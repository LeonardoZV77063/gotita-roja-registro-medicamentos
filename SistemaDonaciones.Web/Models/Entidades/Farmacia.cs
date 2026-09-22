using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// La aplicación normaliza el nombre escrito por la usuaria
/// contra esta tabla, creando la fila si no existe. Se guarda el Id, no el texto
/// repetido: eso es lo que permite estadísticas y el inventario por lotes.
/// </summary>
public class Medicamento
{
    public int IdMedicamento { get; set; }

    [Required(ErrorMessage = "El nombre del medicamento es obligatorio.")]
    [StringLength(120)]
    [Display(Name = "Medicamento")]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(120)]
    [Display(Name = "Nombre genérico")]
    public string? NombreGenerico { get; set; }

    [StringLength(40)]
    [Display(Name = "Concentración")]
    public string? Concentracion { get; set; }

    [Display(Name = "Unidad de medida")]
    public byte? IdUnidadMedida { get; set; }

    public bool Activo { get; set; } = true;

    [Display(Name = "Fecha de alta")]
    public DateTime FechaAlta { get; set; }

    public UnidadMedida? UnidadMedida { get; set; }
    public ICollection<Lote> Lotes { get; set; } = new List<Lote>();

    [Display(Name = "Medicamento")]
    public string NombreCompleto =>
        string.IsNullOrWhiteSpace(Concentracion) ? Nombre : $"{Nombre} {Concentracion}";
}

/// <summary>
/// Cada ingreso de medicamento es un lote con su propio costo histórico. Las
/// entregas consumen del más antiguo al más nuevo sin promediar precios.
/// </summary>
public class Lote
{
    public int IdLote { get; set; }

    [Display(Name = "Medicamento")]
    public int IdMedicamento { get; set; }

    [Display(Name = "Tipo de ingreso")]
    public byte IdTipoIngreso { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de lote")]
    public string? NumeroLote { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Fecha de ingreso")]
    public DateTime FechaIngreso { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Fecha de vencimiento")]
    public DateTime? FechaVencimiento { get; set; }

    [Range(0.01, 9999999, ErrorMessage = "La cantidad debe ser mayor que cero.")]
    [Display(Name = "Cantidad ingresada")]
    public decimal CantidadIngresada { get; set; }

    /// <summary>
    /// Mantenido por el trigger TR_ConsumoLote_ActualizarStock. Es una
    /// desnormalización deliberada: sin ella cada consulta de stock tendría que
    /// sumar todo el histórico de consumos.
    /// </summary>
    [Display(Name = "Disponible")]
    public decimal CantidadDisponible { get; set; }

    [Range(0, 9999999, ErrorMessage = "El costo no puede ser negativo.")]
    [Display(Name = "Costo unitario (Bs)")]
    public decimal CostoUnitario { get; set; }

    [StringLength(120)]
    [Display(Name = "Proveedor / donante")]
    public string? Origen { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de factura")]
    public string? NumeroFactura { get; set; }

    public DateTime FechaRegistro { get; set; }
    public int IdUsuarioRegistro { get; set; }

    /// <summary>
    /// Ingreso dado de baja por estar mal cargado.
    /// El lote deja de contar para el stock, la valuación y el FIFO, pero no se
    /// borra ni se le tocan las cantidades: las entregas que ya salieron de él
    /// conservan su costo y su comprobante.
    /// </summary>
    [Display(Name = "Anulado")]
    public bool Anulado { get; set; }

    [StringLength(200)]
    [Display(Name = "Motivo de la anulación")]
    public string? MotivoAnulacion { get; set; }

    [Display(Name = "Fecha de anulación")]
    public DateTime? FechaAnulacion { get; set; }

    public int? IdUsuarioAnulacion { get; set; }

    public Medicamento? Medicamento { get; set; }
    public TipoIngreso? TipoIngreso { get; set; }
    public Usuario? UsuarioRegistro { get; set; }
    public Usuario? UsuarioAnulacion { get; set; }
    public ICollection<ConsumoLote> Consumos { get; set; } = new List<ConsumoLote>();

    [Display(Name = "Valor en stock (Bs)")]
    public decimal ValorDisponible => Anulado ? 0m : CantidadDisponible * CostoUnitario;

    /// <summary>Unidades que este lote aporta al inventario. Un lote anulado no aporta.</summary>
    [Display(Name = "Disponible")]
    public decimal DisponibleReal => Anulado ? 0m : CantidadDisponible;

    public bool Agotado => CantidadDisponible <= 0;

    public bool Vencido =>
        FechaVencimiento.HasValue && FechaVencimiento.Value.Date < DateTime.Today;

    public bool PorVencer(int diasAviso = 90) =>
        FechaVencimiento.HasValue
        && !Vencido
        && FechaVencimiento.Value.Date <= DateTime.Today.AddDays(diasAviso);
}

/// <summary>
/// Resuelve el N:M entre una línea de entrega y los lotes de los que salió.
/// Una entrega puede consumir cantidades de varios lotes con costos distintos.
/// </summary>
public class ConsumoLote
{
    public int IdConsumo { get; set; }
    public int IdAtencionDetalle { get; set; }
    public int IdLote { get; set; }

    [Display(Name = "Cantidad")]
    public decimal Cantidad { get; set; }

    /// <summary>Copia histórica del costo del lote al momento de la entrega.</summary>
    [Display(Name = "Costo unitario (Bs)")]
    public decimal CostoUnitario { get; set; }

    /// <summary>Columna calculada PERSISTED en la base. EF no la escribe.</summary>
    [Display(Name = "Subtotal (Bs)")]
    public decimal Subtotal { get; private set; }

    public DateTime FechaRegistro { get; set; }

    public AtencionDetalle? AtencionDetalle { get; set; }
    public Lote? Lote { get; set; }
}

/// <summary>
/// Constancia de las copias de respaldo enviadas al exterior. La exportación es
/// manual; lo que el sistema garantiza es que quede registro de qué período se
/// exportó, cuándo y quién lo hizo.
/// </summary>
public class RespaldoExportacion
{
    public int IdExportacion { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime PeriodoDesde { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime PeriodoHasta { get; set; }

    [Display(Name = "Atenciones incluidas")]
    public int CantidadAtenciones { get; set; }

    [StringLength(120)]
    [Display(Name = "Destino")]
    public string? Destino { get; set; }

    public int? IdArchivoGenerado { get; set; }
    public int IdUsuario { get; set; }
    public DateTime FechaGeneracion { get; set; }

    [StringLength(300)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    public ArchivoDigital? ArchivoGenerado { get; set; }
    public Usuario? Usuario { get; set; }
}
