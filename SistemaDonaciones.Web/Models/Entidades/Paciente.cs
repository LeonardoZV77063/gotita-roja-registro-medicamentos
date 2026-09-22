using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// Ficha única del paciente. Se registra una sola vez; cada visita
/// posterior agrega una <see cref="Atencion"/> a su historial en lugar de
/// duplicar sus datos y su carnet.
/// </summary>
public class Paciente
{
    public int IdPaciente { get; set; }

    [Required(ErrorMessage = "El número de carnet es obligatorio.")]
    [StringLength(20)]
    [Display(Name = "Carnet de identidad")]
    public string NumeroDocumento { get; set; } = string.Empty;

    [StringLength(5)]
    [Display(Name = "Complemento")]
    public string? ComplementoDoc { get; set; }

    [StringLength(5)]
    [Display(Name = "Extensión")]
    public string? ExtensionDoc { get; set; }

    [Required(ErrorMessage = "Los nombres son obligatorios.")]
    [StringLength(80)]
    [Display(Name = "Nombres")]
    public string Nombres { get; set; } = string.Empty;

    [Required(ErrorMessage = "El apellido paterno es obligatorio.")]
    [StringLength(60)]
    [Display(Name = "Apellido paterno")]
    public string ApellidoPaterno { get; set; } = string.Empty;

    [StringLength(60)]
    [Display(Name = "Apellido materno")]
    public string? ApellidoMaterno { get; set; }

    [Required(ErrorMessage = "La fecha de nacimiento es obligatoria.")]
    [DataType(DataType.Date)]
    [Display(Name = "Fecha de nacimiento")]
    public DateTime FechaNacimiento { get; set; }

    [Display(Name = "Sexo")]
    public byte IdSexo { get; set; }

    [StringLength(20)]
    [Display(Name = "Teléfono")]
    public string? Telefono { get; set; }
    /// <summary>Municipio donde vive hoy el paciente.</summary>
    [Display(Name = "Municipio de residencia")]
    public int? IdMunicipio { get; set; }

    /// <summary>
    /// Municipio de origen, que puede ser distinto de la residencia. Mientras
    /// esté vacío, las estadísticas usan la residencia y lo advierten.
    /// </summary>
    [Display(Name = "Municipio de origen")]
    public int? IdMunicipioOrigen { get; set; }

    /// <summary>
    /// País de origen. Para un paciente boliviano acompaña al municipio de
    /// origen; para alguien del exterior es todo lo
    /// que se registra, y <see cref="IdMunicipioOrigen"/> queda vacío, porque
    /// el catálogo territorial cargado es sólo el de Bolivia.
    /// </summary>
    [Display(Name = "País de origen")]
    public short? IdPaisOrigen { get; set; }

    // Dirección de residencia

    [StringLength(120)]
    [Display(Name = "Zona o barrio")]
    public string? Zona { get; set; }

    [StringLength(120)]
    [Display(Name = "Calle o avenida")]
    public string? Calle { get; set; }

    [StringLength(20)]
    [Display(Name = "N° de domicilio")]
    public string? NumeroDomicilio { get; set; }

    /// <summary>
    /// Referencia adicional («casa de dos pisos, portón verde»). En registros
    /// legados puede contener la dirección completa; no se intenta dividirla
    /// porque eso inventaría límites entre zona, calle y número.
    /// </summary>
    [StringLength(250)]
    [Display(Name = "Referencia")]
    public string? Direccion { get; set; }

    [StringLength(400)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    public bool Activo { get; set; } = true;

    [Display(Name = "Fecha de registro")]
    public DateTime FechaRegistro { get; set; }

    public int IdUsuarioRegistro { get; set; }

    /// <summary>
    /// Columna calculada en la base (no se almacena). La edad se deriva de la
    /// fecha de nacimiento en cada lectura, así nunca queda desactualizada
    /// después de un cumpleaños. EF nunca escribe este valor.
    /// </summary>
    [Display(Name = "Edad")]
    public int Edad { get; private set; }

    public Sexo? Sexo { get; set; }
    public Municipio? Municipio { get; set; }
    public Municipio? MunicipioOrigen { get; set; }
    public Pais? PaisOrigen { get; set; }
    public Usuario? UsuarioRegistro { get; set; }
    public ICollection<PacienteDocumento> Documentos { get; set; } = new List<PacienteDocumento>();
    public ICollection<Atencion> Atenciones { get; set; } = new List<Atencion>();

    [Display(Name = "Paciente")]
    public string NombreCompleto =>
        $"{ApellidoPaterno} {ApellidoMaterno}".Trim() + $", {Nombres}";

    [Display(Name = "Carnet")]
    public string DocumentoCompleto =>
        string.IsNullOrWhiteSpace(ComplementoDoc)
            ? NumeroDocumento
            : $"{NumeroDocumento}-{ComplementoDoc}";

    /// <summary>
    /// El paciente es de otro país. Requiere que la consulta haya incluido
    /// <see cref="PaisOrigen"/>; sin esa navegación cargada devuelve falso.
    /// </summary>
    public bool EsDelExterior => PaisOrigen is not null && !PaisOrigen.EsLocal;

    /// <summary>
    /// El municipio que representa de dónde es el paciente: el de origen si
    /// está cargado y, si no, el de residencia. Es el que usan el mapa, las
    /// estadísticas y el comprobante.
    ///
    /// Para alguien del exterior no hay municipio que valga: caer en su
    /// residencia lo pintaría en el mapa de Bolivia como si fuera de acá.
    /// </summary>
    public Municipio? MunicipioProcedencia =>
        EsDelExterior ? null : MunicipioOrigen ?? Municipio;

    /// <summary>
    /// El origen no está cargado y se está usando la residencia en su lugar.
    /// De un paciente del exterior sí se sabe de dónde es, así que no aplica.
    /// </summary>
    public bool OrigenSupuesto =>
        !EsDelExterior && IdMunicipioOrigen is null && IdMunicipio is not null;

    /// <summary>
    /// Provincia y departamento de origen, o de residencia mientras el origen
    /// no esté cargado.
    /// Devuelve null si la ubicación no está cargada o si la consulta no
    /// incluyó la cadena Municipio → Provincia → Departamento, para que la
    /// vista muestre un guion en lugar de un texto a medias.
    /// </summary>
    [Display(Name = "Procedencia")]
    public string? ProcedenciaCorta
    {
        get
        {
            if (EsDelExterior) return PaisOrigen!.Nombre;

            var municipio = MunicipioProcedencia;
            var provincia = municipio?.Provincia?.Nombre;
            var departamento = municipio?.Provincia?.Departamento?.Nombre;

            if (provincia is null && departamento is null) return null;
            if (provincia is null) return departamento;
            if (departamento is null) return provincia;

            return $"{provincia}, {departamento}";
        }
    }

    /// <summary>Municipio, provincia y departamento, para la ficha y el detalle.</summary>
    [Display(Name = "Residencia")]
    public string? ResidenciaCompleta => Describir(Municipio);

    /// <summary>
    /// Ídem para el lugar de origen. De alguien del exterior se muestra el país,
    /// que es todo lo que el sistema registra de su procedencia.
    /// </summary>
    [Display(Name = "Origen")]
    public string? OrigenCompleto =>
        EsDelExterior
            ? PaisOrigen!.Nombre
            // «Bolivia» a secas cuando se sabe el país pero no el municipio.
            : Describir(MunicipioOrigen) ?? PaisOrigen?.Nombre;

    /// <summary>
    /// Dirección armada con los campos desglosados. Si un registro legado sólo
    /// tiene la referencia, se devuelve ese texto tal como fue cargado.
    /// </summary>
    [Display(Name = "Dirección")]
    public string? DireccionCompleta
    {
        get
        {
            var calle = string.Join(' ', new[] { Calle, NumeroDomicilio }
                .Where(x => !string.IsNullOrWhiteSpace(x)));

            var partes = new[] { calle, Zona }
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .ToArray();

            return partes.Length == 0
                ? (string.IsNullOrWhiteSpace(Direccion) ? null : Direccion)
                : string.Join(", ", partes);
        }
    }

    private static string? Describir(Municipio? municipio)
    {
        var partes = new[]
            {
                municipio?.Nombre,
                municipio?.Provincia?.Nombre,
                municipio?.Provincia?.Departamento?.Nombre
            }
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToArray();

        return partes.Length == 0 ? null : string.Join(" · ", partes);
    }
}

/// <summary>
/// Historial de carnets del paciente. El carnet se renueva, y conservar el
/// anterior permite auditar una entrega contra el documento que estaba vigente
/// en esa fecha. Un índice filtrado en la base garantiza un solo vigente.
/// </summary>
public class PacienteDocumento
{
    public int IdPacienteDocumento { get; set; }
    public int IdPaciente { get; set; }
    public int IdArchivo { get; set; }
    public DateTime FechaRegistro { get; set; }
    public bool Vigente { get; set; } = true;

    public Paciente? Paciente { get; set; }
    public ArchivoDigital? Archivo { get; set; }
}
