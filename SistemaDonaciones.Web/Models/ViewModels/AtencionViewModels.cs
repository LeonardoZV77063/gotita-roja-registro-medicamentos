using System.ComponentModel.DataAnnotations;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Models.ViewModels;

/// <summary>
/// Una línea del formulario de entrega: un medicamento y su cantidad.
///
/// No lleva atributos de validación a propósito. El formulario permite agregar
/// líneas en blanco y la usuaria puede dejar la última sin usar; si estos campos
/// fueran obligatorios, una línea vacía bloquearía el envío. La validación real
/// —al menos un medicamento, cantidades positivas, sin repetidos— la hace
/// <see cref="Servicios.ServicioAtenciones"/>, que además es el único lugar donde
/// puede comprobarse contra la base.
///
/// Por la misma razón Medicamento es string? y Cantidad es decimal?: con los
/// tipos no anulables, una línea en blanco llegaba con los campos vacíos y MVC
/// la rechazaba (el [Required] implícito de los tipos no anulables y el error
/// de conversión del decimal) con un mensaje que no se veía en ningún lado,
/// bloqueando el envío sin explicación.
/// </summary>
public class LineaMedicamentoViewModel
{
    [StringLength(120)]
    [Display(Name = "Medicamento")]
    public string? Medicamento { get; set; }

    [Display(Name = "Cantidad")]
    public decimal? Cantidad { get; set; }

    /// <summary>
    /// Monto escrito a mano. Se usa sólo cuando la línea no se descuenta del
    /// inventario; con FIFO el monto lo calcula el sistema a partir de los lotes.
    /// </summary>
    [Display(Name = "Monto donado (Bs)")]
    public decimal? MontoManual { get; set; }

    /// <summary>
    /// Si está marcado, la entrega descuenta del inventario y el monto sale del
    /// costo real de los lotes consumidos (FIFO). Si no, la usuaria escribe el
    /// monto manualmente.
    /// </summary>
    [Display(Name = "Descontar del inventario")]
    public bool DescontarDeInventario { get; set; }

    /// <summary>Stock disponible al momento de armar el formulario, informativo.</summary>
    public decimal? StockDisponible { get; set; }
}

/// <summary>
/// Alta de una entrega. La receta escaneada es obligatoria: sin ella el
/// formulario no se envía, igual que la base no acepta la fila.
/// </summary>
public class AtencionFormViewModel
{
    public int IdAtencion { get; set; }

    [Display(Name = "Paciente")]
    public int IdPaciente { get; set; }

    public Paciente? Paciente { get; set; }

    [Required(ErrorMessage = "El número de formulario es obligatorio.")]
    [StringLength(20)]
    [Display(Name = "N° de formulario")]
    public string NumeroFormulario { get; set; } = string.Empty;

    [Required(ErrorMessage = "La fecha de atención es obligatoria.")]
    [DataType(DataType.Date)]
    [Display(Name = "Fecha de atención")]
    public DateTime FechaAtencion { get; set; } = DateTime.Today;

    [Range(1, int.MaxValue, ErrorMessage = "Seleccione un diagnóstico.")]
    [Display(Name = "Diagnóstico")]
    public int IdDiagnostico { get; set; }

    public IEnumerable<Diagnostico> Diagnosticos { get; set; }
        = Array.Empty<Diagnostico>();

    [Range(1, 255, ErrorMessage = "Seleccione la condición del paciente.")]
    [Display(Name = "Condición")]
    public byte IdCondicion { get; set; }

    [StringLength(120)]
    [Display(Name = "Hospital / establecimiento")]
    public string? Establecimiento { get; set; }

    [Display(Name = "Receta escaneada")]
    public IFormFile? ArchivoReceta { get; set; }

    /// <summary>Receta ya cargada, al editar o al mostrar el detalle.</summary>
    public ArchivoDigital? RecetaActual { get; set; }

    [StringLength(400)]
    [Display(Name = "Observaciones")]
    public string? Observaciones { get; set; }

    [Display(Name = "Medicamentos entregados")]
    public List<LineaMedicamentoViewModel> Lineas { get; set; } = new();

    public IEnumerable<CondicionAtencion> Condiciones { get; set; }
        = Array.Empty<CondicionAtencion>();

    /// <summary>Indica si el módulo de farmacia tiene stock cargado.</summary>
    public bool InventarioDisponible { get; set; }

    public bool EsNueva => IdAtencion == 0;
}

/// <summary>Listado general de entregas con filtros.</summary>
public class ListadoAtencionesViewModel
{
    [DataType(DataType.Date)]
    [Display(Name = "Desde")]
    public DateTime? Desde { get; set; }

    [DataType(DataType.Date)]
    [Display(Name = "Hasta")]
    public DateTime? Hasta { get; set; }

    [Display(Name = "Paciente, carnet o formulario")]
    public string? Criterio { get; set; }

    [Display(Name = "Incluir anuladas")]
    public bool IncluirAnuladas { get; set; }

    /// <summary>Se escribió algo sin letras ni números buscables.</summary>
    public bool CriterioInvalido { get; set; }

    public IReadOnlyList<Atencion> Atenciones { get; set; } = Array.Empty<Atencion>();

    public int Pagina { get; set; } = 1;
    public int TotalPaginas { get; set; } = 1;
    public int TotalRegistros { get; set; }

    public decimal MontoTotal => Atenciones
        .Where(a => !a.EstaAnulada)
        .Sum(a => a.Detalles.Sum(d => d.MontoTotal));
}

/// <summary>Datos del comprobante que firma el paciente.</summary>
public class ComprobanteViewModel
{
    public Atencion Atencion { get; set; } = null!;
    public string NombreInstitucion { get; set; } = string.Empty;
    public string? DireccionInstitucion { get; set; }
    public string? TelefonoInstitucion { get; set; }

    public decimal MontoTotal => Atencion.Detalles.Sum(d => d.MontoTotal);
}

/// <summary>
/// Confirmación de anulación: exige un motivo, no se borra nada.
///
/// Sólo IdAtencion, Motivo y DevolverStock viajan en el formulario. Los datos
/// descriptivos se vuelven a leer de la base al mostrar la pantalla, en lugar de
/// mandarlos y recibirlos en campos ocultos: una fecha que va y vuelve por el
/// navegador depende del formato regional y puede romper el reenvío.
/// </summary>
public class AnularAtencionViewModel
{
    public int IdAtencion { get; set; }
    public string NumeroFormulario { get; set; } = string.Empty;
    public string Paciente { get; set; } = string.Empty;
    public DateTime FechaAtencion { get; set; }

    [Required(ErrorMessage = "Indique el motivo de la anulación.")]
    [StringLength(300)]
    [Display(Name = "Motivo de la anulación")]
    public string Motivo { get; set; } = string.Empty;

    [Display(Name = "Devolver los medicamentos al inventario")]
    public bool DevolverStock { get; set; } = true;

    public bool TieneConsumosDeInventario { get; set; }
}
