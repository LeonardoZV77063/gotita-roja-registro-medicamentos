using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// Toda imagen o PDF del sistema (recetas y carnets) pasa por esta tabla.
/// La base guarda ruta + hash; el binario vive en el almacenamiento configurado.
///
/// HashSha256 es único: un contenido idéntico reutiliza el mismo registro y
/// binario en lugar de crear otra copia.
/// </summary>
public class ArchivoDigital
{
    public int IdArchivo { get; set; }

    [Required]
    [StringLength(255)]
    [Display(Name = "Nombre original")]
    public string NombreOriginal { get; set; } = string.Empty;

    [Required]
    [StringLength(500)]
    public string RutaAlmacenamiento { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string TipoMime { get; set; } = string.Empty;

    public long TamanoBytes { get; set; }

    /// <summary>SHA-256 del contenido. 32 bytes exactos.</summary>
    public byte[] HashSha256 { get; set; } = Array.Empty<byte>();

    [Display(Name = "Fecha de carga")]
    public DateTime FechaCarga { get; set; }

    public int IdUsuarioCarga { get; set; }

    public Usuario? UsuarioCarga { get; set; }

    /// <summary>Tipos permitidos, alineados con CK_Archivo_Mime en la base.</summary>
    public static readonly string[] TiposMimePermitidos =
    {
        "image/jpeg", "image/png", "image/webp", "application/pdf"
    };

    public bool EsPdf => TipoMime == "application/pdf";

    public string TamanoLegible => TamanoBytes switch
    {
        < 1024 => $"{TamanoBytes} B",
        < 1024 * 1024 => $"{TamanoBytes / 1024.0:0.#} KB",
        _ => $"{TamanoBytes / (1024.0 * 1024.0):0.#} MB"
    };
}
