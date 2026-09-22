using System.Data;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>
/// Alta, búsqueda y ficha del paciente.
///
/// La primera visita crea una ficha única y las siguientes la reutilizan. Los
/// carnets renovados se conservan como historial sin duplicar al paciente.
/// </summary>
public class ServicioPacientes
{
    /// <summary>Fecha de nacimiento más antigua que se acepta, contra errores de tipeo del año.</summary>
    public static readonly DateTime NacimientoMinimo = new(1900, 1, 1);

    private readonly ServicioBitacora _bitacora;
    private readonly AppDbContext _db;
    private readonly ServicioArchivos _archivos;
    private readonly ILogger<ServicioPacientes> _log;

    public ServicioPacientes(
    AppDbContext db,
    ServicioArchivos archivos,
    ServicioBitacora bitacora,
    ILogger<ServicioPacientes> log)
    {
        _db = db;
        _archivos = archivos;
        _bitacora = bitacora;
        _log = log;
    }

    /// <summary>
    /// Busca por carnet, nombre o apellido usando sp_BuscarPaciente, que además
    /// devuelve cuántas veces vino antes y si su carnet ya está cargado.
    ///
    /// El criterio se depura antes de mandarlo (ver <see cref="CriterioBusqueda"/>).
    /// Si lo escrito no deja nada buscable —un emoji, sólo símbolos— se
    /// devuelven cero resultados: mandar un texto vacío al procedimiento
    /// equivaldría a pedir todos los pacientes.
    /// </summary>
    public async Task<List<ResultadoBusquedaPaciente>> BuscarAsync(
    string? criterio,
    CancellationToken ct = default)
    {
        var texto = CriterioBusqueda.Limpiar(criterio);

        if (CriterioBusqueda.EsInvalido(criterio, texto))
            return new List<ResultadoBusquedaPaciente>();

        var parametro = new SqlParameter(
            "@Criterio",
            SqlDbType.NVarChar,
            CriterioBusqueda.LongitudMaxima)
        {
            Value = texto
        };

        return await _db.BusquedaPacientes
            .FromSqlRaw(
                "EXEC sp_BuscarPaciente @Criterio",
                parametro)
            .ToListAsync(ct);
    }

    /// <summary>Registra un paciente nuevo y adjunta su carnet una sola vez.</summary>
    public async Task<Paciente> CrearAsync(
        PacienteFormViewModel form,
        int idUsuario,
        CancellationToken ct = default)
    {
        var documento = form.NumeroDocumento.Trim();
        var complemento = NormalizarCodigo(form.ComplementoDoc);

        var yaExiste = await _db.Pacientes.AnyAsync(
            p => p.NumeroDocumento == documento && p.ComplementoDoc == complemento, ct);

        if (yaExiste)
            throw new ReglaNegocioException(
                $"Ya hay un paciente registrado con el carnet {DocumentoLegible(documento, complemento)}. " +
                "Búsquelo en lugar de crearlo de nuevo.");

        ValidarFechaNacimiento(form.FechaNacimiento);

        var origen = await ResolverOrigenAsync(form, ct);

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            var paciente = new Paciente
            {
                NumeroDocumento = documento,
                ComplementoDoc = complemento,
                ExtensionDoc = NormalizarCodigo(form.ExtensionDoc),
                Nombres = NormalizarNombre(form.Nombres)!,
                ApellidoPaterno = NormalizarNombre(form.ApellidoPaterno)!,
                ApellidoMaterno = NormalizarNombre(form.ApellidoMaterno),
                FechaNacimiento = form.FechaNacimiento!.Value.Date,
                IdSexo = form.IdSexo,
                Telefono = string.IsNullOrWhiteSpace(form.Telefono)
                    ? null : form.Telefono.Trim(),
                IdMunicipio = form.IdMunicipio,
                IdMunicipioOrigen = origen.IdMunicipio,
                IdPaisOrigen = origen.IdPais,

                Zona = Limpiar(form.Zona),
                Calle = Limpiar(form.Calle),
                NumeroDomicilio = Limpiar(form.NumeroDomicilio),
                Direccion = Limpiar(form.Direccion),
                Observaciones = string.IsNullOrWhiteSpace(form.Observaciones)
                    ? null : form.Observaciones.Trim(),
                Activo = true,
                FechaRegistro = DateTime.Now,
                IdUsuarioRegistro = idUsuario
            };

            _db.Pacientes.Add(paciente);
            await _db.SaveChangesAsync(ct);

            if (form.ArchivoCarnet is { Length: > 0 })
            {
                await AdjuntarCarnetAsync(
                    paciente.IdPaciente,
                    form.ArchivoCarnet,
                    idUsuario,
                    ct);
            }

            // La bitácora va dentro de la transacción: un alta sin su registro
            // de auditoría no debe quedar confirmada.
            await _bitacora.RegistrarAsync(
                idUsuario,
                "Paciente",
                paciente.IdPaciente,
                "INSERT",
                null,
                Instantanea(paciente),
                ct);

            await tx.CommitAsync(ct);
            _archivos.ConfirmarEscritos();

            _log.LogInformation(
                "Paciente {Id} registrado con carnet {Documento}.",
                paciente.IdPaciente,
                documento);

            return paciente;
        }
        catch (Exception ex)
        {
            await tx.RevertirSinFallarAsync();
            await _archivos.DescartarEscritosAsync();
            _db.ChangeTracker.Clear();

            // Otra persona registró el mismo carnet entre la verificación de
            // arriba y el INSERT: se muestra el mismo mensaje que si ya existiera.
            if (ErroresBaseDatos.EsDuplicado(ex, "UQ_Paciente_Documento")
                || ErroresBaseDatos.EsDuplicado(ex, "IX_Paciente_Documento"))
                throw new ReglaNegocioException(
                    $"Ya hay un paciente registrado con el carnet {DocumentoLegible(documento, complemento)}. " +
                    "Búsquelo en lugar de crearlo de nuevo.");

            if (ex is DbUpdateException or SqlException)
                throw new ReglaNegocioException(TraducirErrorBase(ex));

            throw;
        }
    }

    /// <summary>
    /// Actualiza los datos de una ficha existente.
    ///
    /// Antes de guardar se verifica que el carnet no pertenezca a otro paciente,
    /// para traducir el conflicto de unicidad a un error de dominio. Datos,
    /// carnet renovado y bitácora se confirman en una sola transacción.
    /// </summary>
    public async Task<Paciente> ActualizarAsync(
        PacienteFormViewModel form,
        int idUsuario,
        CancellationToken ct = default)
    {
        var paciente = await _db.Pacientes
            .FirstOrDefaultAsync(p => p.IdPaciente == form.IdPaciente, ct)
            ?? throw new ReglaNegocioException("El paciente indicado no existe.");

        var anterior = Instantanea(paciente);

        ValidarFechaNacimiento(form.FechaNacimiento);

        var origen = await ResolverOrigenAsync(form, ct);

        var documento = form.NumeroDocumento.Trim();
        var complemento = NormalizarCodigo(form.ComplementoDoc);

        var otroConElMismoCarnet = await _db.Pacientes
            .AsNoTracking()
            .Where(p => p.IdPaciente != paciente.IdPaciente
                        && p.NumeroDocumento == documento
                        && p.ComplementoDoc == complemento)
            .Select(p => new { p.IdPaciente, p.ApellidoPaterno, p.Nombres })
            .FirstOrDefaultAsync(ct);

        if (otroConElMismoCarnet is not null)
            throw new ReglaNegocioException(
                $"El carnet {DocumentoLegible(documento, complemento)} ya pertenece a otro paciente " +
                $"({otroConElMismoCarnet.ApellidoPaterno}, {otroConElMismoCarnet.Nombres}). " +
                "Revise el número o corrija primero la otra ficha.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            paciente.NumeroDocumento = documento;
            paciente.ComplementoDoc = complemento;
            paciente.ExtensionDoc = NormalizarCodigo(form.ExtensionDoc);
            paciente.Nombres = NormalizarNombre(form.Nombres)!;
            paciente.ApellidoPaterno = NormalizarNombre(form.ApellidoPaterno)!;
            paciente.ApellidoMaterno = NormalizarNombre(form.ApellidoMaterno);
            paciente.FechaNacimiento = form.FechaNacimiento!.Value.Date;
            paciente.IdSexo = form.IdSexo;
            paciente.Telefono = string.IsNullOrWhiteSpace(form.Telefono)
                ? null : form.Telefono.Trim();
            paciente.IdMunicipio = form.IdMunicipio;
            paciente.IdMunicipioOrigen = origen.IdMunicipio;
            paciente.IdPaisOrigen = origen.IdPais;

            paciente.Zona = Limpiar(form.Zona);
            paciente.Calle = Limpiar(form.Calle);
            paciente.NumeroDomicilio = Limpiar(form.NumeroDomicilio);
            paciente.Direccion = Limpiar(form.Direccion);
            paciente.Observaciones = string.IsNullOrWhiteSpace(form.Observaciones)
                ? null : form.Observaciones.Trim();

            await _db.SaveChangesAsync(ct);

            // Un carnet nuevo no reemplaza al anterior: lo desplaza. El histórico se
            // conserva para poder auditar entregas hechas con el documento anterior.
            if (form.ArchivoCarnet is { Length: > 0 })
                await AdjuntarCarnetAsync(paciente.IdPaciente, form.ArchivoCarnet, idUsuario, ct);

            await _bitacora.RegistrarAsync(
                idUsuario,
                "Paciente",
                paciente.IdPaciente,
                "UPDATE",
                anterior,
                Instantanea(paciente),
                ct);

            await tx.CommitAsync(ct);
            _archivos.ConfirmarEscritos();

            return paciente;
        }
        catch (Exception ex)
        {
            await tx.RevertirSinFallarAsync();
            await _archivos.DescartarEscritosAsync();

            // La entidad quedó con los valores nuevos en memoria; se descartan
            // para que nada de esta solicitud intente guardarlos otra vez.
            _db.ChangeTracker.Clear();

            if (ErroresBaseDatos.EsDuplicado(ex, "UQ_Paciente_Documento")
                || ErroresBaseDatos.EsDuplicado(ex, "IX_Paciente_Documento"))
                throw new ReglaNegocioException(
                    $"El carnet {DocumentoLegible(documento, complemento)} ya pertenece a otro paciente.");

            if (ex is DbUpdateException or SqlException)
                throw new ReglaNegocioException(TraducirErrorBase(ex));

            throw;
        }
    }

    /// <summary>
    /// Adjunta un carnet y lo marca como vigente, desmarcando el anterior.
    /// El índice filtrado IX_PacDoc_UnicoVigente garantiza que no queden dos.
    ///
    /// Si se llama sola (renovación desde la ficha) abre su propia transacción;
    /// si la llama el alta o la edición, se suma a la de ellas.
    /// </summary>
    public async Task AdjuntarCarnetAsync(
        int idPaciente,
        IFormFile archivo,
        int idUsuario,
        CancellationToken ct = default)
    {
        var txPropia = _db.Database.CurrentTransaction is null
            ? await _db.Database.BeginTransactionAsync(ct)
            : null;

        try
        {
            if (txPropia is not null
                && !await _db.Pacientes.AnyAsync(p => p.IdPaciente == idPaciente, ct))
                throw new ReglaNegocioException("El paciente indicado no existe.");

            var resultado = await _archivos.GuardarAsync(archivo, idUsuario, "carnets", ct);

            var yaVinculado = await _db.PacienteDocumentos
                .FirstOrDefaultAsync(d => d.IdArchivo == resultado.Archivo.IdArchivo, ct);

            if (yaVinculado is not null)
            {
                if (yaVinculado.IdPaciente != idPaciente)
                    throw new ReglaNegocioException(
                        "Ese carnet escaneado ya está registrado en la ficha de otro paciente.");

                // Es el mismo carnet que ya tenía: no se duplica nada.
                _log.LogInformation(
                    "El carnet subido para el paciente {Id} ya estaba almacenado; no se duplica.",
                    idPaciente);

                if (txPropia is not null) await txPropia.CommitAsync(ct);
                return;
            }

            var vigentes = await _db.PacienteDocumentos
                .Where(d => d.IdPaciente == idPaciente && d.Vigente)
                .ToListAsync(ct);

            foreach (var anterior in vigentes)
                anterior.Vigente = false;

            // Se guarda el cambio de los anteriores antes de insertar el nuevo, para
            // no chocar contra el índice único filtrado.
            if (vigentes.Count > 0)
                await _db.SaveChangesAsync(ct);

            var documento = new PacienteDocumento
            {
                IdPaciente = idPaciente,
                IdArchivo = resultado.Archivo.IdArchivo,
                FechaRegistro = DateTime.Now,
                Vigente = true
            };

            _db.PacienteDocumentos.Add(documento);
            await _db.SaveChangesAsync(ct);

            // La renovación del carnet cambia con qué documento se identifica al
            // paciente: queda en la bitácora como cualquier otra corrección.
            await _bitacora.RegistrarAsync(
                idUsuario,
                "PacienteDocumento",
                documento.IdPacienteDocumento,
                "INSERT",
                vigentes.Count == 0
                    ? null
                    : new { IdPaciente = idPaciente, CarnetsAnteriores = vigentes.Select(v => v.IdArchivo).ToList() },
                new { documento.IdPaciente, documento.IdArchivo, documento.Vigente, resultado.Archivo.NombreOriginal },
                ct);

            if (txPropia is not null)
            {
                await txPropia.CommitAsync(ct);
                _archivos.ConfirmarEscritos();
            }
        }
        catch (Exception ex) when (txPropia is not null)
        {
            await txPropia.RevertirSinFallarAsync();
            await _archivos.DescartarEscritosAsync();
            _db.ChangeTracker.Clear();

            if (ex is DbUpdateException or SqlException)
                throw new ReglaNegocioException(TraducirErrorBase(ex));

            throw;
        }
        finally
        {
            if (txPropia is not null) await txPropia.DisposeAsync();
        }
    }

    /// <summary>Ficha completa con historial de entregas.</summary>
    public async Task<FichaPacienteViewModel?> ObtenerFichaAsync(
        int idPaciente, CancellationToken ct = default)
    {
        // La ficha muestra dónde vive y de dónde es, así que hay que traer la
        // cadena Municipio → Provincia → Departamento por partida doble. Sin
        // estos Include las propiedades llegan en null a la vista y la ubicación
        // se ve vacía aunque esté guardada en la base.
        var paciente = await _db.Pacientes
            .AsNoTracking()
            .Include(p => p.Sexo)
            .Include(p => p.Municipio)
                .ThenInclude(m => m!.Provincia)
                    .ThenInclude(pr => pr!.Departamento)
            .Include(p => p.MunicipioOrigen)
                .ThenInclude(m => m!.Provincia)
                    .ThenInclude(pr => pr!.Departamento)
            .Include(p => p.PaisOrigen)
            .FirstOrDefaultAsync(p => p.IdPaciente == idPaciente, ct);

        if (paciente is null) return null;

        var documentos = await _db.PacienteDocumentos
            .AsNoTracking()
            .Include(d => d.Archivo)
            .Where(d => d.IdPaciente == idPaciente)
            .OrderByDescending(d => d.Vigente)
            .ThenByDescending(d => d.FechaRegistro)
            .ToListAsync(ct);

        var atenciones = await _db.Atenciones
            .AsNoTracking()
            .Include(a => a.Diagnostico)
            .Include(a => a.Condicion)
            .Include(a => a.Establecimiento)
            .Include(a => a.ArchivoReceta)
            .Include(a => a.Detalles).ThenInclude(d => d.Medicamento)
            .Where(a => a.IdPaciente == idPaciente)
            .OrderByDescending(a => a.FechaAtencion)
            .ThenByDescending(a => a.IdAtencion)
            .ToListAsync(ct);

        return new FichaPacienteViewModel
        {
            Paciente = paciente,
            CarnetVigente = documentos.FirstOrDefault(d => d.Vigente)?.Archivo,
            CarnetsAnteriores = documentos.Where(d => !d.Vigente).ToList(),
            Atenciones = atenciones
        };
    }

    /// <summary>
    /// Listado paginado de todos los pacientes. Aplica las mismas reglas de
    /// búsqueda que sp_BuscarPaciente, para que un carnet parcial o un apellido
    /// sin tilde den el mismo resultado en las dos pantallas.
    /// </summary>
    public async Task<(List<Paciente> Pacientes, int Total)> ListarAsync(
        string? criterio,
        int pagina = 1,
        int porPagina = 25,
        CancellationToken ct = default)
    {
        var consulta = _db.Pacientes
            .AsNoTracking()
            .Include(p => p.Sexo)
            .Where(p => p.Activo);

        var texto = CriterioBusqueda.Limpiar(criterio);

        if (CriterioBusqueda.EsInvalido(criterio, texto))
            return (new List<Paciente>(), 0);

        foreach (var palabra in CriterioBusqueda.Palabras(texto))
        {
            var inicioCarnet = CriterioBusqueda.PatronEmpieza(palabra);
            var inicioPalabra = CriterioBusqueda.PatronInicioDePalabra(palabra);

            // El guion cuenta como separador de palabras: «Gómez» encuentra
            // «Pérez-Gómez».
            consulta = consulta.Where(p =>
                EF.Functions.Like(p.NumeroDocumento, inicioCarnet, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + p.Nombres).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + p.ApellidoPaterno).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + p.ApellidoMaterno).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape));
        }

        var total = await consulta.CountAsync(ct);
        var paginas = Math.Max(1, (int)Math.Ceiling(total / (double)porPagina));
        var paginaReal = Math.Clamp(pagina, 1, paginas);

        var pacientes = await consulta
            .OrderBy(p => p.ApellidoPaterno)
            .ThenBy(p => p.ApellidoMaterno)
            .ThenBy(p => p.Nombres)
            .Skip((paginaReal - 1) * porPagina)
            .Take(porPagina)
            .ToListAsync(ct);

        return (pacientes, total);
    }

    private static void ValidarFechaNacimiento(DateTime? fecha)
    {
        if (fecha is null)
            throw new ReglaNegocioException("La fecha de nacimiento es obligatoria.");

        if (fecha.Value.Date > DateTime.Today)
            throw new ReglaNegocioException("La fecha de nacimiento no puede ser futura.");

        if (fecha.Value.Date < NacimientoMinimo)
            throw new ReglaNegocioException(
                $"La fecha de nacimiento no puede ser anterior a {NacimientoMinimo:dd/MM/yyyy}. Revise el año.");
    }

    /// <summary>
    /// Resuelve de dónde es el paciente: país y, si corresponde, municipio.
    ///
    /// El catálogo de departamentos, provincias y municipios es boliviano, así
    /// que de alguien del exterior se guarda sólo el país. La regla vive acá y
    /// no sólo en el navegador: el formulario esconde los desplegables cuando
    /// el país no es el local, pero si llegaran igual —sin JavaScript, o por un
    /// envío armado a mano— no deben guardarse.
    ///
    /// Al revés también: si se eligió un municipio de origen, el país es el
    /// local por definición, aunque el desplegable de país no se haya tocado.
    /// </summary>
    private async Task<(short? IdPais, int? IdMunicipio)> ResolverOrigenAsync(
        PacienteFormViewModel form, CancellationToken ct)
    {
        var local = await _db.Paises
            .AsNoTracking()
            .Where(p => p.EsLocal)
            .Select(p => (short?)p.IdPais)
            .FirstOrDefaultAsync(ct);

        // Sin país local marcado no hay forma de saber si el elegido es Bolivia
        // o el exterior, y guardar a ciegas dejaría una ficha con país
        // extranjero y municipio boliviano a la vez. Se corta acá, y sólo
        // cuando se eligió un país. Si no se declaró, un municipio de origen
        // sigue siendo suficiente para inferir el país local.
        if (form.IdPaisOrigen is not null && local is null)
            throw new ReglaNegocioException(
                "El catálogo de países no tiene marcado cuál es el país local, así que " +
                "no se puede determinar el origen del paciente. Avise al responsable del " +
                "sistema: en la tabla Pais ningún país tiene EsLocal = 1.");

        var esDelExterior = form.IdPaisOrigen is not null
                            && form.IdPaisOrigen != local;

        if (esDelExterior)
            return (form.IdPaisOrigen, null);

        // La casilla «es del mismo lugar donde vive» sin una residencia elegida
        // no afirma nada: se guardaría un origen vacío y la ficha diría «sin
        // cargar» sin explicar por qué. Se avisa en lugar de descartarlo en
        // silencio. No aplica a un paciente del exterior, que ya salió arriba.
        if (form.OrigenIgualQueResidencia && form.IdMunicipio is null)
            throw new ReglaNegocioException(
                "Marcó que el paciente es del mismo lugar donde vive, pero no eligió " +
                "ese lugar. Complete el municipio en «Dónde vive», o desmarque la " +
                "casilla para cargar el lugar de origen por separado.");

        var municipio = OrigenDe(form);

        return (municipio is null ? form.IdPaisOrigen : local ?? form.IdPaisOrigen,
                municipio);
    }

    /// <summary>Recorta y devuelve null si no quedó nada.</summary>
    private static string? Limpiar(string? texto) =>
        string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

    /// <summary>
    /// Municipio de origen que corresponde guardar. Con la casilla «es del mismo
    /// lugar donde vive» marcada se copia la residencia: el formulario no manda
    /// los desplegables de origen (van en un fieldset deshabilitado), así que el
    /// servidor realiza la copia y evita valores divergentes.
    /// Si no se cargó ninguna ubicación queda en null, y el mapa cuenta ese
    /// paciente por su residencia avisándolo en pantalla.
    /// </summary>
    private static int? OrigenDe(PacienteFormViewModel form) =>
        form.OrigenIgualQueResidencia ? form.IdMunicipio : form.IdMunicipioOrigen;

    /// <summary>Recorta y deja un solo espacio entre palabras; null si queda vacío.</summary>
    private static string? NormalizarNombre(string? texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return null;
        return Regex.Replace(texto.Trim(), @"\s+", " ");
    }

    /// <summary>Complemento y extensión: sin espacios y en mayúsculas.</summary>
    private static string? NormalizarCodigo(string? texto) =>
        string.IsNullOrWhiteSpace(texto) ? null : texto.Trim().ToUpperInvariant();

    private static string DocumentoLegible(string documento, string? complemento) =>
        complemento is null ? documento : $"{documento}-{complemento}";

    private static object Instantanea(Paciente p) => new
    {
        p.NumeroDocumento,
        p.ComplementoDoc,
        p.ExtensionDoc,
        p.Nombres,
        p.ApellidoPaterno,
        p.ApellidoMaterno,
        p.FechaNacimiento,
        p.IdSexo,
        p.Telefono,
        p.IdMunicipio,
        p.IdMunicipioOrigen,
        p.IdPaisOrigen,
        p.Zona,
        p.Calle,
        p.NumeroDomicilio,
        p.Direccion,
        p.Observaciones,
        p.Activo
    };

    private static string TraducirErrorBase(Exception ex)
    {
        var mensaje = ErroresBaseDatos.MensajeMotor(ex);

        if (mensaje.Contains("UQ_Paciente_Documento") || mensaje.Contains("IX_Paciente_Documento"))
            return "Ya hay otro paciente registrado con ese carnet.";

        if (mensaje.Contains("CK_Paciente_FechaNac"))
            return "La fecha de nacimiento no puede ser futura.";

        if (mensaje.Contains("IX_PacDoc_UnicoVigente") || mensaje.Contains("UQ_PacDoc_Archivo"))
            return "Otra persona actualizó el carnet de este paciente al mismo tiempo. " +
                   "Vuelva a abrir la ficha e intente de nuevo.";

        // Se pregunta primero por el origen: "FK_Paciente_Municipio" también es
        // parte de "FK_Paciente_MunicipioOrigen", así que el orden inverso
        // devolvería siempre el mensaje de la residencia.
        if (mensaje.Contains("FK_Paciente_MunicipioOrigen"))
            return "El municipio de origen seleccionado no existe. Vuelva a elegir el lugar de origen.";

        if (mensaje.Contains("FK_Paciente_Municipio"))
            return "El municipio seleccionado no existe. Vuelva a elegir la ubicación.";

        if (mensaje.Contains("FK_Paciente_PaisOrigen"))
            return "El país de origen seleccionado no existe. Vuelva a elegirlo.";

        if (mensaje.Contains("FK_Paciente_Sexo"))
            return "Seleccione el sexo del paciente.";

        return "No se pudieron guardar los datos del paciente. Revise la información " +
               "e intente nuevamente; si el problema persiste, avise al responsable del sistema.";
    }
}
