using System.ComponentModel.DataAnnotations;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Servicios;

namespace SistemaDonaciones.Web.Models.ViewModels;

/// <summary>
/// Ingreso de medicamento al inventario. El costo se registra con el lote para
/// conservar su valor histórico.
/// </summary>
public class IngresoLoteViewModel
{
    [Required(ErrorMessage = "Escriba el nombre del medicamento.")]
    [StringLength(120)]
    [Display(Name = "Medicamento")]
    public string Medicamento { get; set; } = string.Empty;

    [Range(1, 255, ErrorMessage = "Seleccione cómo llegó el medicamento.")]
    [Display(Name = "¿Cómo llegó?")]
    public byte IdTipoIngreso { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de lote (opcional)")]
    public string? NumeroLote { get; set; }

    [Required(ErrorMessage = "La fecha de ingreso es obligatoria.")]
    [DataType(DataType.Date)]
    [Display(Name = "Fecha de ingreso")]
    public DateTime FechaIngreso { get; set; } = DateTime.Today;

    [DataType(DataType.Date)]
    [Display(Name = "Vence el (opcional)")]
    public DateTime? FechaVencimiento { get; set; }

    [Range(0.01, 9999999, ErrorMessage = "La cantidad debe ser mayor que cero.")]
    [Display(Name = "Cantidad")]
    public decimal CantidadIngresada { get; set; }

    [Range(0, 9999999, ErrorMessage = "El costo no puede ser negativo.")]
    [Display(Name = "Costo por unidad (Bs)")]
    public decimal CostoUnitario { get; set; }

    [StringLength(120)]
    [Display(Name = "Proveedor o donante")]
    public string? Origen { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de factura (opcional)")]
    public string? NumeroFactura { get; set; }

    [Display(Name = "Unidad de medida")]
    public byte? IdUnidadMedida { get; set; }

    public IEnumerable<TipoIngreso> TiposIngreso { get; set; } = Array.Empty<TipoIngreso>();
    public IEnumerable<UnidadMedida> UnidadesMedida { get; set; } = Array.Empty<UnidadMedida>();

    [Display(Name = "Valor total del ingreso (Bs)")]
    public decimal ValorTotal => CantidadIngresada * CostoUnitario;
}

/// <summary>Existencias actuales con su valor a costo real de adquisición.</summary>
public class InventarioViewModel
{
    [Display(Name = "Buscar medicamento")]
    public string? Criterio { get; set; }

    [Display(Name = "Sólo con stock")]
    public bool SoloConStock { get; set; } = true;

    /// <summary>Se escribió algo sin letras ni números buscables.</summary>
    public bool CriterioInvalido { get; set; }

    /// <summary>Distingue «inventario vacío» de «ningún medicamento coincide».</summary>
    public bool HayMedicamentosRegistrados { get; set; }

    public IReadOnlyList<ValorStock> Existencias { get; set; } = Array.Empty<ValorStock>();

    public decimal ValorTotalInventario => Existencias.Sum(e => e.ValorStockBs);
    public int MedicamentosConStock => Existencias.Count(e => e.UnidadesEnStock > 0);

    public IReadOnlyList<Lote> LotesPorVencer { get; set; } = Array.Empty<Lote>();
}

/// <summary>Detalle de los lotes de un medicamento, del más antiguo al más nuevo.</summary>
public class LotesMedicamentoViewModel
{
    public Medicamento Medicamento { get; set; } = null!;
    public IReadOnlyList<Lote> Lotes { get; set; } = Array.Empty<Lote>();

    // DisponibleReal y ValorDisponible ya devuelven cero para un lote anulado,
    // así que los totales de esta pantalla coinciden con los del inventario.
    public decimal TotalDisponible => Lotes.Sum(l => l.DisponibleReal);
    public decimal ValorTotal => Lotes.Sum(l => l.ValorDisponible);

    /// <summary>Ingresos dados de baja por estar mal cargados.</summary>
    public int LotesAnulados => Lotes.Count(l => l.Anulado);

    /// <summary>
    /// Costo unitario del próximo lote a consumir. Es el precio con el que se
    /// valuará la siguiente entrega, y muestra por qué el promedio no sirve.
    /// </summary>
    public decimal? ProximoCosto => Lotes
        .Where(l => l.DisponibleReal > 0 && l.FechaIngreso.Date <= DateTime.Today)
        .OrderBy(l => l.FechaIngreso)
        .ThenBy(l => l.IdLote)
        .Select(l => (decimal?)l.CostoUnitario)
        .FirstOrDefault();

    public decimal? CostoMinimo => Lotes
        .Where(l => l.DisponibleReal > 0)
        .Min(l => (decimal?)l.CostoUnitario);

    public decimal? CostoMaximo => Lotes
        .Where(l => l.DisponibleReal > 0)
        .Max(l => (decimal?)l.CostoUnitario);
}

/// <summary>
/// Corrección de un ingreso mal cargado. Sólo llega acá un lote del que
/// todavía no salió nada; el medicamento no se edita, porque cambiarlo sería
/// otro ingreso y no una corrección.
/// </summary>
public class EdicionLoteViewModel
{
    public int IdLote { get; set; }

    public int IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string Medicamento { get; set; } = string.Empty;

    [Range(1, 255, ErrorMessage = "Seleccione cómo llegó el medicamento.")]
    [Display(Name = "¿Cómo llegó?")]
    public byte IdTipoIngreso { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de lote (opcional)")]
    public string? NumeroLote { get; set; }

    [Required(ErrorMessage = "La fecha de ingreso es obligatoria.")]
    [DataType(DataType.Date)]
    [Display(Name = "Fecha de ingreso")]
    public DateTime FechaIngreso { get; set; } = DateTime.Today;

    [DataType(DataType.Date)]
    [Display(Name = "Vence el (opcional)")]
    public DateTime? FechaVencimiento { get; set; }

    [Range(0.01, 9999999, ErrorMessage = "La cantidad debe ser mayor que cero.")]
    [Display(Name = "Cantidad")]
    public decimal CantidadIngresada { get; set; }

    [Range(0, 9999999, ErrorMessage = "El costo no puede ser negativo.")]
    [Display(Name = "Costo por unidad (Bs)")]
    public decimal CostoUnitario { get; set; }

    [StringLength(120)]
    [Display(Name = "Proveedor o donante")]
    public string? Origen { get; set; }

    [StringLength(40)]
    [Display(Name = "N° de factura (opcional)")]
    public string? NumeroFactura { get; set; }

    public IEnumerable<TipoIngreso> TiposIngreso { get; set; } = Array.Empty<TipoIngreso>();

    /// <summary>Lo que decía el ingreso antes de tocarlo, para tenerlo a la vista.</summary>
    [Display(Name = "Valor original del ingreso (Bs)")]
    public decimal ValorOriginal { get; set; }

    [Display(Name = "Valor del ingreso (Bs)")]
    public decimal ValorTotal => CantidadIngresada * CostoUnitario;
}

/// <summary>Baja de un ingreso mal cargado.</summary>
public class AnulacionLoteViewModel
{
    public int IdLote { get; set; }

    public int IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string Medicamento { get; set; } = string.Empty;

    [Display(Name = "Fecha de ingreso")]
    public DateTime FechaIngreso { get; set; }

    [Display(Name = "Cantidad ingresada")]
    public decimal CantidadIngresada { get; set; }

    [Display(Name = "Disponible")]
    public decimal CantidadDisponible { get; set; }

    [Display(Name = "Costo por unidad (Bs)")]
    public decimal CostoUnitario { get; set; }

    [Required(ErrorMessage = "Escriba por qué se anula el ingreso.")]
    [StringLength(200)]
    [Display(Name = "Motivo de la anulación")]
    public string Motivo { get; set; } = string.Empty;

    /// <summary>Ya estaba anulado antes de abrir la pantalla.</summary>
    public bool YaAnulado { get; set; }

    /// <summary>Ya salieron medicamentos de este lote: la pantalla lo advierte.</summary>
    public bool TieneSalidas { get; set; }

    /// <summary>Entregas que se hicieron con este lote, para poder revisarlas.</summary>
    public IReadOnlyList<SalidaDeLote> Salidas { get; set; } = Array.Empty<SalidaDeLote>();

    [Display(Name = "Valor que sale del inventario (Bs)")]
    public decimal ValorQueSale => CantidadDisponible * CostoUnitario;
}

/// <summary>Una entrega hecha con un lote que se está por anular.</summary>
public record SalidaDeLote(
    int IdAtencion,
    string NumeroFormulario,
    DateTime Fecha,
    string Paciente,
    decimal Cantidad,
    decimal Subtotal);

/// <summary>Kardex: todos los movimientos de un medicamento.</summary>
public class KardexViewModel
{
    public int? IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string? NombreMedicamento { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime? Desde { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime? Hasta { get; set; }

    public IReadOnlyList<KardexMedicamento> Movimientos { get; set; }
        = Array.Empty<KardexMedicamento>();

    public IEnumerable<Medicamento> Medicamentos { get; set; } = Array.Empty<Medicamento>();

    public decimal TotalIngresos => Movimientos.Where(m => m.EsIngreso).Sum(m => m.Cantidad);

    // Sólo lo que se entregó a un paciente. Las anulaciones de ingresos también
    // descuentan, pero no son donaciones: sumarlas acá diría que se entregó algo
    // que nunca salió de la farmacia.
    public decimal TotalSalidas => Movimientos.Where(m => m.EsSalida).Sum(m => -m.Cantidad);

    public decimal TotalAnulado => Movimientos.Where(m => m.EsAnulacion).Sum(m => -m.Cantidad);

    public decimal ValorNeto => Movimientos.Sum(m => m.Valor);
}

/// <summary>Vista previa del reparto FIFO antes de confirmar una entrega.</summary>
public class SimulacionFifoViewModel
{
    public string Medicamento { get; set; } = string.Empty;
    public decimal Cantidad { get; set; }
    public IReadOnlyList<RepartoLote> Reparto { get; set; } = Array.Empty<RepartoLote>();
    public bool StockSuficiente { get; set; }
    public decimal StockDisponible { get; set; }

    public decimal MontoTotal => Reparto.Sum(r => r.Subtotal);

    /// <summary>Precio promedio resultante, sólo para contrastarlo con el FIFO.</summary>
    public decimal? PromedioResultante =>
        Cantidad > 0 ? MontoTotal / Cantidad : null;
}
