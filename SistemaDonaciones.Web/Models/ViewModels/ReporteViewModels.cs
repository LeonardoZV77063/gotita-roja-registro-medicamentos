using System.ComponentModel.DataAnnotations;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Models.ViewModels;

/// <summary>
/// Reporte estadístico por período con cortes demográficos, territoriales y de
/// atención.
/// </summary>
public class ReporteEstadisticoViewModel
{
    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime Desde { get; set; }
        = new DateTime(DateTime.Today.Year, 1, 1);

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime Hasta { get; set; }
        = DateTime.Today;

    [Display(Name = "Año")]
    public int? Anio { get; set; }

    [Display(Name = "Mes")]
    public int? Mes { get; set; }

    [Display(Name = "Sexo")]
    public byte? IdSexo { get; set; }

    [Display(Name = "Edad desde")]
    public int? EdadDesde { get; set; }

    [Display(Name = "Edad hasta")]
    public int? EdadHasta { get; set; }

    // La ubicación filtra por origen y usa la residencia sólo como respaldo
    // cuando la ficha todavía no tiene procedencia cargada.

    /// <summary>
    /// País de origen. Es el único filtro que alcanza a los pacientes del
    /// exterior: los territoriales no, porque no tienen municipio de origen.
    /// </summary>
    [Display(Name = "País de origen")]
    public short? IdPaisOrigen { get; set; }

    [Display(Name = "Departamento de origen")]
    public int? IdDepartamento { get; set; }

    [Display(Name = "Provincia de origen")]
    public int? IdProvincia { get; set; }

    [Display(Name = "Municipio de origen")]
    public int? IdMunicipio { get; set; }

    [Display(Name = "Diagnóstico")]
    public int? IdDiagnostico { get; set; }

    [Display(Name = "Condición")]
    public byte? IdCondicion { get; set; }


    public IEnumerable<Sexo> Sexos { get; set; }
        = Array.Empty<Sexo>();

    public IEnumerable<CondicionAtencion> Condiciones { get; set; }
        = Array.Empty<CondicionAtencion>();

    public IEnumerable<Diagnostico> Diagnosticos { get; set; }
        = Array.Empty<Diagnostico>();

    public IEnumerable<Pais> Paises { get; set; }
        = Array.Empty<Pais>();

    public IEnumerable<Departamento> Departamentos { get; set; }
        = Array.Empty<Departamento>();

    public IEnumerable<Provincia> Provincias { get; set; }
        = Array.Empty<Provincia>();

    public IEnumerable<Municipio> Municipios { get; set; }
        = Array.Empty<Municipio>();


    public int PacientesUnicos { get; set; }

    public int TotalAtenciones { get; set; }

    public decimal MontoTotal { get; set; }

    public decimal UnidadesEntregadas { get; set; }

    public decimal PromedioPorAtencion =>
        TotalAtenciones == 0
            ? 0
            : MontoTotal / TotalAtenciones;

    public IReadOnlyList<ResumenEstadisticoItem> PorSexo { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenEstadisticoItem> PorCondicion { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenEstadisticoItem> PorEdad { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenEstadisticoItem> PorDepartamento { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenEstadisticoItem> PorMunicipio { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenEstadisticoItem> PorDiagnostico { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    /// <summary>
    /// Atenciones que se contaron por la residencia del paciente porque su ficha
    /// todavía no dice de dónde es. Están dentro de las cifras por departamento
    /// y municipio; se avisan al pie para no dar por firme un dato supuesto.
    /// </summary>
    public int AtencionesPorResidencia { get; set; }

    /// <summary>
    /// Atenciones cuyo paciente no tiene ninguna ubicación cargada: quedan fuera
    /// de las cifras por departamento y municipio.
    /// </summary>
    public int AtencionesSinUbicacion { get; set; }

    /// <summary>
    /// Atenciones de pacientes de otros países. No entran en las cifras por
    /// departamento ni en el mapa —el catálogo territorial es boliviano— y se
    /// informan por país aparte.
    /// </summary>
    public int AtencionesDelExterior { get; set; }

    /// <summary>Pacientes del exterior, agrupados por país de origen.</summary>
    public IReadOnlyList<ResumenEstadisticoItem> PorPaisOrigen { get; set; }
        = Array.Empty<ResumenEstadisticoItem>();

    public IReadOnlyList<ResumenMensualEstadistico> EvolucionMensual { get; set; }
        = Array.Empty<ResumenMensualEstadistico>();

    public bool HayDatos => TotalAtenciones > 0;

   
    public IReadOnlyList<FilaReporteEstadistico> Filas { get; set; }
        = Array.Empty<FilaReporteEstadistico>();

    public FilaReporteEstadistico? TotalGeneral =>
        Filas.FirstOrDefault(f =>
            string.IsNullOrEmpty(f.Sexo) &&
            string.IsNullOrEmpty(f.Condicion) &&
            string.IsNullOrEmpty(f.GrupoEtario));

    public IEnumerable<FilaReporteEstadistico> PorGrupoEtario =>
        Filas.Where(f =>
            string.IsNullOrEmpty(f.Sexo) &&
            string.IsNullOrEmpty(f.Condicion) &&
            !string.IsNullOrEmpty(f.GrupoEtario));

    public IEnumerable<FilaReporteEstadistico> PorSexoYCondicion =>
        Filas.Where(f =>
            !string.IsNullOrEmpty(f.Sexo) &&
            !string.IsNullOrEmpty(f.Condicion));
}
public class ResumenEstadisticoItem
{
    public string Nombre { get; set; } = string.Empty;

    public int Pacientes { get; set; }

    public int Atenciones { get; set; }

    public decimal Monto { get; set; }
}

public class ResumenMensualEstadistico
{
    public int Anio { get; set; }

    public int Mes { get; set; }

    public int Pacientes { get; set; }

    public int Atenciones { get; set; }

    public decimal Monto { get; set; }

    public string Periodo =>
        new DateTime(Anio, Mes, 1)
            .ToString("MMM yyyy");
}

/// <summary>Medicamentos más entregados en un período.</summary>
public class ReporteMedicamentosViewModel
{
    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime Desde { get; set; } = new DateTime(DateTime.Today.Year, 1, 1);

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime Hasta { get; set; } = DateTime.Today;

    public IReadOnlyList<FilaMedicamentoEntregado> Filas { get; set; }
        = Array.Empty<FilaMedicamentoEntregado>();

    public decimal MontoTotal => Filas.Sum(f => f.MontoDonado);
    public int TotalEntregas => Filas.Sum(f => f.Entregas);
}

public class FilaMedicamentoEntregado
{
    public int IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string Medicamento { get; set; } = string.Empty;

    [Display(Name = "Entregas")]
    public int Entregas { get; set; }

    [Display(Name = "Unidades")]
    public decimal Unidades { get; set; }

    [Display(Name = "Monto donado (Bs)")]
    public decimal MontoDonado { get; set; }

    [Display(Name = "Pacientes distintos")]
    public int PacientesDistintos { get; set; }
}

/// <summary>
/// Constancia de una exportación. El sistema no envía el archivo; registra el
/// período, destino, momento y usuario declarados.
/// </summary>
public class ExportacionViewModel
{
    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime Desde { get; set; } = new DateTime(DateTime.Today.Year, 1, 1);

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime Hasta { get; set; } = DateTime.Today;

    /// <summary>
    /// El destino es obligatorio para que la constancia identifique dónde se
    /// envió la copia.
    /// </summary>
    [Required(ErrorMessage = "Indique a dónde se envía la copia (destino).")]
    [StringLength(120)]
    [Display(Name = "Destino")]
    public string? Destino { get; set; }

    [StringLength(300)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    public IReadOnlyList<RespaldoExportacion> Historial { get; set; }
        = Array.Empty<RespaldoExportacion>();
}

/// <summary>Pantalla de inicio: el estado del mes de un vistazo.</summary>
public class TableroViewModel
{
    public int AtencionesDelMes { get; set; }
    public int AtencionesDelAnio { get; set; }
    public decimal MontoDelMes { get; set; }
    public decimal MontoDelAnio { get; set; }
    public int PacientesRegistrados { get; set; }
    public int PacientesNuevosDelMes { get; set; }
    public decimal ValorInventario { get; set; }
    public int MedicamentosConStock { get; set; }

    public IReadOnlyList<Atencion> UltimasAtenciones { get; set; }
        = Array.Empty<Atencion>();

    public IReadOnlyList<Lote> LotesPorVencer { get; set; }
        = Array.Empty<Lote>();

    public string NombreMes =>
        System.Globalization.CultureInfo
            .GetCultureInfo("es-BO")
            .DateTimeFormat
            .GetMonthName(DateTime.Today.Month);
}

/// <summary>Datos del tablero gráfico de porcentajes.</summary>
public class DashboardPorcentajesViewModel
{
    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime Desde { get; set; } = new DateTime(DateTime.Today.Year, 1, 1);

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime Hasta { get; set; } = DateTime.Today;

    public decimal MontoTotalAhorrado { get; set; }

    /// <summary>
    /// Atenciones que los gráficos de departamento y municipio ubicaron por
    /// donde vive el paciente, porque su ficha todavía no dice de dónde es. Es
    /// el mismo aviso que llevan el listado de reportes y el mapa: la cifra se
    /// presenta igual de firme en las tres pantallas o en ninguna.
    /// </summary>
    public int AtencionesPorResidencia { get; set; }

    /// <summary>Atenciones de pacientes de otros países: no entran en el gráfico por departamento.</summary>
    public int AtencionesDelExterior { get; set; }

    public List<string> SexoLabels { get; set; } = new();
    public List<int> SexoValues { get; set; } = new();

    public List<string> EdadLabels { get; set; } = new();
    public List<int> EdadValues { get; set; } = new();

    public List<string> CondicionLabels { get; set; } = new();
    public List<int> CondicionValues { get; set; } = new();

    public List<string> DiagnosticoLabels { get; set; } = new();
    public List<int> DiagnosticoValues { get; set; } = new();

    public List<string> DepartamentoLabels { get; set; } = new();
    public List<int> DepartamentoValues { get; set; } = new();

    public List<string> MunicipioLabels { get; set; } = new();
    public List<int> MunicipioValues { get; set; } = new();

    public List<string> MesLabels { get; set; } = new();
    public List<int> MesValues { get; set; } = new();

    public List<string> TopMedicamentosNombres { get; set; } = new();
    public List<decimal> TopMedicamentosCantidades { get; set; } = new();
}

public class MapaCalorViewModel
{
    [Display(Name = "Diagnóstico")]
    public int? IdDiagnostico { get; set; }
    
    public IEnumerable<Diagnostico> Diagnosticos { get; set; } = Array.Empty<Diagnostico>();
    
    /// <summary>Datos de Highcharts serializados con claves de región y valores.</summary>
    public string DatosMapaJson { get; set; } = "[]";
    
    public string NombreDiagnosticoSeleccionado { get; set; } = "Todos los diagnósticos";

    /// <summary>Atenciones por departamento, también en tabla (lectores de pantalla, celular).</summary>
    public IReadOnlyList<ConteoDepartamento> Departamentos { get; set; } = Array.Empty<ConteoDepartamento>();

    /// <summary>
    /// Atenciones cuyo paciente no tiene ninguna ubicación cargada: no pueden
    /// ubicarse en el mapa y se informan aparte para que el total no parezca
    /// menor.
    /// </summary>
    public int AtencionesSinUbicacion { get; set; }

    /// <summary>
    /// Atenciones de pacientes de otros países. El mapa es de Bolivia, así que
    /// no se pintan en ninguna región y se informan aparte.
    /// </summary>
    public int AtencionesDelExterior { get; set; }

    /// <summary>
    /// Atenciones que el mapa coloreó según dónde vive el paciente porque su
    /// ficha todavía no dice de dónde es. Están incluidas en el mapa; se avisan
    /// para que nadie lea como incidencia lo que puede ser sólo cercanía al
    /// centro de salud.
    /// </summary>
    public int AtencionesPorResidencia { get; set; }

    /// <summary>Los cuatro niveles, en orden, para la leyenda y para la tabla.</summary>
    public IReadOnlyList<NivelMapa> Niveles { get; set; } = Array.Empty<NivelMapa>();

    /// <summary>Las dataClasses de Highcharts, ya serializadas.</summary>
    public string EscalaJson { get; set; } = "[]";

    /// <summary>Gris de los departamentos sin ninguna atención registrada.</summary>
    public string ColorSinDatos => "#dee2e6";

    /// <summary>
    /// El nivel que le toca a una cantidad. La tabla lo escribe con palabras
    /// porque una escala que sólo se distingue por color deja afuera a quien no
    /// distingue el rojo del verde.
    /// </summary>
    public string NivelDe(int atenciones)
    {
        if (atenciones <= 0) return "Sin registros";

        foreach (var nivel in Niveles)
            if (nivel.Hasta is null || atenciones <= nivel.Hasta)
                return nivel.Nombre;

        return "Sin registros";
    }

    /// <summary>
    /// Con muy pocas atenciones la escala no separa nada y el mapa se ve de un
    /// solo color. No es un error: con cinco atenciones en el departamento más
    /// cargado, pintarlo de rojo diría que ahí la demanda es extrema, y no lo es.
    ///
    /// Con un solo departamento con datos no hay nada que contrastar, así que
    /// no se avisa: el aviso diría que la escala falló cuando lo único que pasa
    /// es que hay una sola región cargada.
    /// </summary>
    public bool EscalaSinContraste =>
        HayDatos && Departamentos.Count > 1
        && Departamentos.Select(d => NivelDe(d.Atenciones)).Distinct().Count() == 1;

    public int TotalEnMapa => Departamentos.Sum(d => d.Atenciones);

    public bool HayDatos => TotalEnMapa > 0;
}

public record ConteoDepartamento(string Departamento, int Atenciones);
