using System.Globalization;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.ViewModels;
using SistemaDonaciones.Web.Servicios;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Controllers;

/// <summary>
/// Estadísticas, exportaciones y constancias de respaldo.
///
/// Los filtros se validan antes de consultar para no mostrar ni registrar un
/// período distinto del solicitado.
/// </summary>
public class ReportesController : Controller
{
    private const string MensajeRangoInvertido =
        "La fecha «Desde» no puede ser posterior a «Hasta».";

    private readonly AppDbContext _db;
    private readonly ServicioReportes _reportes;
    // Resolver Value sólo al construir el mapa evita que una configuración
    // inválida de su escala bloquee las demás acciones de reportes.
    private readonly IOptions<OpcionesMapa> _escalaMapa;

    public ReportesController(
    ServicioReportes reportes,
    AppDbContext db,
    IOptions<OpcionesMapa> escalaMapa)
    {
        _reportes = reportes;
        _db = db;
        _escalaMapa = escalaMapa;
    }

    /// <summary>
    /// Estadísticas con filtros combinables: período, sexo, edad, ubicación,
    /// diagnóstico y condición.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Index(
    DateTime? desde,
    DateTime? hasta,
    int? anio,
    int? mes,
    byte? idSexo,
    int? edadDesde,
    int? edadHasta,
    short? idPaisOrigen,
    int? idDepartamento,
    int? idProvincia,
    int? idMunicipio,
    int? idDiagnostico,
    byte? idCondicion,
    CancellationToken ct)
    {
        var modelo = new ReporteEstadisticoViewModel();

        if (desde.HasValue)
            modelo.Desde = desde.Value;

        if (hasta.HasValue)
            modelo.Hasta = hasta.Value;

        modelo.Anio = anio;
        modelo.Mes = mes;
        modelo.IdSexo = idSexo;
        modelo.EdadDesde = edadDesde;
        modelo.EdadHasta = edadHasta;
        modelo.IdPaisOrigen = idPaisOrigen;
        modelo.IdDepartamento = idDepartamento;
        modelo.IdProvincia = idProvincia;
        modelo.IdMunicipio = idMunicipio;
        modelo.IdDiagnostico = idDiagnostico;
        modelo.IdCondicion = idCondicion;

        if (anio is < 1900 or > 9999)
            ModelState.AddModelError(nameof(anio), "El año indicado no es válido.");

        if (mes is < 1 or > 12)
            ModelState.AddModelError(nameof(mes), "El mes debe estar entre 1 y 12.");

        if (edadDesde is < 0 or > 150)
            ModelState.AddModelError(nameof(edadDesde), "La edad «desde» debe estar entre 0 y 150.");

        if (edadHasta is < 0 or > 150)
            ModelState.AddModelError(nameof(edadHasta), "La edad «hasta» debe estar entre 0 y 150.");

        if (edadDesde.HasValue && edadHasta.HasValue && edadDesde > edadHasta)
            ModelState.AddModelError(string.Empty,
                "La edad «desde» no puede ser mayor que la edad «hasta».");

        // El año o mes seleccionado reemplaza el rango predeterminado enviado
        // por el formulario; ambos filtros no deben intersectarse.
        if (ModelState.IsValid && modelo.Anio.HasValue)
        {
            var inicio = modelo.Mes.HasValue
                ? new DateTime(modelo.Anio.Value, modelo.Mes.Value, 1)
                : new DateTime(modelo.Anio.Value, 1, 1);

            modelo.Desde = inicio;
            modelo.Hasta = modelo.Mes.HasValue
                ? inicio.AddMonths(1).AddDays(-1)
                : new DateTime(modelo.Anio.Value, 12, 31);
        }
        // Un mes sin año se sigue aplicando dentro del rango de fechas elegido,
        // que es lo que hace el filtro por mes del servicio.

        if (modelo.Hasta.Date < modelo.Desde.Date)
            ModelState.AddModelError(string.Empty, MensajeRangoInvertido);

        modelo.Sexos = await _db.Sexos
            .AsNoTracking()
            .Where(s => s.Activo)
            .OrderBy(s => s.Descripcion)
            .ToListAsync(ct);

        modelo.Condiciones = await _db.CondicionesAtencion
            .AsNoTracking()
            .Where(c => c.Activo)
            .OrderBy(c => c.Descripcion)
            .ToListAsync(ct);

        modelo.Diagnosticos = await _db.Diagnosticos
            .AsNoTracking()
            .Where(d => d.Activo)
            .OrderBy(d => d.Descripcion)
            .ToListAsync(ct);

        modelo.Paises = await _db.Paises
            .AsNoTracking()
            .Where(p => p.Activo)
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

        // Con filtros inválidos no se consulta: mostrar cifras de otro período
        // sería peor que no mostrar nada.
        if (!ModelState.IsValid)
            return View(modelo);

        modelo = await _reportes.EstadisticoAvanzadoAsync(
            modelo,
            ct);

        return View(modelo);
    }

    /// <summary>Medicamentos más entregados y cuánto representan.</summary>
    [HttpGet]
    public async Task<IActionResult> Medicamentos(
        DateTime? desde, DateTime? hasta, CancellationToken ct)
    {
        var modelo = new ReporteMedicamentosViewModel();
        if (desde.HasValue) modelo.Desde = desde.Value;
        if (hasta.HasValue) modelo.Hasta = hasta.Value;

        if (modelo.Hasta.Date < modelo.Desde.Date)
            ModelState.AddModelError(string.Empty, MensajeRangoInvertido);

        if (!ModelState.IsValid)
            return View(modelo);

        modelo.Filas = await _reportes.MedicamentosAsync(modelo.Desde, modelo.Hasta, ct);

        return View(modelo);
    }

    /// <summary>Exportación a CSV, que Excel abre directamente.</summary>
    [HttpGet]
    public async Task<IActionResult> ExportarCsv(
        DateTime? desde, DateTime? hasta, CancellationToken ct)
    {
        // Evita que un DateTime predeterminado llegue a la consulta o al nombre.
        if (!ModelState.IsValid || desde is null || hasta is null)
        {
            TempData["Error"] = "Para exportar indique fechas «Desde» y «Hasta» válidas.";
            return RedirectToAction(nameof(Respaldos));
        }

        if (hasta.Value.Date < desde.Value.Date)
        {
            TempData["Error"] = MensajeRangoInvertido;
            return RedirectToAction(nameof(Respaldos));
        }

        var contenido = await _reportes.ExportarCsvAsync(desde.Value, hasta.Value, ct);
        var nombre = $"entregas_{desde:yyyyMMdd}_{hasta:yyyyMMdd}.csv";

        return File(contenido, "text/csv", nombre);
    }

    /// <summary>Registro de las copias de respaldo enviadas al exterior.</summary>
    [HttpGet]
    public async Task<IActionResult> Respaldos(CancellationToken ct) =>
        View(new ExportacionViewModel
        {
            Historial = await _reportes.HistorialExportacionesAsync(ct)
        });

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Respaldos(ExportacionViewModel modelo, CancellationToken ct)
    {
        // La constancia conserva el período escrito; no se invierte ni completa.
        if (modelo.Hasta.Date < modelo.Desde.Date)
            ModelState.AddModelError(string.Empty, MensajeRangoInvertido);

        if (!ModelState.IsValid)
        {
            modelo.Historial = await _reportes.HistorialExportacionesAsync(ct);
            return View(modelo);
        }

        var registro = await _reportes.RegistrarExportacionAsync(
            modelo.Desde, modelo.Hasta, modelo.Destino, modelo.Observaciones,
            User.IdUsuario(), ct);

        TempData["Exito"] =
            $"Quedó registrada la exportación del período " +
            $"{registro.PeriodoDesde:dd/MM/yyyy} al {registro.PeriodoHasta:dd/MM/yyyy} " +
            $"({registro.CantidadAtenciones} atenciones).";

        return RedirectToAction(nameof(Respaldos));
    }

    /// <summary>Tablero gráfico (Dashboard) con porcentajes y estadísticas rápidas.</summary>
    [HttpGet]
    public async Task<IActionResult> Porcentajes(DateTime? desde, DateTime? hasta, CancellationToken ct)
    {
        var modelo = new DashboardPorcentajesViewModel();
        if (desde.HasValue) modelo.Desde = desde.Value;
        if (hasta.HasValue) modelo.Hasta = hasta.Value;

        if (modelo.Hasta.Date < modelo.Desde.Date)
            ModelState.AddModelError(string.Empty, MensajeRangoInvertido);

        if (!ModelState.IsValid)
            return View(modelo);

        var filtroBase = new ReporteEstadisticoViewModel { Desde = modelo.Desde, Hasta = modelo.Hasta };
        var estadisticas = await _reportes.EstadisticoAvanzadoAsync(filtroBase, ct);

        modelo.MontoTotalAhorrado = estadisticas.MontoTotal;

        modelo.SexoLabels = estadisticas.PorSexo.Select(x => x.Nombre).ToList();
        modelo.SexoValues = estadisticas.PorSexo.Select(x => x.Pacientes).ToList();

        modelo.EdadLabels = estadisticas.PorEdad.Select(x => x.Nombre).ToList();
        modelo.EdadValues = estadisticas.PorEdad.Select(x => x.Pacientes).ToList();

        modelo.CondicionLabels = estadisticas.PorCondicion.Select(x => x.Nombre).ToList();
        modelo.CondicionValues = estadisticas.PorCondicion.Select(x => x.Pacientes).ToList();

        modelo.DiagnosticoLabels = estadisticas.PorDiagnostico.Select(x => x.Nombre).ToList();
        modelo.DiagnosticoValues = estadisticas.PorDiagnostico.Select(x => x.Pacientes).ToList();

        modelo.DepartamentoLabels = estadisticas.PorDepartamento.Select(x => x.Nombre).ToList();
        modelo.DepartamentoValues = estadisticas.PorDepartamento.Select(x => x.Pacientes).ToList();
        modelo.AtencionesPorResidencia = estadisticas.AtencionesPorResidencia;
        modelo.AtencionesDelExterior = estadisticas.AtencionesDelExterior;

        // Se limita el gráfico para mantener legibles las etiquetas.
        modelo.MunicipioLabels = estadisticas.PorMunicipio.OrderByDescending(x => x.Pacientes).Take(10).Select(x => x.Nombre).ToList();
        modelo.MunicipioValues = estadisticas.PorMunicipio.OrderByDescending(x => x.Pacientes).Take(10).Select(x => x.Pacientes).ToList();

        modelo.MesLabels = estadisticas.EvolucionMensual.Select(x => x.Periodo).ToList();
        modelo.MesValues = estadisticas.EvolucionMensual.Select(x => x.Atenciones).ToList();

        var topMedicamentos = await _db.AtencionDetalles
            .AsNoTracking()
            .Include(d => d.Medicamento)
            .Where(d => d.Atencion!.Estado != Atencion.EstadoAnulada && d.Atencion.FechaAtencion >= modelo.Desde.Date && d.Atencion.FechaAtencion <= modelo.Hasta.Date)
            .GroupBy(d => d.Medicamento!.Nombre)
            .Select(g => new { Nombre = g.Key, Cantidad = g.Sum(x => x.Cantidad) })
            .OrderByDescending(x => x.Cantidad)
            .Take(5)
            .ToListAsync(ct);

        modelo.TopMedicamentosNombres = topMedicamentos.Select(m => m.Nombre).ToList();
        modelo.TopMedicamentosCantidades = topMedicamentos.Select(m => m.Cantidad).ToList();

        return View(modelo);
    }

    [HttpGet]
    public async Task<IActionResult> MapaDeCalor(int? idDiagnostico, CancellationToken ct)
    {
        var modelo = new MapaCalorViewModel
        {
            IdDiagnostico = idDiagnostico,
            Diagnosticos = await _db.Diagnosticos
                .AsNoTracking()
                .Where(d => d.Activo || d.IdDiagnostico == idDiagnostico)
                .OrderBy(d => d.Descripcion)
                .ToListAsync(ct)
        };

        // La vista necesita la escala aun cuando el filtro sea inválido y el
        // mapa no contenga datos.
        AplicarEscala(modelo);

        // Un id inexistente no debe interpretarse como «Todos los diagnósticos».
        if (idDiagnostico.HasValue)
        {
            var diagnostico = modelo.Diagnosticos.FirstOrDefault(d => d.IdDiagnostico == idDiagnostico.Value);
            if (diagnostico is null)
                ModelState.AddModelError(string.Empty, "El diagnóstico indicado no existe.");
            else
                modelo.NombreDiagnosticoSeleccionado = diagnostico.Descripcion;
        }

        if (!ModelState.IsValid)
        {
            modelo.IdDiagnostico = null;
            modelo.NombreDiagnosticoSeleccionado = "Diagnóstico no válido";
            return View(modelo);
        }

        var atenciones = _db.Atenciones
            .AsNoTracking()
            .Where(a => a.Estado != Atencion.EstadoAnulada);

        if (idDiagnostico.HasValue)
            atenciones = atenciones.Where(a => a.IdDiagnostico == idDiagnostico.Value);

        // El mapa representa procedencia, no residencia. Cuando falta el origen
        // se usa la residencia y la vista informa cuántos casos dependen de ese
        // reemplazo. La agrupación se resuelve en la base.
        // Cada atención se lleva el municipio del que ES el paciente y, mientras
        // su ficha no lo diga, el de su residencia. El join contra Municipio deja
        // afuera a los que no tienen ninguno de los dos: se cuentan aparte.
        var ubicadas = atenciones.Select(a => new
        {
            // Un paciente del exterior no cae en su residencia: el mapa es de
            // Bolivia y pintarlo acá atribuiría el caso al país equivocado.
            IdMunicipio = a.Paciente!.PaisOrigen != null && !a.Paciente.PaisOrigen.EsLocal
                ? (int?)null
                : a.Paciente.IdMunicipioOrigen ?? a.Paciente.IdMunicipio
        });

        var conteoPorDepartamento = await (
            from x in ubicadas
            join m in _db.Municipios on x.IdMunicipio equals (int?)m.IdMunicipio
            group x by m.Provincia!.Departamento!.Nombre into g
            select new { NombreDepartamento = g.Key, Cantidad = g.Count() })
            .ToListAsync(ct);

        modelo.AtencionesSinUbicacion = await atenciones
            .CountAsync(a =>
                a.Paciente!.IdMunicipioOrigen == null &&
                a.Paciente.IdMunicipio == null &&
                (a.Paciente.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal), ct);

        modelo.AtencionesPorResidencia = await atenciones
            .CountAsync(a =>
                a.Paciente!.IdMunicipioOrigen == null &&
                a.Paciente.IdMunicipio != null &&
                (a.Paciente.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal), ct);

        modelo.AtencionesDelExterior = await atenciones
            .CountAsync(a =>
                a.Paciente!.PaisOrigen != null && !a.Paciente.PaisOrigen.EsLocal, ct);

        modelo.Departamentos = conteoPorDepartamento
            .OrderByDescending(d => d.Cantidad)
            .Select(d => new ConteoDepartamento(d.NombreDepartamento, d.Cantidad))
            .ToList();

        var datosMapa = conteoPorDepartamento
            .Select(item => new Dictionary<string, object>
            {
                // hc-key es la propiedad con la que Highcharts une el dato a la región.
                ["hc-key"] = GetHighchartsKey(item.NombreDepartamento),
                ["value"] = item.Cantidad,
                ["name"] = item.NombreDepartamento
            })
            .ToList();

        modelo.DatosMapaJson = System.Text.Json.JsonSerializer.Serialize(datosMapa);

        return View(modelo);
    }

    /// <summary>
    /// Carga la escala de colores con los cortes definidos en configuración.
///
    /// Cada clase incluye nombre y rango para que la representación de
    /// Highcharts coincida con la leyenda textual.
    /// </summary>
    private void AplicarEscala(MapaCalorViewModel modelo)
    {
        modelo.Niveles = _escalaMapa.Value.Niveles();

        modelo.EscalaJson = System.Text.Json.JsonSerializer.Serialize(
            modelo.Niveles.Select(nivel =>
            {
                var clase = new Dictionary<string, object>
                {
                    ["from"] = nivel.Desde,
                    ["color"] = nivel.Color,
                    ["name"] = $"{nivel.Nombre} ({nivel.Rango})"
                };

                // El último nivel no lleva «to»: Highcharts lo toma como abierto
                // hacia arriba, que es lo que corresponde a «11 o más».
                if (nivel.Hasta is not null)
                    clase["to"] = nivel.Hasta.Value;

                return clase;
            }));
    }

    /// <summary>
    /// Clave de Highcharts para cada departamento. Se comparan sin tildes, sin
    /// espacios y sin mayúsculas, así «POTOSÍ», «Potosi» y «Potosí» coinciden.
    ///
    /// Las claves corresponden al archivo <c>countries/bo/bo-all.js</c> usado por
    /// Highcharts Maps.
    /// </summary>
    private static string GetHighchartsKey(string nombreDpto)
    {
        var sinTildes = new string(nombreDpto
            .Normalize(NormalizationForm.FormD)
            .Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark
                        && !char.IsWhiteSpace(c))
            .ToArray())
            .ToLowerInvariant();

        return sinTildes switch
        {
            "lapaz" => "bo-lp",
            "santacruz" => "bo-sc",
            "cochabamba" => "bo-cb",
            "oruro" => "bo-or",
            "potosi" => "bo-po",
            "tarija" => "bo-tr",
            "chuquisaca" => "bo-cq",
            "beni" or "elbeni" => "bo-eb",
            "pando" => "bo-pa",
            _ => ""
        };
    }
}
