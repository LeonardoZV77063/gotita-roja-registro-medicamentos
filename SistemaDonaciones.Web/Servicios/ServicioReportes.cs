using System.Data;
using System.Globalization;
using System.Text;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>
/// Estadísticas, tableros y exportaciones de atenciones.
/// </summary>
public class ServicioReportes
{
    private readonly AppDbContext _db;

    public ServicioReportes(AppDbContext db) => _db = db;

    /// <summary>
    /// Distribución por sexo, condición y grupo etario, vía sp_ReporteEstadistico.
    /// El procedimiento usa GROUPING SETS para traer los cortes y los totales en
    /// una sola pasada, en lugar de repetir la consulta una vez por dimensión.
    /// </summary>
    public async Task<List<FilaReporteEstadistico>> EstadisticoAsync(
        DateTime desde, DateTime hasta, CancellationToken ct = default)
    {
        var pDesde = new SqlParameter("@Desde", SqlDbType.Date) { Value = desde.Date };
        var pHasta = new SqlParameter("@Hasta", SqlDbType.Date) { Value = hasta.Date };

        return await _db.ReporteEstadistico
            .FromSqlRaw("EXEC sp_ReporteEstadistico @Desde, @Hasta", pDesde, pHasta)
            .ToListAsync(ct);
    }
    public async Task<ReporteEstadisticoViewModel> EstadisticoAvanzadoAsync(
    ReporteEstadisticoViewModel filtro,
    CancellationToken ct = default)
    {
        var consulta = _db.Atenciones
            .AsNoTracking()
            .Where(a => a.Estado == Atencion.EstadoRegistrada);

        consulta = consulta.Where(a =>
            a.FechaAtencion >= filtro.Desde.Date &&
            a.FechaAtencion <= filtro.Hasta.Date);

        if (filtro.Anio.HasValue)
        {
            consulta = consulta.Where(a =>
                a.FechaAtencion.Year == filtro.Anio.Value);
        }

        if (filtro.Mes.HasValue)
        {
            consulta = consulta.Where(a =>
                a.FechaAtencion.Month == filtro.Mes.Value);
        }

        if (filtro.IdSexo.HasValue)
        {
            consulta = consulta.Where(a =>
                a.Paciente!.IdSexo == filtro.IdSexo.Value);
        }

        if (filtro.EdadDesde.HasValue)
        {
            var edadDesde = filtro.EdadDesde.Value;

            consulta = consulta.Where(a =>
                EF.Functions.DateDiffYear(
                    a.Paciente!.FechaNacimiento,
                    a.FechaAtencion)
                -
                (
                    a.Paciente.FechaNacimiento.AddYears(
                        EF.Functions.DateDiffYear(
                            a.Paciente.FechaNacimiento,
                            a.FechaAtencion))
                    > a.FechaAtencion
                        ? 1
                        : 0
                )
                >= edadDesde);
        }

        if (filtro.EdadHasta.HasValue)
        {
            var edadHasta = filtro.EdadHasta.Value;

            consulta = consulta.Where(a =>
                EF.Functions.DateDiffYear(
                    a.Paciente!.FechaNacimiento,
                    a.FechaAtencion)
                -
                (
                    a.Paciente.FechaNacimiento.AddYears(    
                        EF.Functions.DateDiffYear(
                            a.Paciente.FechaNacimiento,
                            a.FechaAtencion))
                    > a.FechaAtencion
                        ? 1
                        : 0
                )
                <= edadHasta);
        }
        // Se filtra por la procedencia del paciente, no por su residencia.
        // Mientras el origen esté vacío se usa la residencia y las pantallas
        // informan cuántas atenciones se contaron así.
        // El municipio que cuenta es el de origen y, mientras esté vacío, el de
        // residencia: ISNULL(IdMunicipioOrigen, IdMunicipio). Provincia y
        // departamento se resuelven con un EXISTS contra Municipio en vez de
        // encadenar las dos rutas de navegación dentro de un condicional, para
        // mantener una traducción estable a SQL.
        // El país filtra por sí solo porque los pacientes del exterior no tienen
        // departamento ni municipio de origen en el catálogo boliviano.
        if (filtro.IdPaisOrigen.HasValue)
        {
            consulta = consulta.Where(a =>
                a.Paciente!.IdPaisOrigen == filtro.IdPaisOrigen.Value);
        }

        // Los filtros territoriales dejan fuera a los pacientes del exterior:
        // el catálogo es boliviano, y sin esta condición un paciente venezolano
        // que vive en Montero pasaría el filtro «departamento de origen = Santa
        // Cruz» aunque las tablas por departamento ya no lo cuenten ahí.
        if (filtro.IdMunicipio.HasValue)
        {
            consulta = consulta.Where(a =>
                (a.Paciente!.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal)
                && (a.Paciente.IdMunicipioOrigen ?? a.Paciente.IdMunicipio)
                    == filtro.IdMunicipio.Value);
        }
        else if (filtro.IdProvincia.HasValue)
        {
            consulta = consulta.Where(a =>
                (a.Paciente!.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal)
                && _db.Municipios.Any(m =>
                    m.IdMunicipio == (a.Paciente.IdMunicipioOrigen ?? a.Paciente.IdMunicipio)
                    && m.IdProvincia == filtro.IdProvincia.Value));
        }
        else if (filtro.IdDepartamento.HasValue)
        {
            consulta = consulta.Where(a =>
                (a.Paciente!.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal)
                && _db.Municipios.Any(m =>
                    m.IdMunicipio == (a.Paciente.IdMunicipioOrigen ?? a.Paciente.IdMunicipio)
                    && m.Provincia!.IdDepartamento == filtro.IdDepartamento.Value));
        }

        if (filtro.IdDiagnostico.HasValue)
        {
            consulta = consulta.Where(a =>
                a.IdDiagnostico == filtro.IdDiagnostico.Value);
        }

        if (filtro.IdCondicion.HasValue)
        {
            consulta = consulta.Where(a =>
                a.IdCondicion == filtro.IdCondicion.Value);
        }

        filtro.TotalAtenciones =
            await consulta.CountAsync(ct);

        filtro.PacientesUnicos =
            await consulta
                .Select(a => a.IdPaciente)
                .Distinct()
                .CountAsync(ct);

        var idsAtenciones = consulta.Select(a => a.IdAtencion);

        var detalles = _db.AtencionDetalles
            .AsNoTracking()
            .Where(d => idsAtenciones.Contains(d.IdAtencion));

        filtro.MontoTotal =
            await detalles.SumAsync(
                d => (decimal?)d.MontoTotal, ct) ?? 0m;

        filtro.UnidadesEntregadas =
            await detalles.SumAsync(
                d => (decimal?)d.Cantidad, ct) ?? 0m;

        filtro.PorSexo = await consulta
            .GroupBy(a => new
            {
                a.Paciente!.IdSexo,
                Nombre = a.Paciente.Sexo!.Descripcion
            })
            .Select(g => new ResumenEstadisticoItem
            {
                Nombre = g.Key.Nombre,
                Pacientes = g.Select(x => x.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);

        filtro.PorCondicion = await consulta
            .GroupBy(a => new
            {
                a.IdCondicion,
                Nombre = a.Condicion!.Descripcion
            })
            .Select(g => new ResumenEstadisticoItem
            {
                Nombre = g.Key.Nombre,
                Pacientes = g.Select(x => x.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);
        // Edad que tenía el paciente al momento de la atención.

        var edadesAtenciones = await consulta
            .Select(a => new
            {
                a.IdPaciente,
                a.IdAtencion,

                Edad =
                    EF.Functions.DateDiffYear(
                        a.Paciente!.FechaNacimiento,
                        a.FechaAtencion)
                    -
                    (
                        a.Paciente.FechaNacimiento.AddYears(
                            EF.Functions.DateDiffYear(
                                a.Paciente.FechaNacimiento,
                                a.FechaAtencion))
                        > a.FechaAtencion
                            ? 1
                            : 0
                    )
            })
            .ToListAsync(ct);

        filtro.PorEdad = edadesAtenciones
            .GroupBy(x =>
                x.Edad <= 5 ? "0 - 5 años" :
                x.Edad <= 12 ? "6 - 12 años" :
                x.Edad <= 17 ? "13 - 17 años" :
                x.Edad <= 29 ? "18 - 29 años" :
                x.Edad <= 44 ? "30 - 44 años" :
                x.Edad <= 59 ? "45 - 59 años" :
                               "60 años o más")
            .Select(g => new ResumenEstadisticoItem
            {
                Nombre = g.Key,

                Pacientes = g
                    .Select(x => x.IdPaciente)
                    .Distinct()
                    .Count(),

                Atenciones = g.Count()
            })
            .OrderBy(x =>
                x.Nombre.StartsWith("0 -") ? 1 :
                x.Nombre.StartsWith("6 -") ? 2 :
                x.Nombre.StartsWith("13 -") ? 3 :
                x.Nombre.StartsWith("18 -") ? 4 :
                x.Nombre.StartsWith("30 -") ? 5 :
                x.Nombre.StartsWith("45 -") ? 6 : 7)
            .ToList();

        // Cada atención se lleva el municipio del que ES el paciente; si su ficha
        // todavía no lo dice, el de su residencia. El join contra Municipio deja
        // afuera a los que no tienen ninguno de los dos, que se cuentan aparte.
        //
        // Un paciente del exterior no cae en la residencia: el catálogo
        // territorial es boliviano, y contarlo por donde vive lo pintaría en el
        // mapa de Bolivia como si fuera de acá.
        var ubicadas = consulta.Select(a => new
        {
            a.IdPaciente,
            // El país manda sobre el municipio, igual que Paciente.
            // MunicipioProcedencia: si alguna ficha quedara con país extranjero
            // y municipio boliviano a la vez, las dos cifras tienen que contarla
            // en el mismo lado o el desglose supera al total.
            IdMunicipio = a.Paciente!.PaisOrigen != null && !a.Paciente.PaisOrigen.EsLocal
                ? (int?)null
                : a.Paciente.IdMunicipioOrigen ?? a.Paciente.IdMunicipio
        });

        filtro.PorDepartamento = await (
            from x in ubicadas
            join m in _db.Municipios on x.IdMunicipio equals (int?)m.IdMunicipio
            group x by m.Provincia!.Departamento!.Nombre into g
            select new ResumenEstadisticoItem
            {
                Nombre = g.Key,
                Pacientes = g.Select(y => y.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);

        filtro.PorMunicipio = await (
            from x in ubicadas
            join m in _db.Municipios on x.IdMunicipio equals (int?)m.IdMunicipio
            group x by m.Nombre into g
            select new ResumenEstadisticoItem
            {
                Nombre = g.Key,
                Pacientes = g.Select(y => y.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);

        // Cuántas de esas atenciones se contaron por la residencia porque la
        // ficha todavía no dice de dónde es el paciente, y cuántas no se
        // pudieron ubicar en ningún lado. Se muestran al pie de las tablas: sin
        // este aviso, las cifras por departamento parecen más firmes de lo que
        // son.
        filtro.AtencionesPorResidencia = await consulta
            .CountAsync(a =>
                a.Paciente!.IdMunicipioOrigen == null &&
                a.Paciente.IdMunicipio != null &&
                (a.Paciente.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal), ct);

        filtro.AtencionesSinUbicacion = await consulta
            .CountAsync(a =>
                a.Paciente!.IdMunicipioOrigen == null &&
                a.Paciente.IdMunicipio == null &&
                (a.Paciente.PaisOrigen == null || a.Paciente.PaisOrigen.EsLocal), ct);

        // Los tres contadores son excluyentes entre sí: quien es de otro país
        // no está «contado por residencia» ni «sin ubicación», está contado en
        // su país.
        filtro.AtencionesDelExterior = await consulta
            .CountAsync(a =>
                a.Paciente!.PaisOrigen != null && !a.Paciente.PaisOrigen.EsLocal, ct);

        filtro.PorPaisOrigen = await consulta
            .Where(a => a.Paciente!.PaisOrigen != null && !a.Paciente.PaisOrigen.EsLocal)
            .GroupBy(a => a.Paciente!.PaisOrigen!.Nombre)
            .Select(g => new ResumenEstadisticoItem
            {
                Nombre = g.Key,
                Pacientes = g.Select(x => x.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);

        filtro.PorDiagnostico = await consulta
            .GroupBy(a => a.Diagnostico!.Descripcion)
            .Select(g => new ResumenEstadisticoItem
            {
                Nombre = g.Key,
                Pacientes = g.Select(x => x.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderByDescending(x => x.Pacientes)
            .ToListAsync(ct);

        filtro.EvolucionMensual = await consulta
            .GroupBy(a => new
            {
                a.FechaAtencion.Year,
                a.FechaAtencion.Month
            })
            .Select(g => new ResumenMensualEstadistico
            {
                Anio = g.Key.Year,
                Mes = g.Key.Month,
                Pacientes = g.Select(x => x.IdPaciente).Distinct().Count(),
                Atenciones = g.Count()
            })
            .OrderBy(x => x.Anio)
            .ThenBy(x => x.Mes)
            .ToListAsync(ct);

        return filtro;
    }

    /// <summary>
    /// Medicamentos más entregados en el período.
    ///
    /// Se resuelve en dos consultas en lugar de una: contar pacientes distintos
    /// dentro de una agrupación (COUNT DISTINCT sobre otra tabla) no siempre se
    /// traduce de forma fiable a SQL; dos consultas explícitas evitan una
    /// evaluación accidental en memoria.
    /// </summary>
    public async Task<List<FilaMedicamentoEntregado>> MedicamentosAsync(
        DateTime desde, DateTime hasta, CancellationToken ct = default)
    {
        var baseConsulta = _db.AtencionDetalles
            .AsNoTracking()
            .Where(d => d.Atencion!.Estado == Atencion.EstadoRegistrada
                        && d.Atencion.FechaAtencion >= desde.Date
                        && d.Atencion.FechaAtencion <= hasta.Date);

        var agregados = await baseConsulta
            .GroupBy(d => new { d.IdMedicamento, d.Medicamento!.Nombre })
            .Select(g => new
            {
                g.Key.IdMedicamento,
                g.Key.Nombre,
                Entregas = g.Count(),
                Unidades = g.Sum(d => d.Cantidad),
                MontoDonado = g.Sum(d => d.MontoTotal)
            })
            .ToListAsync(ct);

        var pacientesPorMedicamento = (await baseConsulta
                .Select(d => new { d.IdMedicamento, d.Atencion!.IdPaciente })
                .Distinct()
                .ToListAsync(ct))
            .GroupBy(x => x.IdMedicamento)
            .ToDictionary(g => g.Key, g => g.Count());

        return agregados
            .Select(a => new FilaMedicamentoEntregado
            {
                IdMedicamento = a.IdMedicamento,
                Medicamento = a.Nombre,
                Entregas = a.Entregas,
                Unidades = a.Unidades,
                MontoDonado = a.MontoDonado,
                PacientesDistintos = pacientesPorMedicamento.GetValueOrDefault(a.IdMedicamento)
            })
            .OrderByDescending(f => f.MontoDonado)
            .ToList();
    }

    /// <summary>Datos del tablero de inicio.</summary>
    public async Task<TableroViewModel> TableroAsync(CancellationToken ct = default)
    {
        var hoy = DateTime.Today;
        var inicioMes = new DateTime(hoy.Year, hoy.Month, 1);
        var inicioAnio = new DateTime(hoy.Year, 1, 1);

        var registradas = _db.Atenciones
            .AsNoTracking()
            .Where(a => a.Estado == Atencion.EstadoRegistrada);

        var vm = new TableroViewModel
        {
            AtencionesDelMes = await registradas
                .CountAsync(a => a.FechaAtencion >= inicioMes, ct),

            AtencionesDelAnio = await registradas
                .CountAsync(a => a.FechaAtencion >= inicioAnio, ct),

            PacientesRegistrados = await _db.Pacientes
                .AsNoTracking().CountAsync(p => p.Activo, ct),

            PacientesNuevosDelMes = await _db.Pacientes
                .AsNoTracking().CountAsync(p => p.FechaRegistro >= inicioMes, ct)
        };

        vm.MontoDelMes = await _db.AtencionDetalles
            .AsNoTracking()
            .Where(d => d.Atencion!.Estado == Atencion.EstadoRegistrada
                        && d.Atencion.FechaAtencion >= inicioMes)
            .SumAsync(d => (decimal?)d.MontoTotal, ct) ?? 0m;

        vm.MontoDelAnio = await _db.AtencionDetalles
            .AsNoTracking()
            .Where(d => d.Atencion!.Estado == Atencion.EstadoRegistrada
                        && d.Atencion.FechaAtencion >= inicioAnio)
            .SumAsync(d => (decimal?)d.MontoTotal, ct) ?? 0m;

        // Los ingresos anulados no forman parte del inventario ni de su valor.
        vm.ValorInventario = await _db.Lotes
            .AsNoTracking()
            .Where(l => l.CantidadDisponible > 0 && !l.Anulado)
            .SumAsync(l => (decimal?)(l.CantidadDisponible * l.CostoUnitario), ct) ?? 0m;

        vm.MedicamentosConStock = await _db.Lotes
            .AsNoTracking()
            .Where(l => l.CantidadDisponible > 0 && !l.Anulado)
            .Select(l => l.IdMedicamento)
            .Distinct()
            .CountAsync(ct);

        vm.UltimasAtenciones = await registradas
            .Include(a => a.Paciente)
            .Include(a => a.Detalles).ThenInclude(d => d.Medicamento)
            .OrderByDescending(a => a.FechaAtencion)
            .ThenByDescending(a => a.IdAtencion)
            .Take(8)
            .ToListAsync(ct);

        var limite = hoy.AddDays(90);
        vm.LotesPorVencer = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.Medicamento)
            .Where(l => l.CantidadDisponible > 0
                        && !l.Anulado
                        && l.FechaVencimiento != null
                        && l.FechaVencimiento <= limite)
            .OrderBy(l => l.FechaVencimiento)
            .Take(10)
            .ToListAsync(ct);

        return vm;
    }

    /// <summary>
    /// Exporta las atenciones de un período a CSV. Se elige CSV en lugar de un
    /// .xlsx generado por biblioteca porque Excel lo abre igual, no agrega una
    /// dependencia más al proyecto y es un formato que seguirá siendo legible
    /// dentro de diez años, que es el horizonte de un archivo de auditoría.
    /// </summary>
    public async Task<byte[]> ExportarCsvAsync(
        DateTime desde, DateTime hasta, CancellationToken ct = default)
    {
        var filas = await _db.AtencionDetalles
            .AsNoTracking()
            .Include(d => d.Medicamento)
            .Include(d => d.Atencion).ThenInclude(a => a!.Paciente).ThenInclude(p => p!.Sexo)
            .Include(d => d.Atencion).ThenInclude(a => a!.Paciente).ThenInclude(p => p!.Municipio)
                .ThenInclude(m => m!.Provincia).ThenInclude(pr => pr!.Departamento)
            .Include(d => d.Atencion).ThenInclude(a => a!.Paciente).ThenInclude(p => p!.MunicipioOrigen)
                .ThenInclude(m => m!.Provincia).ThenInclude(pr => pr!.Departamento)
            .Include(d => d.Atencion).ThenInclude(a => a!.Paciente).ThenInclude(p => p!.PaisOrigen)
            .Include(d => d.Atencion).ThenInclude(a => a!.Diagnostico)
            .Include(d => d.Atencion).ThenInclude(a => a!.Condicion)
            .Include(d => d.Atencion).ThenInclude(a => a!.Establecimiento)
            .Where(d => d.Atencion!.FechaAtencion >= desde.Date
                        && d.Atencion.FechaAtencion <= hasta.Date)
            .OrderBy(d => d.Atencion!.FechaAtencion)
            .ThenBy(d => d.IdAtencion)
            .ToListAsync(ct);

        var cultura = CultureInfo.GetCultureInfo("es-BO");
        var sb = new StringBuilder();

        // El CSV mantiene origen y residencia en columnas distintas, sin
        // completar una con la otra. Así se distinguen las fichas sin procedencia
        // cargada; para pacientes del exterior, el país puede ser el único dato.
        sb.AppendLine(string.Join(';', new[]
        {
            "Fecha", "N Formulario", "Carnet", "Paciente", "Edad", "Sexo",
            "Pais de origen",
            "Departamento de origen", "Provincia de origen", "Municipio de origen",
            "Departamento de residencia", "Provincia de residencia", "Municipio de residencia",
            "Diagnostico", "Condicion", "Establecimiento", "Medicamento",
            "Cantidad", "Monto Bs", "Origen del costo", "Estado"
        }));

        foreach (var d in filas)
        {
            var a = d.Atencion!;
            var p = a.Paciente!;

            sb.AppendLine(string.Join(';', new[]
            {
                a.FechaAtencion.ToString("dd/MM/yyyy"),
                Escapar(a.NumeroFormulario),
                Escapar(p.DocumentoCompleto),
                Escapar(p.NombreCompleto),
                // Edad que tenía al ser atendido, como en las estadísticas.
                // Paciente.Edad es la de hoy: en un respaldo de años anteriores
                // cada fila quedaba con una edad que no era la de la entrega.
                EdadA(p.FechaNacimiento, a.FechaAtencion).ToString(cultura),
                Escapar(p.Sexo?.Descripcion),
                Escapar(p.PaisOrigen?.Nombre),
                Escapar(p.MunicipioOrigen?.Provincia?.Departamento?.Nombre),
                Escapar(p.MunicipioOrigen?.Provincia?.Nombre),
                Escapar(p.MunicipioOrigen?.Nombre),
                Escapar(p.Municipio?.Provincia?.Departamento?.Nombre),
                Escapar(p.Municipio?.Provincia?.Nombre),
                Escapar(p.Municipio?.Nombre),
                Escapar(a.Diagnostico?.Descripcion),
                Escapar(a.Condicion?.Descripcion),
                Escapar(a.Establecimiento?.Nombre),
                Escapar(d.Medicamento?.Nombre),
                d.Cantidad.ToString("0.##", cultura),
                d.MontoTotal.ToString("0.00", cultura),
                d.OrigenCosto,
                a.Estado
            }));
        }

        // BOM UTF-8: sin él Excel en Windows abre el archivo en ANSI y rompe
        // las tildes y las eñes.
        return Encoding.UTF8.GetPreamble()
            .Concat(Encoding.UTF8.GetBytes(sb.ToString()))
            .ToArray();
    }

    /// <summary>Deja constancia de una exportación realizada.</summary>
    public async Task<RespaldoExportacion> RegistrarExportacionAsync(
        DateTime desde,
        DateTime hasta,
        string? destino,
        string? observaciones,
        int idUsuario,
        CancellationToken ct = default)
    {
        var cantidad = await _db.Atenciones
            .CountAsync(a => a.FechaAtencion >= desde.Date
                             && a.FechaAtencion <= hasta.Date
                             && a.Estado == Atencion.EstadoRegistrada, ct);

        var registro = new RespaldoExportacion
        {
            PeriodoDesde = desde.Date,
            PeriodoHasta = hasta.Date,
            CantidadAtenciones = cantidad,
            Destino = string.IsNullOrWhiteSpace(destino) ? null : destino.Trim(),
            Observaciones = string.IsNullOrWhiteSpace(observaciones)
                ? null : observaciones.Trim(),
            IdUsuario = idUsuario,
            FechaGeneracion = DateTime.Now
        };

        _db.Exportaciones.Add(registro);
        await _db.SaveChangesAsync(ct);

        return registro;
    }

    public Task<List<RespaldoExportacion>> HistorialExportacionesAsync(
        CancellationToken ct = default) =>
        _db.Exportaciones
            .AsNoTracking()
            .Include(e => e.Usuario)
            .OrderByDescending(e => e.FechaGeneracion)
            .Take(50)
            .ToListAsync(ct);

    /// <summary>Edad cumplida a una fecha dada.</summary>
    private static int EdadA(DateTime nacimiento, DateTime fecha)
    {
        var edad = fecha.Year - nacimiento.Year;
        if (nacimiento.Date > fecha.Date.AddYears(-edad)) edad--;
        return Math.Max(0, edad);
    }

    /// <summary>
    /// Escapa un campo para CSV con separador punto y coma.
    ///
    /// Un texto que empieza con =, +, - o @ Excel lo interpreta como fórmula
    /// al abrir el archivo (inyección de fórmulas en CSV). Nombres, diagnósticos
    /// y establecimientos los escriben las usuarias, así que esos campos se
    /// anteponen con un apóstrofo, que Excel muestra como texto.
    /// </summary>
    private static string Escapar(string? valor)
    {
        if (string.IsNullOrEmpty(valor)) return string.Empty;

        if (valor[0] is '=' or '+' or '-' or '@' or '\t' or '\r')
            valor = "'" + valor;

        var necesitaComillas = valor.Contains(';') || valor.Contains('"')
                               || valor.Contains('\n') || valor.Contains('\r');

        return necesitaComillas
            ? '"' + valor.Replace("\"", "\"\"") + '"'
            : valor;
    }
}
