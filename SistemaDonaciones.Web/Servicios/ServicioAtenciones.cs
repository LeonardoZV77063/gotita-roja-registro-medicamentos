using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>Error de negocio con un mensaje pensado para mostrarle a la usuaria.</summary>
public class ReglaNegocioException : Exception
{
    public ReglaNegocioException(string mensaje) : base(mensaje) { }
}

/// <summary>
/// Orquesta el alta de una entrega: la receta escaneada, el diagnóstico, los
/// medicamentos y, cuando corresponde, el descuento de inventario.
///
/// Todo ocurre dentro de una transacción para que receta, atención, detalles y
/// movimientos de inventario no queden confirmados parcialmente.
/// </summary>
public class ServicioAtenciones
{
    /// <summary>Fecha de atención más antigua que se acepta, contra errores de tipeo del año.</summary>
    public static readonly DateTime AtencionMinima = new(2000, 1, 1);

    /// <summary>Límites de las columnas DECIMAL(10,2) y DECIMAL(14,2) de AtencionDetalle.</summary>
    private const decimal CantidadMaxima = 99_999_999.99m;
    private const decimal MontoMaximo = 999_999_999_999.99m;

    private readonly AppDbContext _db;
    private readonly ServicioArchivos _archivos;
    private readonly ServicioCatalogos _catalogos;
    private readonly ServicioFarmacia _farmacia;
    private readonly ILogger<ServicioAtenciones> _log;

    public ServicioAtenciones(
        AppDbContext db,
        ServicioArchivos archivos,
        ServicioCatalogos catalogos,
        ServicioFarmacia farmacia,
        ILogger<ServicioAtenciones> log)
    {
        _db = db;
        _archivos = archivos;
        _catalogos = catalogos;
        _farmacia = farmacia;
        _log = log;
    }

    /// <summary>
    /// Registra una entrega completa. Devuelve la atención ya persistida.
    /// </summary>
    public async Task<Atencion> RegistrarAsync(
        AtencionFormViewModel form,
        int idUsuario,
        CancellationToken ct = default)
    {
        if (form.ArchivoReceta is null || form.ArchivoReceta.Length == 0)
            throw new ReglaNegocioException(
                "Debe adjuntar la receta escaneada: sin ella la entrega no puede registrarse.");

        var lineas = ValidarLineas(form.Lineas);

        var paciente = await _db.Pacientes
            .FirstOrDefaultAsync(p => p.IdPaciente == form.IdPaciente, ct)
            ?? throw new ReglaNegocioException("El paciente indicado no existe.");

        if (form.FechaAtencion.Date > DateTime.Today)
            throw new ReglaNegocioException("La fecha de atención no puede ser futura.");

        if (form.FechaAtencion.Date < AtencionMinima)
            throw new ReglaNegocioException(
                $"La fecha de atención no puede ser anterior a {AtencionMinima:dd/MM/yyyy}. Revise el año.");

        if (!await _db.CondicionesAtencion.AnyAsync(c => c.IdCondicion == form.IdCondicion && c.Activo, ct))
            throw new ReglaNegocioException("Seleccione una condición del paciente válida.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            // El binario puede deduplicarse, pero una receta no puede pertenecer
            // a dos entregas.
            var resultado = await _archivos.GuardarAsync(
                form.ArchivoReceta, idUsuario, "recetas", ct);

            if (resultado.YaExistia)
            {
                var yaUsada = await _db.Atenciones
                    .AnyAsync(a => a.IdArchivoReceta == resultado.Archivo.IdArchivo, ct);

                if (yaUsada)
                    throw new ReglaNegocioException(
                        "Esa receta escaneada ya está registrada en otra entrega. " +
                        "Verifique que no esté cargando dos veces el mismo documento.");
            }

            var diagnostico = await _db.Diagnosticos
                .FirstOrDefaultAsync(
                    d => d.IdDiagnostico == form.IdDiagnostico && d.Activo,
                    ct)
                ?? throw new ReglaNegocioException(
                    "Seleccione un diagnóstico válido.");

            var establecimiento =
                await _catalogos.ObtenerOCrearEstablecimientoAsync(
                    form.Establecimiento,
                    ct);

            // El valor del formulario es sólo una vista previa. El bloqueo de
            // aplicación reserva el correlativo definitivo dentro de la
            // transacción y serializa solicitudes simultáneas.
            var numeroFormulario = await ReservarNumeroFormularioAsync(ct);

            var atencion = new Atencion
            {
                NumeroFormulario = numeroFormulario,
                IdPaciente = paciente.IdPaciente,
                FechaAtencion = form.FechaAtencion.Date,
                IdDiagnostico = diagnostico.IdDiagnostico,
                IdCondicion = form.IdCondicion,
                IdEstablecimiento = establecimiento?.IdEstablecimiento,
                IdArchivoReceta = resultado.Archivo.IdArchivo,
                Observaciones = string.IsNullOrWhiteSpace(form.Observaciones)
                    ? null : form.Observaciones.Trim(),
                Estado = Atencion.EstadoRegistrada,
                FechaRegistro = DateTime.Now,
                IdUsuarioRegistro = idUsuario
            };

            _db.Atenciones.Add(atencion);
            await _db.SaveChangesAsync(ct);

            var medicamentosUsados = new HashSet<int>();

            foreach (var linea in lineas)
            {
                var medicamento = await _catalogos.ObtenerOCrearMedicamentoAsync(
                    linea.Medicamento!, idUsuario, ct);

                // Dos textos distintos pueden resolver al mismo medicamento
                // («Ondansetron» y «Ondansetrón»): se avisa antes de que lo
                // rechace UQ_Detalle_AtencionMed.
                if (!medicamentosUsados.Add(medicamento.IdMedicamento))
                    throw new ReglaNegocioException(
                        $"El medicamento «{medicamento.Nombre}» aparece más de una vez. " +
                        "Sume las cantidades en una sola línea.");

                var cantidad = linea.Cantidad!.Value;

                var detalle = new AtencionDetalle
                {
                    IdAtencion = atencion.IdAtencion,
                    IdMedicamento = medicamento.IdMedicamento,
                    Cantidad = cantidad,
                    MontoTotal = linea.DescontarDeInventario ? 0m : (linea.MontoManual ?? 0m),
                    CostoUnitario = linea.DescontarDeInventario
                        ? null
                        : decimal.Round((linea.MontoManual ?? 0m) / cantidad, 2),
                    OrigenCosto = linea.DescontarDeInventario
                        ? AtencionDetalle.OrigenFifo
                        : AtencionDetalle.OrigenManual
                };

                _db.AtencionDetalles.Add(detalle);
                await _db.SaveChangesAsync(ct);

                if (linea.DescontarDeInventario)
                {
                    // El procedimiento reparte la cantidad entre los lotes que
                    // ya habían ingresado a la fecha de la atención, del más
                    // antiguo al más nuevo, y escribe el monto real en la
                    // línea. Si el stock no alcanza, la transacción se revierte.
                    await _farmacia.ConsumirFifoAsync(
                        detalle.IdAtencionDetalle,
                        medicamento.IdMedicamento,
                        cantidad,
                        ct);

                    await _db.Entry(detalle).ReloadAsync(ct);
                }
            }

            await tx.CommitAsync(ct);
            _archivos.ConfirmarEscritos();

            _log.LogInformation(
                "Entrega {Formulario} registrada para el paciente {Paciente} con {Lineas} medicamento(s).",
                atencion.NumeroFormulario, paciente.IdPaciente, lineas.Count);

            return atencion;
        }
        catch (Exception ex)
        {
            await tx.RevertirSinFallarAsync();
            await _archivos.DescartarEscritosAsync();
            _db.ChangeTracker.Clear();

            if (ex is StockInsuficienteException or ReglaNegocioException or ArgumentException)
                throw;

            if (ex is DbUpdateException or SqlException)
            {
                _log.LogWarning(ex, "No se pudo registrar la entrega del paciente {Paciente}.", form.IdPaciente);
                throw new ReglaNegocioException(TraducirErrorBase(ex));
            }

            throw;
        }
    }

    /// <summary>
    /// Anula una entrega. Nunca se borra: el respaldo para auditoría no admite
    /// huecos, y la base lo impone con un trigger INSTEAD OF DELETE.
    /// </summary>
    public async Task AnularAsync(
        int idAtencion,
        string motivo,
        bool devolverStock,
        int idUsuario,
        CancellationToken ct = default)
    {
        var atencion = await _db.Atenciones
            .Include(a => a.Detalles)
            .FirstOrDefaultAsync(a => a.IdAtencion == idAtencion, ct)
            ?? throw new ReglaNegocioException("La entrega indicada no existe.");

        if (atencion.EstaAnulada)
            throw new ReglaNegocioException("Esa entrega ya estaba anulada.");

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            // TR_Atencion_Auditoria registra este UPDATE en la bitácora. Sin
            // este dato el trigger sólo conoce a quien REGISTRÓ la entrega y
            // anotaba a esa persona como autora de la anulación. El contexto de
            // sesión vive lo que dura la conexión, que dentro de la transacción
            // es siempre la misma.
            await _db.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC sp_set_session_context @key = N'IdUsuario', @value = {idUsuario}", ct);

            if (devolverStock)
            {
                foreach (var detalle in atencion.Detalles.Where(d => d.CosteadoPorInventario))
                    await _farmacia.DevolverConsumosAsync(detalle.IdAtencionDetalle, ct);
            }

            atencion.Estado = Atencion.EstadoAnulada;
            atencion.MotivoAnulacion = motivo.Trim();

            // No se escribe nada en Bitacora desde acá: el trigger
            // TR_Atencion_Auditoria ya registra este UPDATE con el estado
            // anterior y el nuevo en JSON, motivo incluido. Duplicarlo dejaría
            // dos versiones del mismo hecho en el registro de auditoría.
            await _db.SaveChangesAsync(ct);

            await tx.CommitAsync(ct);

            _log.LogWarning(
                "Entrega {Id} anulada por el usuario {Usuario}. Motivo: {Motivo}",
                idAtencion, idUsuario, motivo);
        }
        catch (Exception ex)
        {
            await tx.RevertirSinFallarAsync();
            _db.ChangeTracker.Clear();

            // Dos administradores anulando la misma entrega a la vez: el
            // segundo encuentra los consumos ya devueltos.
            if (ex is DbUpdateConcurrencyException)
                throw new ReglaNegocioException(
                    "Otra persona modificó esta entrega mientras se anulaba. " +
                    "Vuelva a abrirla para ver su estado actual.");

            if (ex is DbUpdateException or SqlException)
            {
                _log.LogWarning(ex, "No se pudo anular la entrega {Id}.", idAtencion);
                throw new ReglaNegocioException(TraducirErrorBase(ex));
            }

            throw;
        }
    }

    /// <summary>Consulta con filtros y paginación para el listado general.</summary>
    public async Task<ListadoAtencionesViewModel> ListarAsync(
        ListadoAtencionesViewModel filtro,
        int porPagina = 25,
        CancellationToken ct = default)
    {
        var consulta = _db.Atenciones
            .AsNoTracking()
            .Include(a => a.Paciente)
            .Include(a => a.Diagnostico)
            .Include(a => a.Condicion)
            .Include(a => a.Detalles).ThenInclude(d => d.Medicamento)
            .AsQueryable();

        if (!filtro.IncluirAnuladas)
            consulta = consulta.Where(a => a.Estado == Atencion.EstadoRegistrada);

        if (filtro.Desde.HasValue)
            consulta = consulta.Where(a => a.FechaAtencion >= filtro.Desde.Value.Date);

        if (filtro.Hasta.HasValue)
            consulta = consulta.Where(a => a.FechaAtencion <= filtro.Hasta.Value.Date);

        // Mismas reglas que la búsqueda de pacientes (ver CriterioBusqueda):
        // cada palabra debe coincidir con parte del número de formulario, con
        // el comienzo del carnet o con el comienzo de un nombre o apellido.
        var texto = CriterioBusqueda.Limpiar(filtro.Criterio);
        filtro.CriterioInvalido = CriterioBusqueda.EsInvalido(filtro.Criterio, texto);

        if (filtro.CriterioInvalido)
            consulta = consulta.Where(a => false);

        foreach (var palabra in CriterioBusqueda.Palabras(texto))
        {
            var contiene = CriterioBusqueda.PatronContiene(palabra);
            var inicioCarnet = CriterioBusqueda.PatronEmpieza(palabra);
            var inicioPalabra = CriterioBusqueda.PatronInicioDePalabra(palabra);

            consulta = consulta.Where(a =>
                EF.Functions.Like(a.NumeroFormulario, contiene, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(a.Paciente!.NumeroDocumento, inicioCarnet, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + a.Paciente.Nombres).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + a.Paciente.ApellidoPaterno).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape) ||
                EF.Functions.Like(EF.Functions.Collate((" " + a.Paciente.ApellidoMaterno).Replace("-", " "), CriterioBusqueda.Colacion),
                    inicioPalabra, CriterioBusqueda.CaracterEscape));
        }

        var total = await consulta.CountAsync(ct);
        var pagina = Math.Max(1, filtro.Pagina);
        var totalPaginas = Math.Max(1, (int)Math.Ceiling(total / (double)porPagina));
        if (pagina > totalPaginas) pagina = totalPaginas;

        filtro.Atenciones = await consulta
            .OrderByDescending(a => a.FechaAtencion)
            .ThenByDescending(a => a.IdAtencion)
            .Skip((pagina - 1) * porPagina)
            .Take(porPagina)
            .ToListAsync(ct);

        filtro.Pagina = pagina;
        filtro.TotalPaginas = totalPaginas;
        filtro.TotalRegistros = total;

        return filtro;
    }

    /// <summary>Una entrega con todo lo necesario para verla o imprimirla.</summary>
    public Task<Atencion?> ObtenerCompletaAsync(int idAtencion, CancellationToken ct = default) =>
        _db.Atenciones
            .AsNoTracking()
            .Include(a => a.Paciente).ThenInclude(p => p!.Sexo)
            // Procedencia del paciente para el comprobante impreso: sin estas
            // cadenas de Include el municipio llega null y la fila queda vacía.
            // Las dos hacen falta: si sólo se trajera la residencia, un paciente
            // con origen cargado imprimiría la residencia como si fuera su
            // procedencia, sin que nada lo delate.
            .Include(a => a.Paciente).ThenInclude(p => p!.Municipio)
                .ThenInclude(m => m!.Provincia).ThenInclude(pr => pr!.Departamento)
            .Include(a => a.Paciente).ThenInclude(p => p!.MunicipioOrigen)
                .ThenInclude(m => m!.Provincia).ThenInclude(pr => pr!.Departamento)
            // El país evita dejar vacía la procedencia de pacientes del exterior.
            .Include(a => a.Paciente).ThenInclude(p => p!.PaisOrigen)
            .Include(a => a.Diagnostico)
            .Include(a => a.Condicion)
            .Include(a => a.Establecimiento)
            .Include(a => a.ArchivoReceta)
            .Include(a => a.UsuarioRegistro)
            .Include(a => a.Detalles).ThenInclude(d => d.Medicamento)
                .ThenInclude(m => m!.UnidadMedida)
            .Include(a => a.Detalles).ThenInclude(d => d.Consumos).ThenInclude(c => c.Lote)
            .FirstOrDefaultAsync(a => a.IdAtencion == idAtencion, ct);

    /// <summary>
    /// Filtra las líneas del formulario y valida las que se usaron. Una línea
    /// completamente vacía se ignora (la usuaria puede dejar la última sin
    /// usar); una a medias se informa en lugar de descartarse en silencio.
    /// </summary>
    private static List<LineaMedicamentoViewModel> ValidarLineas(
        IReadOnlyList<LineaMedicamentoViewModel> lineasFormulario)
    {
        var lineas = new List<LineaMedicamentoViewModel>();

        for (var i = 0; i < lineasFormulario.Count; i++)
        {
            var linea = lineasFormulario[i];
            var numero = i + 1;
            var tieneMedicamento = !string.IsNullOrWhiteSpace(linea.Medicamento);

            if (!tieneMedicamento)
            {
                if (linea.Cantidad.HasValue || linea.MontoManual.HasValue)
                    throw new ReglaNegocioException(
                        $"La línea {numero} tiene cantidad o monto pero no dice qué medicamento es.");
                continue;
            }

            var nombre = linea.Medicamento!.Trim();

            if (linea.Cantidad is not decimal cantidad || cantidad <= 0)
                throw new ReglaNegocioException(
                    $"Indique la cantidad entregada de «{nombre}» (mayor que cero).");

            if (cantidad > CantidadMaxima || decimal.Round(cantidad, 2) != cantidad)
                throw new ReglaNegocioException(
                    $"La cantidad de «{nombre}» no es válida: use hasta dos decimales " +
                    $"y un valor menor a {CantidadMaxima:N0}.");

            if (!linea.DescontarDeInventario && linea.MontoManual is decimal monto)
            {
                if (monto < 0)
                    throw new ReglaNegocioException($"El monto de «{nombre}» no puede ser negativo.");

                if (monto > MontoMaximo || decimal.Round(monto, 2) != monto)
                    throw new ReglaNegocioException(
                        $"El monto de «{nombre}» no es válido: use hasta dos decimales.");
            }

            lineas.Add(linea);
        }

        if (lineas.Count == 0)
            throw new ReglaNegocioException("Agregue al menos un medicamento entregado.");

        var duplicados = lineas
            .GroupBy(l => l.Medicamento!.Trim(), StringComparer.OrdinalIgnoreCase)
            .Where(g => g.Count() > 1)
            .Select(g => g.Key)
            .ToList();

        if (duplicados.Count > 0)
            throw new ReglaNegocioException(
                $"El medicamento «{duplicados[0]}» aparece más de una vez. " +
                "Sume las cantidades en una sola línea.");

        return lineas;
    }

    /// <summary>
    /// Toma un bloqueo exclusivo de aplicación, dueño la transacción en curso,
    /// y devuelve el siguiente número de formulario libre.
    /// </summary>
    private async Task<string> ReservarNumeroFormularioAsync(CancellationToken ct)
    {
        await _db.Database.ExecuteSqlRawAsync(
            "DECLARE @resultado INT; " +
            "EXEC @resultado = sp_getapplock " +
            "    @Resource = N'SistemaDonaciones.NumeroFormulario', " +
            "    @LockMode = N'Exclusive', @LockOwner = N'Transaction', @LockTimeout = 15000; " +
            "IF @resultado < 0 " +
            "    THROW 50010, N'No se pudo reservar el número de formulario porque el sistema está ocupado. Intente de nuevo en unos segundos.', 1;",
            ct);

        return await _catalogos.SugerirNumeroFormularioAsync(ct);
    }

    /// <summary>
    /// Traduce las violaciones de restricciones de SQL Server a mensajes que la
    /// usuaria pueda entender y accionar.
    /// </summary>
    private static string TraducirErrorBase(Exception ex)
    {
        var sql = ErroresBaseDatos.SqlDe(ex);
        var mensaje = ErroresBaseDatos.MensajeMotor(ex);

        // Errores levantados a propósito por los scripts de la base: el
        // mensaje ya está escrito para la usuaria.
        if (sql is { Number: >= 50000 and < 51000 })
            return sql.Message;

        if (mensaje.Contains("UQ_Atencion_Formulario"))
            return "Ya existe una entrega con ese número de formulario. Vuelva a registrarla.";

        if (mensaje.Contains("UQ_Atencion_Receta"))
            return "Esa receta escaneada ya está asociada a otra entrega.";

        if (mensaje.Contains("UQ_ArchivoDigital_Hash"))
            return "Ese archivo ya estaba cargado en el sistema.";

        if (mensaje.Contains("UQ_Detalle_AtencionMed"))
            return "El mismo medicamento no puede figurar dos veces en una entrega.";

        if (mensaje.Contains("CK_Atencion_Fecha"))
            return "La fecha de atención no puede ser futura.";

        if (mensaje.Contains("CK_Lote_Cantidades"))
            return "La operación dejaría el stock de un lote en un valor imposible. " +
                   "Verifique las cantidades.";

        if (mensaje.Contains("CK_Detalle_Cantidad") || mensaje.Contains("CK_Detalle_Monto")
            || mensaje.Contains("CK_Detalle_Costo"))
            return "Revise las cantidades y los montos de los medicamentos: deben ser mayores que cero.";

        if (mensaje.Contains("FK_Atencion_Condicion"))
            return "Seleccione una condición del paciente válida.";

        return "No se pudo guardar la información. " +
               "Revise los datos e intente nuevamente; si el problema persiste, " +
               "anote el número de formulario y avise al responsable del sistema.";
    }
}
