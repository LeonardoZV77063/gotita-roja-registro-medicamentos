using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models;
using SistemaDonaciones.Web.Servicios;
using System.Diagnostics;

namespace SistemaDonaciones.Web.Controllers;

public class HomeController : Controller
{
    private readonly ServicioReportes _reportes;
    private readonly OpcionesRedLocal _redLocal;

    public HomeController(
        ServicioReportes reportes,
        IOptions<OpcionesRedLocal> redLocal)
    {
        _reportes = reportes;
        _redLocal = redLocal.Value;
    }

    /// <summary>Tablero de inicio: el estado del mes de un vistazo.</summary>
    public async Task<IActionResult> Index(CancellationToken ct)
    {
        var tablero = await _reportes.TableroAsync(ct);
        var urlCompartir = DireccionRedLocal.Resolver(_redLocal);

        ViewBag.UrlCompartir = urlCompartir;
        ViewBag.RedLocalSinTls = urlCompartir?.StartsWith(
            "http://", StringComparison.OrdinalIgnoreCase) == true;
        return View(tablero);
    }

    [AllowAnonymous]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error() =>
        View(new ErrorViewModel
        {
            RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier
        });
}
