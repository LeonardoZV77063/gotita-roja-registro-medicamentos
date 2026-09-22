using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;
using SistemaDonaciones.Web.Servicios;

namespace SistemaDonaciones.Web.Controllers;

/// <summary>
/// Búsqueda, registro, edición y ficha de pacientes. El flujo comienza buscando
/// una ficha existente para evitar duplicados.
/// </summary>
public class PacientesController : Controller
{
    private readonly ServicioPacientes _pacientes;
    private readonly AppDbContext _db;

    public PacientesController(ServicioPacientes pacientes, AppDbContext db)
    {
        _pacientes = pacientes;
        _db = db;
    }

    /// <summary>Pantalla de búsqueda: el primer paso de cada atención.</summary>
    [HttpGet]
    public async Task<IActionResult> Index(
    string? criterio,
    CancellationToken ct)
    {
        var modelo = new BusquedaPacienteViewModel
        {
            Criterio = criterio,
            CriterioInvalido = CriterioBusqueda.EsInvalido(
                criterio, CriterioBusqueda.Limpiar(criterio))
        };

        modelo.Resultados =
            await _pacientes.BuscarAsync(
                criterio ?? string.Empty,
                ct);

        return View(modelo);
    }
    /// <summary>Listado completo, para consultas generales.</summary>
    [HttpGet]
    public async Task<IActionResult> Listado(string? criterio, int pagina = 1, CancellationToken ct = default)
    {
        var (lista, total) = await _pacientes.ListarAsync(criterio, pagina, 25, ct);
        var totalPaginas = Math.Max(1, (int)Math.Ceiling(total / 25.0));

        ViewBag.Criterio = criterio;
        ViewBag.CriterioInvalido = CriterioBusqueda.EsInvalido(
            criterio, CriterioBusqueda.Limpiar(criterio));
        ViewBag.Pagina = Math.Clamp(pagina, 1, totalPaginas);
        ViewBag.TotalPaginas = totalPaginas;
        ViewBag.Total = total;

        return View(lista);
    }

    [HttpGet]
    public async Task<IActionResult> Crear(string? documento, CancellationToken ct)
    {
        var modelo = new PacienteFormViewModel
        {
            NumeroDocumento = documento ?? string.Empty,

            Sexos = await _db.Sexos
        .AsNoTracking()
        .Where(s => s.Activo)
        .ToListAsync(ct),

            Paises = await _db.Paises
        .AsNoTracking()
        .Where(p => p.Activo)
        .OrderByDescending(p => p.EsLocal)
        .ThenBy(p => p.Nombre)
        .ToListAsync(ct),

            Departamentos = await _db.Departamentos
        .AsNoTracking()
        .OrderBy(d => d.Nombre)
        .ToListAsync(ct),

            Provincias = await _db.Provincias
        .AsNoTracking()
        .OrderBy(p => p.Nombre)
        .ToListAsync(ct),

            Municipios = await _db.Municipios
        .AsNoTracking()
        .OrderBy(m => m.Nombre)
        .ToListAsync(ct)
        };

        // Después de cargar el catálogo: el país local sale de él.
        modelo.PreseleccionarPaisLocal();

        return View(modelo);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Crear(PacienteFormViewModel modelo, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return await VolverAlFormulario(modelo, ct);

        try
        {
            var paciente = await _pacientes.CrearAsync(modelo, User.IdUsuario(), ct);
            TempData["Exito"] = $"Paciente {paciente.NombreCompleto} registrado correctamente.";
            return RedirectToAction(nameof(Ficha), new { id = paciente.IdPaciente });
        }
        catch (ReglaNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await VolverAlFormulario(modelo, ct);
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(nameof(modelo.ArchivoCarnet), ex.Message);
            return await VolverAlFormulario(modelo, ct);
        }
    }

    /// <summary>
    /// La corrección completa de una ficha está reservada al rol Administrador.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Editar(int id, CancellationToken ct)
    {
        // Las dos cadenas Municipio → Provincia hacen falta para reconstruir los
        // desplegables: el formulario guarda sólo el municipio, pero en pantalla
        // hay que dejar preseleccionados también su provincia y su departamento.
        var paciente = await _db.Pacientes
            .AsNoTracking()
            .Include(p => p.Municipio)
                .ThenInclude(m => m!.Provincia)
            .Include(p => p.MunicipioOrigen)
                .ThenInclude(m => m!.Provincia)
            .Include(p => p.PaisOrigen)
            .FirstOrDefaultAsync(
            p => p.IdPaciente == id,
            ct);

        if (paciente is null) return NotFound();

        var carnet = await _db.PacienteDocumentos
            .AsNoTracking()
            .Include(d => d.Archivo)
            .Where(d => d.IdPaciente == id && d.Vigente)
            .Select(d => d.Archivo)
            .FirstOrDefaultAsync(ct);

        var modelo = new PacienteFormViewModel
        {
            IdPaciente = paciente.IdPaciente,
            NumeroDocumento = paciente.NumeroDocumento,
            ComplementoDoc = paciente.ComplementoDoc,
            ExtensionDoc = paciente.ExtensionDoc,
            Nombres = paciente.Nombres,
            ApellidoPaterno = paciente.ApellidoPaterno,
            ApellidoMaterno = paciente.ApellidoMaterno,
            FechaNacimiento = paciente.FechaNacimiento,
            IdSexo = paciente.IdSexo,
            Telefono = paciente.Telefono,
            Observaciones = paciente.Observaciones,
            CarnetVigente = carnet,
            IdMunicipio = paciente.IdMunicipio,

            IdProvincia = paciente.Municipio?.IdProvincia,

            IdDepartamento = paciente.Municipio?.Provincia?.IdDepartamento,

            IdMunicipioOrigen = paciente.IdMunicipioOrigen,

            IdProvinciaOrigen = paciente.MunicipioOrigen?.IdProvincia,

            IdDepartamentoOrigen = paciente.MunicipioOrigen?.Provincia?.IdDepartamento,

            IdPaisOrigen = paciente.IdPaisOrigen,

            Zona = paciente.Zona,
            Calle = paciente.Calle,
            NumeroDomicilio = paciente.NumeroDomicilio,

            // La casilla «es del mismo lugar donde vive» nunca llega marcada desde
            // el servidor, aunque hoy las dos ubicaciones coincidan: es un atajo
            // para copiar, no un dato guardado. Si viniera marcada, el bloque de
            // origen se mostraría oculto y corregir la residencia de alguien que
            // se mudó le reescribiría el origen
            // sin que nadie lo viera.
            Direccion = paciente.Direccion,
            Sexos = await _db.Sexos.AsNoTracking().Where(s => s.Activo).ToListAsync(ct),

            Paises = await _db.Paises
            .AsNoTracking()
            .Where(p => p.Activo || p.IdPais == paciente.IdPaisOrigen)
            .OrderByDescending(p => p.EsLocal)
            .ThenBy(p => p.Nombre)
            .ToListAsync(ct),

            Departamentos = await _db.Departamentos
            .AsNoTracking()
            .OrderBy(d => d.Nombre)
            .ToListAsync(ct),

            Provincias = await _db.Provincias
            .AsNoTracking()
            .OrderBy(p => p.Nombre)
            .ToListAsync(ct),

            Municipios = await _db.Municipios
            .AsNoTracking()
            .OrderBy(m => m.Nombre)
            .ToListAsync(ct)
        };

        return View(modelo);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Editar(PacienteFormViewModel modelo, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return await VolverAlFormulario(modelo, ct, vista: nameof(Editar));

        try
        {
            await _pacientes.ActualizarAsync(modelo, User.IdUsuario(), ct);
            TempData["Exito"] = "Los datos del paciente fueron actualizados.";
            return RedirectToAction(nameof(Ficha), new { id = modelo.IdPaciente });
        }
        catch (ReglaNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await VolverAlFormulario(modelo, ct, vista: nameof(Editar));
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(nameof(modelo.ArchivoCarnet), ex.Message);
            return await VolverAlFormulario(modelo, ct, vista: nameof(Editar));
        }
    }

    /// <summary>Ficha con el historial completo de entregas.</summary>
    [HttpGet]
    public async Task<IActionResult> Ficha(int id, CancellationToken ct)
    {
        var ficha = await _pacientes.ObtenerFichaAsync(id, ct);
        return ficha is null ? NotFound() : View(ficha);
    }

    /// <summary>Sube un carnet renovado sin pasar por la edición completa.</summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ActualizarCarnet(
        int id, IFormFile archivoCarnet, CancellationToken ct)
    {
        try
        {
            await _pacientes.AdjuntarCarnetAsync(id, archivoCarnet, User.IdUsuario(), ct);
            TempData["Exito"] = "El carnet fue actualizado.";
        }
        catch (Exception ex) when (ex is ReglaNegocioException or ArgumentException)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Ficha), new { id });
    }

    private async Task<IActionResult> VolverAlFormulario(
    PacienteFormViewModel modelo,
    CancellationToken ct,
    string vista = nameof(Crear))
    {
        modelo.Sexos = await _db.Sexos
            .AsNoTracking()
            .Where(s => s.Activo)
            .ToListAsync(ct);

        modelo.Paises = await _db.Paises
            .AsNoTracking()
            .Where(p => p.Activo || p.IdPais == modelo.IdPaisOrigen)
            .OrderByDescending(p => p.EsLocal)
            .ThenBy(p => p.Nombre)
            .ToListAsync(ct);

        modelo.Departamentos = await _db.Departamentos
            .AsNoTracking()
            .OrderBy(d => d.Nombre)
            .ToListAsync(ct);

        modelo.Provincias = await _db.Provincias
            .AsNoTracking()
            .OrderBy(p => p.Nombre)
            .ToListAsync(ct);

        modelo.Municipios = await _db.Municipios
            .AsNoTracking()
            .OrderBy(m => m.Nombre)
            .ToListAsync(ct);

        // Con la casilla marcada el bloque de origen viaja deshabilitado y sus
        // tres desplegables llegan vacíos. Si la persona la desmarca después de
        // corregir el error, tiene que ver la residencia que estaba por copiarse
        // y no tres casilleros en blanco que al guardar borrarían el origen.
        if (modelo.OrigenIgualQueResidencia)
        {
            modelo.IdDepartamentoOrigen = modelo.IdDepartamento;
            modelo.IdProvinciaOrigen = modelo.IdProvincia;
            modelo.IdMunicipioOrigen = modelo.IdMunicipio;
        }

        if (modelo.IdPaciente != 0)
        {
            modelo.CarnetVigente = await _db.PacienteDocumentos
                .AsNoTracking()
                .Include(d => d.Archivo)
                .Where(d =>
                    d.IdPaciente == modelo.IdPaciente &&
                    d.Vigente)
                .Select(d => d.Archivo)
                .FirstOrDefaultAsync(ct);
        }

        return View(vista, modelo);
    }
}
