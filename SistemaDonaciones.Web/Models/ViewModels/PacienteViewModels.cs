using System.ComponentModel.DataAnnotations;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Models.ViewModels;

/// <summary>
/// Formulario de alta y edición de paciente. En la edición sólo se pide un
/// carnet cuando se reemplaza el vigente.
/// </summary>
public class PacienteFormViewModel
{
    /// <summary>
    /// Letras del español (con ü), espacios, apóstrofo y guion, con al menos una
    /// letra. El apóstrofo cubre apellidos aimaras y quechuas escritos con
    /// glotal (Ch'uqi, Q'ispi) y el guion los apellidos compuestos. Es la misma
    /// regla que aplica el filtro de teclado de site.js (data-filtro="letras").
    /// </summary>
    public const string PatronNombre =
        @"^(?=.*[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ])[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s'\-]+$";

    public const string MensajeNombre =
        "Solo se permiten letras, espacios, apóstrofo (') o guion (-).";

    public int IdPaciente { get; set; }

    [Required(ErrorMessage = "El número de carnet es obligatorio.")]
    [StringLength(20)]
    [RegularExpression(@"^[0-9]+$", ErrorMessage = "El carnet solo debe contener números.")]
    [Display(Name = "Carnet de identidad")]
    public string NumeroDocumento { get; set; } = string.Empty;

    [StringLength(5)]
    [RegularExpression(@"^[0-9A-Za-z]+$",
        ErrorMessage = "El complemento solo admite letras y números, sin espacios.")]
    [Display(Name = "Complemento")]
    public string? ComplementoDoc { get; set; }

    [StringLength(5)]
    [RegularExpression(@"^[A-Za-z]+$",
        ErrorMessage = "La extensión solo admite letras (LP, SC, CB…).")]
    [Display(Name = "Extensión")]
    public string? ExtensionDoc { get; set; }

    [Required(ErrorMessage = "Los nombres son obligatorios.")]
    [StringLength(80)]
    [RegularExpression(PatronNombre, ErrorMessage = MensajeNombre)]
    [Display(Name = "Nombres")]
    public string Nombres { get; set; } = string.Empty;

    [Required(ErrorMessage = "El apellido paterno es obligatorio.")]
    [StringLength(60)]
    [RegularExpression(PatronNombre, ErrorMessage = MensajeNombre)]
    [Display(Name = "Apellido paterno")]
    public string ApellidoPaterno { get; set; } = string.Empty;

    [StringLength(60)]
    [RegularExpression(PatronNombre, ErrorMessage = MensajeNombre)]
    [Display(Name = "Apellido materno")]
    public string? ApellidoMaterno { get; set; }

    [Required(ErrorMessage = "La fecha de nacimiento es obligatoria.")]
    [DataType(DataType.Date)]
    [Display(Name = "Fecha de nacimiento")]
    public DateTime? FechaNacimiento { get; set; }

    [Range(1, 255, ErrorMessage = "Seleccione el sexo.")]
    [Display(Name = "Sexo")]
    public byte IdSexo { get; set; }

    [StringLength(20)]
    [RegularExpression(@"^[\d\s\+\-]+$", ErrorMessage = "Ingrese un número telefónico válido.")]
    [Display(Name = "Teléfono")]
    public string? Telefono { get; set; }

    // Residencia
    // Departamento y provincia no se guardan: sólo sirven para ir filtrando los
    // municipios en pantalla. Lo que queda en la ficha es el municipio.

    [Display(Name = "Departamento")]
    public int? IdDepartamento { get; set; }

    [Display(Name = "Provincia")]
    public int? IdProvincia { get; set; }

    [Display(Name = "Municipio")]
    public int? IdMunicipio { get; set; }

    [StringLength(120)]
    [Display(Name = "Zona o barrio")]
    public string? Zona { get; set; }

    [StringLength(120)]
    [Display(Name = "Calle o avenida")]
    public string? Calle { get; set; }

    [StringLength(20)]
    [Display(Name = "N° de domicilio")]
    public string? NumeroDomicilio { get; set; }

    [StringLength(250)]
    [Display(Name = "Referencia")]
    public string? Direccion { get; set; }

    // Origen. Alimenta el mapa y las estadísticas y puede diferir de la residencia.

    /// <summary>
    /// País del que es el paciente. Si no es el local, los tres desplegables
    /// territoriales no se usan: el catálogo de departamentos, provincias y
    /// municipios es boliviano.
    /// </summary>
    [Display(Name = "País de origen")]
    public short? IdPaisOrigen { get; set; }

    [Display(Name = "Departamento de origen")]
    public int? IdDepartamentoOrigen { get; set; }

    [Display(Name = "Provincia de origen")]
    public int? IdProvinciaOrigen { get; set; }

    [Display(Name = "Municipio de origen")]
    public int? IdMunicipioOrigen { get; set; }

    /// <summary>
    /// Marcada, el servidor guarda la residencia también como origen y los tres
    /// desplegables de origen ni siquiera se envían (el fieldset va
    /// deshabilitado). Así el dato queda afirmado por quien atiende, no supuesto
    /// por el sistema.
    /// </summary>
    [Display(Name = "Es del mismo lugar donde vive")]
    public bool OrigenIgualQueResidencia { get; set; }

    [StringLength(400)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    [Display(Name = "Carnet escaneado")]
    public IFormFile? ArchivoCarnet { get; set; }

    /// <summary>Carnet vigente ya cargado, si lo hay.</summary>
    public ArchivoDigital? CarnetVigente { get; set; }

    public bool EsNuevo => IdPaciente == 0;

    /// <summary>Edad calculada en el navegador para mostrarla al escribir la fecha.</summary>
    public int? EdadCalculada
    {
        get
        {
            if (FechaNacimiento is null) return null;
            var hoy = DateTime.Today;
            var edad = hoy.Year - FechaNacimiento.Value.Year;
            if (FechaNacimiento.Value.Date > hoy.AddYears(-edad)) edad--;
            return edad;
        }
    }

    public IEnumerable<Sexo> Sexos { get; set; } = Array.Empty<Sexo>();

    public IEnumerable<Pais> Paises { get; set; } = Array.Empty<Pais>();
    public IEnumerable<Departamento> Departamentos { get; set; }
    = Array.Empty<Departamento>();

    public IEnumerable<Provincia> Provincias { get; set; }
        = Array.Empty<Provincia>();

    public IEnumerable<Municipio> Municipios { get; set; }
        = Array.Empty<Municipio>();

    /// <summary>
    /// Deja el país local (Bolivia) elegido de entrada en un alta. La enorme
    /// mayoría de los pacientes son de acá, y sin preselección el desplegable
    /// se queda en «— Seleccione país —»: si además no se carga un municipio
    /// de origen, la ficha se guarda con IdPaisOrigen en null y deja de
    /// aparecer al filtrar las estadísticas por Bolivia, que compara el
    /// identificador y no alcanza a los nulos.
    ///
    /// El identificador sale del catálogo por la marca EsLocal, nunca fijo en
    /// el código: la base garantiza que haya uno solo. Si el catálogo no lo
    /// tiene marcado, el desplegable queda sin elegir como hasta ahora y es
    /// <see cref="Servicios.ServicioPacientes"/> el que avisa al guardar.
    ///
    /// Sólo aplica a un alta y sólo si no hay país cargado: no debe pisar lo
    /// que ya tiene una ficha existente ni lo que la usuaria acaba de elegir
    /// cuando el formulario vuelve con errores de validación.
    /// </summary>
    public void PreseleccionarPaisLocal()
    {
        if (!EsNuevo || IdPaisOrigen is not null) return;

        IdPaisOrigen = Paises.FirstOrDefault(p => p.EsLocal)?.IdPais;
    }
}

/// <summary>Pantalla de búsqueda: el primer paso de cada atención.</summary>
public class BusquedaPacienteViewModel
{
    [Display(Name = "Carnet o apellido")]
    public string? Criterio { get; set; }

    public IReadOnlyList<ResultadoBusquedaPaciente> Resultados { get; set; }
        = Array.Empty<ResultadoBusquedaPaciente>();

    /// <summary>
    /// Se escribió algo, pero sin letras ni números buscables (un emoji, sólo
    /// símbolos). No se busca y se avisa, en lugar de listar a todos.
    /// </summary>
    public bool CriterioInvalido { get; set; }

    public bool SeBusco => !string.IsNullOrWhiteSpace(Criterio);
    public bool SinResultados => SeBusco && !CriterioInvalido && Resultados.Count == 0;
}

/// <summary>Ficha completa del paciente con su historial de entregas.</summary>
public class FichaPacienteViewModel
{
    public Paciente Paciente { get; set; } = null!;
    public ArchivoDigital? CarnetVigente { get; set; }
    public IReadOnlyList<PacienteDocumento> CarnetsAnteriores { get; set; }
        = Array.Empty<PacienteDocumento>();
    public IReadOnlyList<Atencion> Atenciones { get; set; } = Array.Empty<Atencion>();

    public int TotalAtenciones => Atenciones.Count(a => !a.EstaAnulada);

    public decimal MontoTotalDonado => Atenciones
        .Where(a => !a.EstaAnulada)
        .Sum(a => a.Detalles.Sum(d => d.MontoTotal));

    public DateTime? UltimaAtencion => Atenciones
        .Where(a => !a.EstaAnulada)
        .Max(a => (DateTime?)a.FechaAtencion);
}
