using System.Text.Json;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Servicios;

public class ServicioBitacora
{
    private readonly AppDbContext _db;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public ServicioBitacora(
        AppDbContext db,
        IHttpContextAccessor httpContextAccessor)
    {
        _db = db;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task RegistrarAsync(
        int? idUsuario,
        string tabla,
        int? idRegistro,
        string accion,
        object? datosAnteriores = null,
        object? datosNuevos = null,
        CancellationToken ct = default)
    {
        var ip = _httpContextAccessor
            .HttpContext?
            .Connection
            .RemoteIpAddress?
            .ToString();

        var registro = new Bitacora
        {
            IdUsuario = idUsuario,

            TablaAfectada = tabla,

            IdRegistroAfectado = idRegistro,

            Accion = accion,

            DatosAnteriores = datosAnteriores is null
                ? null
                : JsonSerializer.Serialize(datosAnteriores),

            DatosNuevos = datosNuevos is null
                ? null
                : JsonSerializer.Serialize(datosNuevos),

            FechaHora = DateTime.Now,

            DireccionIp = ip
        };

        _db.Bitacoras.Add(registro);

        await _db.SaveChangesAsync(ct);
    }
}