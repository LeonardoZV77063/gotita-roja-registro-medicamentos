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
/// Registro, consulta, comprobante y anulación de entregas de medicamentos.
/// </summary>
public class AtencionesController : Controller
{
    private readonly ServicioAtenciones _atenciones;
    private readonly ServicioCatalogos _catalogos;
    private readonly ServicioFarmacia _farmacia;
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;
    private readonly ServicioBitacora _bitacora;

    public AtencionesController(
        ServicioAtenciones atenciones,
        ServicioCatalogos catalogos,
        ServicioFarmacia farmacia,
        ServicioBitacora bitacora,
        AppDbContext db,
        IConfiguration config)
    {
        _atenciones = atenciones;
        _catalogos = catalogos;
        _farmacia = farmacia;
        _bitacora = bitacora;
        _db = db;
        _config = config;
    }

    [HttpGet]
    public async Task<IActionResult> Index(
        ListadoAtencionesViewModel filtro, CancellationToken ct)
    {
        // Las fechas malformadas ya dejaron su error en ModelState; el rango
        // invertido se informa en lugar de simular una lista válida vacía.
        if (filtro.Desde.HasValue && filtro.Hasta.HasValue
            && filtro.Hasta.Value.Date < filtro.Desde.Value.Date)
            ModelState.AddModelError(string.Empty,
                "La fecha «Desde» no puede ser posterior a «Hasta».");

        if (!ModelState.IsValid)
            return View(filtro);

        var modelo = await _atenciones.ListarAsync(filtro, 25, ct);
        return View(modelo);
    }

    /// <summary>
    /// Nueva entrega para un paciente ya registrado. No hay forma de llegar acá
    /// sin haber elegido un paciente antes: es lo que garantiza el registro único.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Crear(int idPaciente, CancellationToken ct)
    {
        var paciente = await _db.Pacientes
            .AsNoTracking()
            .Include(p => p.Sexo)
            .FirstOrDefaultAsync(p => p.IdPaciente == idPaciente, ct);

        if (paciente is null) return NotFound();

        var modelo = new AtencionFormViewModel
        {
            IdPaciente = idPaciente,
            Paciente = paciente,
            FechaAtencion = DateTime.Today,
            Lineas = new List<LineaMedicamentoViewModel> { new() }
        };

        // Reutiliza el diagnóstico de la última atención: los pacientes vuelven
        // varias veces por el mismo tratamiento y reescribirlo es tiempo perdido.
        var ultima = await _db.Atenciones
            .AsNoTracking()
            .Include(a => a.Diagnostico)
            .Include(a => a.Establecimiento)
            .Where(a => a.IdPaciente == idPaciente && a.Estado == Atencion.EstadoRegistrada)
            .OrderByDescending(a => a.FechaAtencion)
            .ThenByDescending(a => a.IdAtencion)
            .FirstOrDefaultAsync(ct);

        if (ultima is not null)
        {
            modelo.IdDiagnostico = ultima.IdDiagnostico;
            modelo.Establecimiento = ultima.Establecimiento?.Nombre;
            modelo.IdCondicion = ultima.IdCondicion;
        }

        return await PrepararFormulario(modelo, ct);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> Crear(AtencionFormViewModel modelo, CancellationToken ct)
    {
        // La receta es obligatoria y el binder no puede validarla con un
        // atributo, porque en la edición puede venir vacía.
        if (modelo.ArchivoReceta is null || modelo.ArchivoReceta.Length == 0)
            ModelState.AddModelError(nameof(modelo.ArchivoReceta),
                "Adjunte la receta escaneada.");

        if (modelo.FechaAtencion.Date > DateTime.Today)
            ModelState.AddModelError(nameof(modelo.FechaAtencion),
                "La fecha de atención no puede ser futura.");
        else if (modelo.FechaAtencion.Date < ServicioAtenciones.AtencionMinima)
            ModelState.AddModelError(nameof(modelo.FechaAtencion),
                $"La fecha de atención no puede ser anterior a {ServicioAtenciones.AtencionMinima:dd/MM/yyyy}. Revise el año.");

        // El número se asigna al guardar (ServicioAtenciones), no se valida el
        // que viajó en el formulario.
        ModelState.Remove(nameof(modelo.NumeroFormulario));

        // Las líneas de medicamentos no tienen un <span> de validación por
        // campo: si el enlazador rechazó algún valor, se avisa arriba en lugar
        // de devolver el formulario sin explicación.
        var erroresLineas = ModelState
            .Where(e => e.Key.StartsWith(nameof(modelo.Lineas), StringComparison.OrdinalIgnoreCase)
                        && e.Value.Errors.Count > 0)
            .SelectMany(e => e.Value.Errors.Select(x => x.ErrorMessage))
            .Distinct()
            .ToList();

        if (erroresLineas.Count > 0)
            ModelState.AddModelError(string.Empty,
                "Revise los medicamentos: " + string.Join(" ", erroresLineas));

        if (!ModelState.IsValid)
            return await PrepararFormulario(modelo, ct);

        try
        {
            var atencion = await _atenciones.RegistrarAsync(modelo, User.IdUsuario(), ct);
            TempData["Exito"] =
                $"Entrega {atencion.NumeroFormulario} registrada. " +
                "Puede imprimir el comprobante para que lo firme el paciente.";

            return RedirectToAction(nameof(Detalle), new { id = atencion.IdAtencion });
        }
        catch (StockInsuficienteException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await PrepararFormulario(modelo, ct);
        }
        catch (Exception ex) when (ex is ReglaNegocioException or ArgumentException)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await PrepararFormulario(modelo, ct);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Detalle(int id, CancellationToken ct)
    {
        var atencion = await _atenciones.ObtenerCompletaAsync(id, ct);
        return atencion is null ? NotFound() : View(atencion);
    }

    /// <summary>Comprobante imprimible que firma el paciente.</summary>
    [HttpGet]
    public async Task<IActionResult> Comprobante(int id, CancellationToken ct)
    {
        var atencion = await _atenciones.ObtenerCompletaAsync(id, ct);
        if (atencion is null) return NotFound();

        return View(new ComprobanteViewModel
        {
            Atencion = atencion,
            NombreInstitucion = _config["Institucion:Nombre"] ?? "Institución",
            DireccionInstitucion = _config["Institucion:Direccion"],
            TelefonoInstitucion = _config["Institucion:Telefono"]
        });
    }

    /// <summary>
    /// Anula lógicamente una entrega y conserva el motivo en la auditoría. La
    /// operación está reservada al rol Administrador.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Anular(int id, CancellationToken ct)
    {
        var atencion = await _atenciones.ObtenerCompletaAsync(id, ct);
        if (atencion is null) return NotFound();

        if (atencion.EstaAnulada)
        {
            TempData["Error"] = "Esa entrega ya estaba anulada.";
            return RedirectToAction(nameof(Detalle), new { id });
        }

        return View(new AnularAtencionViewModel
        {
            IdAtencion = atencion.IdAtencion,
            NumeroFormulario = atencion.NumeroFormulario,
            Paciente = atencion.Paciente?.NombreCompleto ?? string.Empty,
            FechaAtencion = atencion.FechaAtencion,
            TieneConsumosDeInventario = atencion.Detalles.Any(d => d.CosteadoPorInventario)
        });
    }
    
    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Anular(AnularAtencionViewModel modelo, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return await RearmarAnulacion(modelo, ct);

        try
        {
            await _atenciones.AnularAsync(
                modelo.IdAtencion, modelo.Motivo, modelo.DevolverStock, User.IdUsuario(), ct);

            TempData["Exito"] =
                "La entrega fue anulada. El registro se conserva en el historial " +
                "porque el respaldo de auditoría no admite borrados.";

            return RedirectToAction(nameof(Detalle), new { id = modelo.IdAtencion });
        }
        catch (ReglaNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await RearmarAnulacion(modelo, ct);
        }
    }

    /// <summary>Repuebla los datos descriptivos desde la base al reenviar el formulario.</summary>
    private async Task<IActionResult> RearmarAnulacion(
        AnularAtencionViewModel modelo, CancellationToken ct)
    {
        var atencion = await _atenciones.ObtenerCompletaAsync(modelo.IdAtencion, ct);
        if (atencion is null) return NotFound();

        modelo.NumeroFormulario = atencion.NumeroFormulario;
        modelo.Paciente = atencion.Paciente?.NombreCompleto ?? string.Empty;
        modelo.FechaAtencion = atencion.FechaAtencion;
        modelo.TieneConsumosDeInventario = atencion.Detalles.Any(d => d.CosteadoPorInventario);

        return View(modelo);
    }

    [HttpGet]
    public async Task<IActionResult> SugerirMedicamentos(string termino, CancellationToken ct) =>
        Json(await _catalogos.SugerirMedicamentosAsync(termino ?? string.Empty, 10, ct));

    [HttpGet]
    public async Task<IActionResult> SugerirEstablecimientos(string termino, CancellationToken ct) =>
        Json(await _catalogos.SugerirEstablecimientosAsync(termino ?? string.Empty, 10, ct));

    [HttpGet]
    public async Task<IActionResult> ObtenerCatalogoMedicamentos(CancellationToken ct)
    {
        var hoy = DateTime.Today;

        var inventario = await _db.Medicamentos
            .AsNoTracking()
            .Include(m => m.UnidadMedida)
            .Where(m => m.Activo)
            .Select(m => new {
                nombre = m.Nombre,
                concentracion = m.Concentracion,
                unidad = m.UnidadMedida != null ? m.UnidadMedida.Descripcion : "",
                // Mismo corte que el FIFO: un lote con fecha futura no está disponible.
                stock = m.Lotes
                    // Un ingreso anulado no es stock: si contara acá, la casilla
                    // «Descontar del inventario» se marcaría sola sobre un
                    // medicamento que no tiene nada disponible.
                    .Where(l => l.CantidadDisponible > 0 && !l.Anulado && l.FechaIngreso <= hoy)
                    .Sum(l => (decimal?)l.CantidadDisponible) ?? 0
            })
            .OrderBy(m => m.nombre)
            .ToListAsync(ct);
        
        return Json(inventario);
    }

    /// <summary>
    /// Agrega un diagnóstico al catálogo desde el propio formulario de entrega.
    ///
    /// El diagnóstico se normaliza en un catálogo para que variantes de escritura
    /// no fragmenten las estadísticas.
    ///
    /// Cualquier usuario autenticado puede crear una opción faltante para no
    /// interrumpir la atención; modificar o desactivar opciones existentes sigue
    /// reservado al administrador. La creación queda registrada en la bitácora.
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AgregarDiagnosticoRapido(
        string descripcion, string? codigoCie10, CancellationToken ct)
    {
        var texto = descripcion?.Trim();

        if (string.IsNullOrWhiteSpace(texto))
            return Json(new { ok = false, mensaje = "Escriba el diagnóstico." });

        if (texto.Length > 160 || (codigoCie10?.Trim().Length ?? 0) > 10)
            return Json(new
            {
                ok = false,
                mensaje = "El diagnóstico admite hasta 160 caracteres y el código CIE-10 hasta 10."
            });

        var existente = await _db.Diagnosticos
            .FirstOrDefaultAsync(d => d.Descripcion == texto, ct);

        if (existente is not null)
        {
            // Si ya estaba pero desactivado, se reactiva en lugar de crear un
            // duplicado que rompería UQ_Diagnostico_Descripcion.
            if (!existente.Activo)
            {
                existente.Activo = true;
                await _db.SaveChangesAsync(ct);
            }

            return Json(new
            {
                ok = true,
                id = existente.IdDiagnostico,
                texto = EtiquetaDiagnostico(existente),
                mensaje = "Ese diagnóstico ya estaba en el catálogo; se seleccionó."
            });
        }

        var diagnostico = new Diagnostico
        {
            Descripcion = texto,
            CodigoCie10 = string.IsNullOrWhiteSpace(codigoCie10)
                ? null
                : codigoCie10.Trim().ToUpperInvariant(),
            Activo = true
        };

        _db.Diagnosticos.Add(diagnostico);

        try
        {
            await _db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ErroresBaseDatos.EsDuplicado(ex))
        {
            // Otra persona lo agregó en el mismo momento.
            return Json(new { ok = false, mensaje = "Ese diagnóstico acaba de agregarse. Recargue la página." });
        }

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "Diagnostico",
            diagnostico.IdDiagnostico,
            "INSERT",
            null,
            new { diagnostico.Descripcion, diagnostico.CodigoCie10, diagnostico.Activo },
            ct);

        return Json(new
        {
            ok = true,
            id = diagnostico.IdDiagnostico,
            texto = EtiquetaDiagnostico(diagnostico),
            mensaje = $"Se agregó el diagnóstico «{texto}»."
        });
    }

    private static string EtiquetaDiagnostico(Diagnostico d) =>
        string.IsNullOrWhiteSpace(d.CodigoCie10)
            ? d.Descripcion
            : $"{d.CodigoCie10} - {d.Descripcion}";

    /// <summary>
    /// Muestra de qué lotes saldría una entrega y a qué precio antes de
    /// confirmarla.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> SimularCosto(
        string medicamento, decimal cantidad, DateTime? fecha, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(medicamento) || cantidad <= 0)
            return Json(new { hayInventario = false });

        // El mismo criterio con que se resolverá el nombre al guardar, para que
        // la vista previa hable del medicamento que realmente se va a usar.
        var med = await _catalogos.BuscarMedicamentoAsync(medicamento, ct);

        if (med is null)
            return Json(new { hayInventario = false });

        // Sólo cuentan los lotes que ya habían ingresado a la fecha de la
        // entrega, igual que en sp_ConsumirLotesFifo.
        var disponible = await _farmacia.StockDisponibleAsync(med.IdMedicamento, fecha, ct);
        var disponibleHoy = await _farmacia.StockDisponibleAsync(med.IdMedicamento, null, ct);
        var reparto = await _farmacia.SimularFifoAsync(med.IdMedicamento, cantidad, fecha, ct);

        return Json(new
        {
            hayInventario = disponibleHoy > 0,
            // Hay unidades en farmacia, pero ingresaron después de la fecha de
            // la entrega: el mensaje tiene que decir eso y no «sin stock».
            lotesPosteriores = disponibleHoy > disponible,
            stockDisponible = disponible,
            suficiente = disponible >= cantidad,
            monto = reparto.Sum(r => r.Subtotal),
            lotes = reparto.Select(r => new
            {
                r.NumeroLote,
                fecha = r.FechaIngreso.ToString("dd/MM/yyyy"),
                r.TipoIngreso,
                r.Cantidad,
                r.CostoUnitario,
                r.Subtotal
            })
        });
    }

    private async Task<IActionResult> PrepararFormulario(
        AtencionFormViewModel modelo, CancellationToken ct)
    {
        modelo.Paciente ??= await _db.Pacientes
            .AsNoTracking()
            .Include(p => p.Sexo)
            .FirstOrDefaultAsync(p => p.IdPaciente == modelo.IdPaciente, ct);

        modelo.Condiciones = await _db.CondicionesAtencion
            .AsNoTracking()
            .Where(c => c.Activo)
            .OrderBy(c => c.IdCondicion)
            .ToListAsync(ct);
        modelo.Diagnosticos = await _db.Diagnosticos
            .AsNoTracking()
            .Where(d => d.Activo)
            .OrderBy(d => d.Descripcion)
            .ToListAsync(ct);

        modelo.InventarioDisponible = await _db.Lotes
            .AsNoTracking()
            .AnyAsync(l => l.CantidadDisponible > 0 && !l.Anulado, ct);

        // El número que se muestra es una vista previa: el definitivo se
        // asigna al guardar. Al volver con errores se recalcula, porque otra
        // persona pudo haber registrado una entrega mientras tanto.
        ModelState.Remove(nameof(modelo.NumeroFormulario));
        modelo.NumeroFormulario = await _catalogos.SugerirNumeroFormularioAsync(ct);

        if (modelo.Lineas.Count == 0)
            modelo.Lineas.Add(new LineaMedicamentoViewModel());

        return View(modelo);
    }
}
