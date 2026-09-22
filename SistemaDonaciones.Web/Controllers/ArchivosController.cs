using Microsoft.AspNetCore.Mvc;
using SistemaDonaciones.Web.Servicios;

namespace SistemaDonaciones.Web.Controllers;

/// <summary>
/// Entrega recetas y carnets al navegador.
///
/// Los documentos médicos permanecen fuera de wwwroot y se sirven mediante
/// acciones que exigen una sesión autenticada.
/// </summary>
public class ArchivosController : Controller
{
    private readonly ServicioArchivos _archivos;

    public ArchivosController(ServicioArchivos archivos) => _archivos = archivos;

    /// <summary>Muestra el archivo en el navegador (imagen o PDF).</summary>
    [HttpGet]
    public async Task<IActionResult> Ver(int id, CancellationToken ct)
    {
        var archivo = await _archivos.LeerAsync(id, ct);
        if (archivo is null) return NotFound();

        Response.Headers.Append("Content-Disposition",
            $"inline; filename=\"{Sanear(archivo.Value.Nombre)}\"");

        return File(archivo.Value.Contenido, archivo.Value.TipoMime);
    }

    /// <summary>Descarga el archivo original.</summary>
    [HttpGet]
    public async Task<IActionResult> Descargar(int id, CancellationToken ct)
    {
        var archivo = await _archivos.LeerAsync(id, ct);
        if (archivo is null) return NotFound();

        return File(archivo.Value.Contenido, archivo.Value.TipoMime,
            Sanear(archivo.Value.Nombre));
    }

    /// <summary>Quita caracteres que romperían la cabecera Content-Disposition.</summary>
    private static string Sanear(string nombre)
    {
        var limpio = new string(nombre
            .Where(c => !Path.GetInvalidFileNameChars().Contains(c) && c != '"')
            .ToArray());

        return string.IsNullOrWhiteSpace(limpio) ? "documento" : limpio;
    }
}
