using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;
using SistemaDonaciones.Web.Servicios;

namespace SistemaDonaciones.Web.Controllers;

/// <summary>
/// Inicio y cierre de sesión contra la tabla Usuario del esquema.
///
/// No se usa ASP.NET Core Identity para evitar un esquema paralelo a las tablas
/// Usuario y Rol existentes. La cookie lleva sólo el id, el nombre y el rol; la
/// contraseña se verifica con PBKDF2 en <see cref="ServicioContrasenas"/>.
/// </summary>
public class CuentaController : Controller
{
    private readonly AppDbContext _db;
    private readonly ServicioContrasenas _contrasenas;
    private readonly ILogger<CuentaController> _log;

    public CuentaController(
        AppDbContext db,
        ServicioContrasenas contrasenas,
        ILogger<CuentaController> log)
    {
        _db = db;
        _contrasenas = contrasenas;
        _log = log;
    }

    [AllowAnonymous]
    [HttpGet]
    public IActionResult Ingresar(string? urlRetorno = null)
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Home");

        return View(new LoginViewModel { UrlRetorno = urlRetorno });
    }

    [AllowAnonymous]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Ingresar(LoginViewModel modelo)
    {
        if (!ModelState.IsValid) return View(modelo);

        Usuario? usuario;

        try
        {
            usuario = await _db.Usuarios
                .Include(u => u.Rol)
                .FirstOrDefaultAsync(u => u.NombreUsuario == modelo.NombreUsuario);
        }
        catch (Exception ex) when (ex is Microsoft.Data.SqlClient.SqlException
                                      or InvalidOperationException)
        {
            // El ingreso es la primera pantalla que toca la base; aquí se
            // traduce un fallo de disponibilidad sin exponer la excepción.
            _log.LogError(ex, "Fallo al consultar la tabla Usuario durante el inicio de sesión.");

            ModelState.AddModelError(string.Empty,
                "No se pudo acceder a la base de datos. Verifique que el servidor SQL Server " +
                "esté iniciado y que el script 01-esquema.sql ya se haya ejecutado. " +
                "El detalle técnico quedó en el registro de la aplicación.");

            return View(modelo);
        }

        // El mismo mensaje para ambos casos evita revelar si una cuenta existe.
        if (usuario is null || !_contrasenas.Verificar(modelo.Contrasena, usuario.HashContrasena))
        {
            _log.LogWarning(
                "Intento de ingreso fallido para «{Usuario}» desde {Ip}.",
                modelo.NombreUsuario, HttpContext.Connection.RemoteIpAddress);

            ModelState.AddModelError(string.Empty, "Usuario o contraseña incorrectos.");
            return View(modelo);
        }

        if (!usuario.Activo)
        {
            ModelState.AddModelError(string.Empty,
                "Esta cuenta está desactivada. Comuníquese con el administrador.");
            return View(modelo);
        }

        // Si el hash quedó con menos iteraciones de las actuales, se rederiva
        // ahora que tenemos la contraseña en claro.
        if (_contrasenas.NecesitaActualizacion(usuario.HashContrasena))
            usuario.HashContrasena = _contrasenas.Derivar(modelo.Contrasena);

        usuario.UltimoAcceso = DateTime.Now;
        await _db.SaveChangesAsync();

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, usuario.IdUsuario.ToString()),
            new(ClaimTypes.Name, usuario.NombreUsuario),
            new("NombreCompleto", usuario.NombreCompleto),
            new(ClaimTypes.Role, usuario.Rol?.Nombre ?? string.Empty)
        };

        var identidad = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identidad),
            new AuthenticationProperties
            {
                IsPersistent = modelo.Recordarme,
                ExpiresUtc = modelo.Recordarme
                    ? DateTimeOffset.UtcNow.AddDays(14)
                    : DateTimeOffset.UtcNow.AddHours(8)
            });

        _log.LogInformation("Ingreso correcto de «{Usuario}».", usuario.NombreUsuario);

        if (!string.IsNullOrWhiteSpace(modelo.UrlRetorno) && Url.IsLocalUrl(modelo.UrlRetorno))
            return Redirect(modelo.UrlRetorno);

        return RedirectToAction("Index", "Home");
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Salir()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Ingresar));
    }

    [HttpGet]
    public IActionResult CambiarContrasena() => View(new CambiarContrasenaViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CambiarContrasena(CambiarContrasenaViewModel modelo)
    {
        if (!ModelState.IsValid) return View(modelo);

        var usuario = await _db.Usuarios.FindAsync(User.IdUsuario());
        if (usuario is null) return Forbid();

        if (!_contrasenas.Verificar(modelo.ContrasenaActual, usuario.HashContrasena))
        {
            ModelState.AddModelError(nameof(modelo.ContrasenaActual),
                "La contraseña actual no es correcta.");
            return View(modelo);
        }

        usuario.HashContrasena = _contrasenas.Derivar(modelo.ContrasenaNueva);
        await _db.SaveChangesAsync();

        TempData["Exito"] = "Su contraseña fue actualizada.";
        return RedirectToAction("Index", "Home");
    }

    [AllowAnonymous]
    public IActionResult SinPermiso() => View();
}
