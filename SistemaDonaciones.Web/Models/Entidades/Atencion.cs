using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// Entrega de medicamentos a un paciente. La receta es obligatoria tanto en la
/// aplicación como mediante la restricción NOT NULL de la base.
/// </summary>
public class Atencion
{
    public const string EstadoRegistrada = "REGISTRADA";
    public const string EstadoAnulada = "ANULADA";

    public int IdAtencion { get; set; }

    [Required(ErrorMessage = "El número de formulario es obligatorio.")]
    [StringLength(20)]
    [Display(Name = "N° de formulario")]
    public string NumeroFormulario { get; set; } = string.Empty;

    [Display(Name = "Paciente")]
    public int IdPaciente { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Fecha de atención")]
    public DateTime FechaAtencion { get; set; }

    [Display(Name = "Diagnóstico")]
    public int IdDiagnostico { get; set; }

    [Display(Name = "Condición")]
    public byte IdCondicion { get; set; }

    [Display(Name = "Hospital / establecimiento")]
    public int? IdEstablecimiento { get; set; }

    [Display(Name = "Receta escaneada")]
    public int IdArchivoReceta { get; set; }

    [StringLength(400)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    [StringLength(10)]
    public string Estado { get; set; } = EstadoRegistrada;

    [StringLength(300)]
    [Display(Name = "Motivo de anulación")]
    public string? MotivoAnulacion { get; set; }

    public DateTime FechaRegistro { get; set; }
    public int IdUsuarioRegistro { get; set; }

    public Paciente? Paciente { get; set; }
    public Diagnostico? Diagnostico { get; set; }
    public CondicionAtencion? Condicion { get; set; }
    public Establecimiento? Establecimiento { get; set; }
    public ArchivoDigital? ArchivoReceta { get; set; }
    public Usuario? UsuarioRegistro { get; set; }
    public ICollection<AtencionDetalle> Detalles { get; set; } = new List<AtencionDetalle>();

    public bool EstaAnulada => Estado == EstadoAnulada;

    [Display(Name = "Monto donado")]
    public decimal MontoTotal => Detalles.Sum(d => d.MontoTotal);
}

/// <summary>
/// Una línea por medicamento entregado. Una receta puede traer varios, y por eso
/// el detalle es una tabla aparte en lugar de columnas Medicamento1, Medicamento2…
/// </summary>
public class AtencionDetalle
{
    public const string OrigenManual = "MANUAL";
    public const string OrigenFifo = "FIFO";

    public int IdAtencionDetalle { get; set; }
    public int IdAtencion { get; set; }

    [Display(Name = "Medicamento")]
    public int IdMedicamento { get; set; }

    [Range(0.01, 999999, ErrorMessage = "La cantidad debe ser mayor que cero.")]
    [Display(Name = "Cantidad")]
    public decimal Cantidad { get; set; }

    [Display(Name = "Costo unitario")]
    public decimal? CostoUnitario { get; set; }

    /// <summary>
    /// Se almacena en lugar de calcularse. Bajo FIFO la línea puede salir de
    /// varios lotes a precios distintos y no existe un precio unitario único que
    /// la reproduzca sin arrastrar centavos de redondeo.
    /// </summary>
    [Display(Name = "Monto donado")]
    public decimal MontoTotal { get; set; }

    /// <summary>MANUAL: la usuaria escribió el monto. FIFO: lo calculó el inventario.</summary>
    [StringLength(10)]
    public string OrigenCosto { get; set; } = OrigenManual;

    public Atencion? Atencion { get; set; }
    public Medicamento? Medicamento { get; set; }
    public ICollection<ConsumoLote> Consumos { get; set; } = new List<ConsumoLote>();

    public bool CosteadoPorInventario => OrigenCosto == OrigenFifo;
}
