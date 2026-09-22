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
/// Inventario de medicamentos por lotes. Cada ingreso conserva su costo y las
/// salidas se valoran consumiendo primero los lotes más antiguos.
/// </summary>
public class FarmaciaController : Controller
{
    private readonly AppDbContext _db;
    private readonly ServicioFarmacia _farmacia;
    private readonly ServicioCatalogos _catalogos;

    public FarmaciaController(
        AppDbContext db,
        ServicioFarmacia farmacia,
        ServicioCatalogos catalogos)
    {
        _db = db;
        _farmacia = farmacia;
        _catalogos = catalogos;
    }

    /// <summary>Existencias actuales y su valor a costo real de adquisición.</summary>
    [HttpGet]
    public async Task<IActionResult> Index(
        string? criterio, bool soloConStock = true, CancellationToken ct = default)
    {
        var limite = DateTime.Today.AddDays(90);

        var modelo = new InventarioViewModel
        {
            Criterio = criterio,
            SoloConStock = soloConStock,
            CriterioInvalido = CriterioBusqueda.EsInvalido(criterio, CriterioBusqueda.Limpiar(criterio)),
            HayMedicamentosRegistrados = await _db.Medicamentos.AnyAsync(ct),
            Existencias = await _farmacia.ExistenciasAsync(criterio, soloConStock, ct),
            LotesPorVencer = await _db.Lotes
                .AsNoTracking()
                .Include(l => l.Medicamento)
                .Where(l => l.CantidadDisponible > 0
                            && !l.Anulado
                            && l.FechaVencimiento != null
                            && l.FechaVencimiento <= limite)
                .OrderBy(l => l.FechaVencimiento)
                .ToListAsync(ct)
        };

        return View(modelo);
    }

    [HttpGet]
    public async Task<IActionResult> Ingresar(CancellationToken ct)
    {
        var modelo = new IngresoLoteViewModel
        {
            FechaIngreso = DateTime.Today,
            TiposIngreso = await _db.TiposIngreso.AsNoTracking().ToListAsync(ct),
            UnidadesMedida = await _db.UnidadesMedida.AsNoTracking().ToListAsync(ct)
        };

        return View(modelo);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Ingresar(IngresoLoteViewModel modelo, CancellationToken ct)
    {
        if (modelo.FechaVencimiento.HasValue
            && modelo.FechaVencimiento.Value.Date <= modelo.FechaIngreso.Date)
        {
            ModelState.AddModelError(nameof(modelo.FechaVencimiento),
                "El vencimiento debe ser posterior a la fecha de ingreso.");
        }

        // Una fecha futura volvería el lote elegible para entregas anteriores a
        // su ingreso real.
        if (modelo.FechaIngreso.Date > DateTime.Today)
        {
            ModelState.AddModelError(nameof(modelo.FechaIngreso),
                "La fecha de ingreso no puede ser posterior a hoy.");
        }
        else if (modelo.FechaIngreso.Date < ServicioFarmacia.IngresoMinimo)
        {
            ModelState.AddModelError(nameof(modelo.FechaIngreso),
                $"La fecha de ingreso no puede ser anterior a {ServicioFarmacia.IngresoMinimo:dd/MM/yyyy}. Revise el año.");
        }

        // La base guarda dos decimales; un tercero se perdería sin aviso.
        if (decimal.Round(modelo.CantidadIngresada, 2) != modelo.CantidadIngresada)
            ModelState.AddModelError(nameof(modelo.CantidadIngresada),
                "Use como máximo dos decimales en la cantidad.");

        if (decimal.Round(modelo.CostoUnitario, 2) != modelo.CostoUnitario)
            ModelState.AddModelError(nameof(modelo.CostoUnitario),
                "Use como máximo dos decimales en el costo.");

        if (modelo.IdUnidadMedida.HasValue
            && !await _db.UnidadesMedida.AnyAsync(u => u.IdUnidadMedida == modelo.IdUnidadMedida, ct))
            ModelState.AddModelError(nameof(modelo.IdUnidadMedida),
                "La unidad de medida seleccionada no existe.");

        if (modelo.IdTipoIngreso > 0
            && !await _db.TiposIngreso.AnyAsync(t => t.IdTipoIngreso == modelo.IdTipoIngreso, ct))
            ModelState.AddModelError(nameof(modelo.IdTipoIngreso),
                "Seleccione cómo llegó el medicamento.");

        if (!ModelState.IsValid)
            return await VolverAlFormularioIngreso(modelo, ct);

        try
        {
            var medicamento = await _catalogos.ObtenerOCrearMedicamentoAsync(
            modelo.Medicamento,
            User.IdUsuario(),
            ct);

            // La unidad de medida se completa la primera vez que se declara.
            if (modelo.IdUnidadMedida.HasValue && medicamento.IdUnidadMedida is null)
            {
                medicamento.IdUnidadMedida = modelo.IdUnidadMedida;
                await _db.SaveChangesAsync(ct);
            }

            var lote = new Lote
            {
                IdMedicamento = medicamento.IdMedicamento,
                IdTipoIngreso = modelo.IdTipoIngreso,
                NumeroLote = string.IsNullOrWhiteSpace(modelo.NumeroLote)
                    ? null : modelo.NumeroLote.Trim(),
                FechaIngreso = modelo.FechaIngreso.Date,
                FechaVencimiento = modelo.FechaVencimiento?.Date,
                CantidadIngresada = modelo.CantidadIngresada,
                CostoUnitario = modelo.CostoUnitario,
                Origen = string.IsNullOrWhiteSpace(modelo.Origen) ? null : modelo.Origen.Trim(),
                NumeroFactura = string.IsNullOrWhiteSpace(modelo.NumeroFactura)
                    ? null : modelo.NumeroFactura.Trim(),
                IdUsuarioRegistro = User.IdUsuario()
            };

            await _farmacia.RegistrarIngresoAsync(lote, ct);

            TempData["Exito"] =
                $"Ingresaron {modelo.CantidadIngresada:0.##} unidades de {medicamento.Nombre} " +
                $"a {modelo.CostoUnitario:N2} Bs c/u ({modelo.ValorTotal:N2} Bs en total).";

            return RedirectToAction(nameof(Lotes), new { id = medicamento.IdMedicamento });
        }
        catch (Exception ex) when (ex is ReglaNegocioException or ArgumentException)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await VolverAlFormularioIngreso(modelo, ct);
        }
        catch (DbUpdateException ex)
        {
            ModelState.AddModelError(string.Empty,
                ErroresBaseDatos.EsDuplicado(ex, "UQ_Medicamento_Nombre")
                    ? "Otra persona registró ese medicamento al mismo tiempo. Vuelva a guardar el ingreso."
                    : "No se pudo registrar el ingreso. Revise los datos e intente nuevamente.");
            return await VolverAlFormularioIngreso(modelo, ct);
        }
    }

    /// <summary>
    /// Corrige un ingreso que aún no tiene consumos. La operación está reservada
    /// al rol Administrador.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Editar(int id, CancellationToken ct)
    {
        var lote = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.Medicamento)
            .FirstOrDefaultAsync(l => l.IdLote == id, ct);

        if (lote is null) return NotFound();

        if (lote.Anulado)
        {
            TempData["Error"] = "Ese ingreso está anulado y ya no se corrige. Si las " +
                                "unidades siguen en el depósito, regístrelas de nuevo.";
            return RedirectToAction(nameof(Lotes), new { id = lote.IdMedicamento });
        }

        if (await _farmacia.TieneSalidasAsync(lote.IdLote, ct))
        {
            TempData["Error"] = "De ese ingreso ya salieron medicamentos, así que no se " +
                                "puede corregir sin cambiar el monto de entregas ya " +
                                "registradas. Anúlelo y cargue el ingreso correcto.";
            return RedirectToAction(nameof(Anular), new { id = lote.IdLote });
        }

        return View(new EdicionLoteViewModel
        {
            IdLote = lote.IdLote,
            IdMedicamento = lote.IdMedicamento,
            Medicamento = lote.Medicamento?.Nombre ?? string.Empty,
            IdTipoIngreso = lote.IdTipoIngreso,
            NumeroLote = lote.NumeroLote,
            FechaIngreso = lote.FechaIngreso,
            FechaVencimiento = lote.FechaVencimiento,
            CantidadIngresada = lote.CantidadIngresada,
            CostoUnitario = lote.CostoUnitario,
            Origen = lote.Origen,
            NumeroFactura = lote.NumeroFactura,
            ValorOriginal = lote.CantidadIngresada * lote.CostoUnitario,
            TiposIngreso = await _db.TiposIngreso.AsNoTracking().ToListAsync(ct)
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Editar(EdicionLoteViewModel modelo, CancellationToken ct)
    {
        // Las mismas verificaciones que el alta: la base guarda dos decimales y
        // un tercero se perdería sin aviso.
        if (decimal.Round(modelo.CantidadIngresada, 2) != modelo.CantidadIngresada)
            ModelState.AddModelError(nameof(modelo.CantidadIngresada),
                "Use como máximo dos decimales en la cantidad.");

        if (decimal.Round(modelo.CostoUnitario, 2) != modelo.CostoUnitario)
            ModelState.AddModelError(nameof(modelo.CostoUnitario),
                "Use como máximo dos decimales en el costo.");

        if (modelo.FechaVencimiento.HasValue
            && modelo.FechaVencimiento.Value.Date <= modelo.FechaIngreso.Date)
            ModelState.AddModelError(nameof(modelo.FechaVencimiento),
                "El vencimiento debe ser posterior a la fecha de ingreso.");

        if (modelo.FechaIngreso.Date > DateTime.Today)
            ModelState.AddModelError(nameof(modelo.FechaIngreso),
                "La fecha de ingreso no puede ser posterior a hoy.");
        else if (modelo.FechaIngreso.Date < ServicioFarmacia.IngresoMinimo)
            ModelState.AddModelError(nameof(modelo.FechaIngreso),
                $"La fecha de ingreso no puede ser anterior a {ServicioFarmacia.IngresoMinimo:dd/MM/yyyy}. Revise el año.");

        if (modelo.IdTipoIngreso > 0
            && !await _db.TiposIngreso.AnyAsync(t => t.IdTipoIngreso == modelo.IdTipoIngreso, ct))
            ModelState.AddModelError(nameof(modelo.IdTipoIngreso),
                "Seleccione cómo llegó el medicamento.");

        if (!ModelState.IsValid)
            return await VolverAlFormularioEdicion(modelo, ct);

        try
        {
            // El medicamento no viaja en el formulario: se conserva el del lote
            // guardado, para que nadie pueda mover un ingreso de un medicamento
            // a otro desde el navegador.
            var lote = await _farmacia.EditarLoteAsync(
                new Lote
                {
                    IdLote = modelo.IdLote,
                    IdTipoIngreso = modelo.IdTipoIngreso,
                    NumeroLote = modelo.NumeroLote,
                    FechaIngreso = modelo.FechaIngreso,
                    FechaVencimiento = modelo.FechaVencimiento,
                    CantidadIngresada = modelo.CantidadIngresada,
                    CostoUnitario = modelo.CostoUnitario,
                    Origen = modelo.Origen,
                    NumeroFactura = modelo.NumeroFactura
                },
                User.IdUsuario(),
                ct);

            TempData["Exito"] =
                $"Ingreso corregido: {lote.CantidadIngresada:0.##} unidades a " +
                $"{lote.CostoUnitario:N2} Bs c/u ({lote.CantidadIngresada * lote.CostoUnitario:N2} Bs en total).";

            return RedirectToAction(nameof(Lotes), new { id = lote.IdMedicamento });
        }
        catch (ReglaNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await VolverAlFormularioEdicion(modelo, ct);
        }
        catch (DbUpdateException)
        {
            ModelState.AddModelError(string.Empty,
                "No se pudo guardar la corrección. Revise los datos e intente nuevamente.");
            return await VolverAlFormularioEdicion(modelo, ct);
        }
    }

    /// <summary>
    /// Da de baja un ingreso mal cargado. El lote sale del inventario pero no
    /// se borra, y las entregas que ya salieron de él conservan su costo.
    /// </summary>
    [HttpGet]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Anular(int id, CancellationToken ct)
    {
        var modelo = await ArmarAnulacionAsync(id, ct);

        if (modelo is null) return NotFound();

        if (modelo.YaAnulado)
        {
            TempData["Error"] = "Ese ingreso ya estaba anulado.";
            return RedirectToAction(nameof(Lotes), new { id = modelo.IdMedicamento });
        }

        // De un lote agotado no queda nada para dar de baja: anularlo no
        // cambiaría el inventario y sólo lo dejaría bloqueado. Se avisa acá, en
        // vez de dejar que escriba el motivo y recibir el rechazo al guardar.
        if (modelo.CantidadDisponible <= 0)
        {
            TempData["Error"] = "De ese ingreso ya salió todo, así que anularlo no " +
                                "cambiaría el inventario. Si alguna entrega quedó con un " +
                                "monto equivocado, anule esa entrega desde su pantalla.";
            return RedirectToAction(nameof(Lotes), new { id = modelo.IdMedicamento });
        }

        return View(modelo);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize(Roles = Rol.Administrador)]
    public async Task<IActionResult> Anular(AnulacionLoteViewModel modelo, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return await VolverAlFormularioAnulacion(modelo, ct);

        try
        {
            var lote = await _farmacia.AnularLoteAsync(
                modelo.IdLote, modelo.Motivo, User.IdUsuario(), ct);

            TempData["Exito"] =
                $"Ingreso anulado. Salen del inventario {lote.CantidadDisponible:0.##} unidades " +
                $"por {lote.CantidadDisponible * lote.CostoUnitario:N2} Bs. Las entregas que ya " +
                "se habían hecho con este lote no cambian.";

            return RedirectToAction(nameof(Lotes), new { id = lote.IdMedicamento });
        }
        catch (ReglaNegocioException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return await VolverAlFormularioAnulacion(modelo, ct);
        }
        catch (DbUpdateException)
        {
            ModelState.AddModelError(string.Empty,
                "No se pudo anular el ingreso. Intente nuevamente.");
            return await VolverAlFormularioAnulacion(modelo, ct);
        }
    }

    /// <summary>
    /// Arma la pantalla de anulación releyendo todo de la base. Lo único que el
    /// formulario aporta es el identificador y el motivo.
    /// </summary>
    private async Task<AnulacionLoteViewModel?> ArmarAnulacionAsync(
        int idLote, CancellationToken ct)
    {
        var lote = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.Medicamento)
            .FirstOrDefaultAsync(l => l.IdLote == idLote, ct);

        if (lote is null) return null;

        // Qué entregas se hicieron con este lote. No se tocan, pero quien anula
        // tiene que poder verlas: son las que quedan con el costo equivocado.
        var salidas = await _db.ConsumosLote
            .AsNoTracking()
            .Where(c => c.IdLote == idLote)
            .OrderByDescending(c => c.AtencionDetalle!.Atencion!.FechaAtencion)
            .ThenByDescending(c => c.IdConsumo)
            .Select(c => new SalidaDeLote(
                c.AtencionDetalle!.IdAtencion,
                c.AtencionDetalle.Atencion!.NumeroFormulario,
                c.AtencionDetalle.Atencion.FechaAtencion,
                c.AtencionDetalle.Atencion.Paciente!.ApellidoPaterno + ", " +
                    c.AtencionDetalle.Atencion.Paciente.Nombres,
                c.Cantidad,
                c.Subtotal))
            .ToListAsync(ct);

        return new AnulacionLoteViewModel
        {
            IdLote = lote.IdLote,
            IdMedicamento = lote.IdMedicamento,
            Medicamento = lote.Medicamento?.Nombre ?? string.Empty,
            FechaIngreso = lote.FechaIngreso,
            CantidadIngresada = lote.CantidadIngresada,
            CantidadDisponible = lote.CantidadDisponible,
            CostoUnitario = lote.CostoUnitario,
            YaAnulado = lote.Anulado,
            TieneSalidas = salidas.Count > 0,
            Salidas = salidas
        };
    }

    private async Task<IActionResult> VolverAlFormularioEdicion(
        EdicionLoteViewModel modelo, CancellationToken ct)
    {
        modelo.TiposIngreso = await _db.TiposIngreso.AsNoTracking().ToListAsync(ct);

        // El nombre del medicamento y el valor original son informativos y no
        // viajan en el formulario: se releen para que la pantalla no vuelva en
        // blanco después de un error.
        var lote = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.Medicamento)
            .FirstOrDefaultAsync(l => l.IdLote == modelo.IdLote, ct);

        if (lote is not null)
        {
            modelo.IdMedicamento = lote.IdMedicamento;
            modelo.Medicamento = lote.Medicamento?.Nombre ?? string.Empty;
            modelo.ValorOriginal = lote.CantidadIngresada * lote.CostoUnitario;
        }

        return View(nameof(Editar), modelo);
    }

    private async Task<IActionResult> VolverAlFormularioAnulacion(
        AnulacionLoteViewModel modelo, CancellationToken ct)
    {
        var recargado = await ArmarAnulacionAsync(modelo.IdLote, ct);

        if (recargado is null) return NotFound();

        recargado.Motivo = modelo.Motivo;
        return View(nameof(Anular), recargado);
    }

    /// <summary>
    /// Lotes de un medicamento, del más antiguo al más nuevo. Es la pantalla que
    /// muestra por qué el promedio no sirve: la misma fila puede tener 70 Bs y
    /// 150 Bs, y la próxima entrega saldrá de la de arriba.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Lotes(int id, CancellationToken ct)
    {
        var medicamento = await _db.Medicamentos
            .AsNoTracking()
            .Include(m => m.UnidadMedida)
            .FirstOrDefaultAsync(m => m.IdMedicamento == id, ct);

        if (medicamento is null) return NotFound();

        var lotes = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.TipoIngreso)
            .Where(l => l.IdMedicamento == id)
            // Primero lo que el FIFO va a consumir, después lo agotado y al
            // final los ingresos anulados, que ya no son inventario.
            .OrderBy(l => l.Anulado ? 2 : (l.CantidadDisponible > 0 ? 0 : 1))
            .ThenBy(l => l.FechaIngreso)
            .ThenBy(l => l.IdLote)
            .ToListAsync(ct);

        return View(new LotesMedicamentoViewModel
        {
            Medicamento = medicamento,
            Lotes = lotes
        });
    }

    /// <summary>Kardex: todos los movimientos de un medicamento.</summary>
    [HttpGet]
    public async Task<IActionResult> Kardex(
        int? idMedicamento, DateTime? desde, DateTime? hasta, CancellationToken ct)
    {
        var modelo = new KardexViewModel
        {
            IdMedicamento = idMedicamento,
            Desde = desde,
            Hasta = hasta,
            Medicamentos = await _db.Medicamentos
                .AsNoTracking()
                .Where(m => m.Activo || m.IdMedicamento == idMedicamento)
                .OrderBy(m => m.Nombre)
                .ToListAsync(ct)
        };

        // Las fechas malformadas ya dejaron su error en ModelState; un rango
        // invertido se informa en lugar de ignorarse.
        if (desde.HasValue && hasta.HasValue && hasta.Value.Date < desde.Value.Date)
            ModelState.AddModelError(string.Empty,
                "La fecha «Desde» no puede ser posterior a «Hasta».");

        if (idMedicamento.HasValue
            && modelo.Medicamentos.All(m => m.IdMedicamento != idMedicamento.Value))
            ModelState.AddModelError(string.Empty, "El medicamento indicado no existe.");

        if (!ModelState.IsValid)
            return View(modelo);

        if (idMedicamento.HasValue)
        {
            var consulta = _db.Kardex
                .AsNoTracking()
                .Where(k => k.IdMedicamento == idMedicamento.Value);

            if (desde.HasValue) consulta = consulta.Where(k => k.Fecha >= desde.Value.Date);
            if (hasta.HasValue) consulta = consulta.Where(k => k.Fecha <= hasta.Value.Date);

            modelo.Movimientos = await consulta
                .OrderBy(k => k.Fecha)
                .ThenBy(k => k.Movimiento)
                .ToListAsync(ct);

            modelo.NombreMedicamento = modelo.Medicamentos
                .FirstOrDefault(m => m.IdMedicamento == idMedicamento.Value)?.Nombre;
        }

        return View(modelo);
    }

    /// <summary>Simulación del reparto FIFO, para explicarlo o verificarlo.</summary>
    [HttpGet]
    public async Task<IActionResult> Simular(int id, decimal cantidad, CancellationToken ct)
    {
        var medicamento = await _db.Medicamentos
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.IdMedicamento == id, ct);

        if (medicamento is null) return NotFound();

        if (cantidad <= 0)
        {
            TempData["Error"] = "Indique una cantidad mayor que cero para simular el reparto.";
            return RedirectToAction(nameof(Lotes), new { id });
        }

        var disponible = await _farmacia.StockDisponibleAsync(id, null, ct);
        var reparto = await _farmacia.SimularFifoAsync(id, cantidad, null, ct);

        return View(new SimulacionFifoViewModel
        {
            Medicamento = medicamento.Nombre,
            Cantidad = cantidad,
            Reparto = reparto,
            StockDisponible = disponible,
            StockSuficiente = disponible >= cantidad
        });
    }

    private async Task<IActionResult> VolverAlFormularioIngreso(
        IngresoLoteViewModel modelo, CancellationToken ct)
    {
        modelo.TiposIngreso = await _db.TiposIngreso.AsNoTracking().ToListAsync(ct);
        modelo.UnidadesMedida = await _db.UnidadesMedida.AsNoTracking().ToListAsync(ct);
        return View(nameof(Ingresar), modelo);
    }
}
