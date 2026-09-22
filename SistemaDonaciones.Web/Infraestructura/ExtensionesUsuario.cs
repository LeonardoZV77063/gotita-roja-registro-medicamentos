using System.Security.Claims;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Atajos para leer la identidad del usuario que está operando, sin repetir la
/// búsqueda de claims en cada controlador.
/// </summary>
public static class ExtensionesUsuario
{
    /// <summary>Id del usuario autenticado. Lanza si no hay sesión válida.</summary>
    public static int IdUsuario(this ClaimsPrincipal principal)
    {
        var valor = principal.FindFirstValue(ClaimTypes.NameIdentifier);

        return int.TryParse(valor, out var id)
            ? id
            : throw new InvalidOperationException(
                "La sesión no contiene un identificador de usuario válido.");
    }

    public static string NombreCompleto(this ClaimsPrincipal principal) =>
        principal.FindFirstValue("NombreCompleto")
        ?? principal.Identity?.Name
        ?? "Usuario";

    public static bool EsAdministrador(this ClaimsPrincipal principal) =>
        principal.IsInRole(Rol.Administrador);
}
