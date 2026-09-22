using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Configuración del acceso desde otro equipo de la red local.
///
/// El servidor no se publica en la red sólo por existir esta sección: el
/// endpoint de Kestrel también debe habilitarse de forma explícita. En
/// desarrollo se hace seleccionando el perfil «red-local».
/// </summary>
public class OpcionesRedLocal
{
    public const string Seccion = "RedLocal";

    /// <summary>Muestra el módulo para compartir la dirección de la aplicación.</summary>
    public bool Habilitada { get; set; }

    /// <summary>
    /// Dirección estable que utilizará la operadora, por ejemplo
    /// https://EQUIPO-ONG:5443. Si queda vacía se detecta una IPv4 privada.
    /// </summary>
    public string? UrlPublica { get; set; }

    /// <summary>Puerto usado cuando UrlPublica no está configurada.</summary>
    public int Puerto { get; set; } = 5000;

    /// <summary>
    /// Permite generar una dirección HTTP y cookies compatibles con ella.
    /// Debe usarse únicamente en una red privada y con el Firewall de Windows
    /// limitado al perfil Privado. Para la instalación definitiva se prefiere
    /// HTTPS y esta opción debe permanecer en false.
    /// </summary>
    public bool PermitirHttpSinTls { get; set; }

    public static bool EsValida(OpcionesRedLocal opciones)
    {
        if (opciones.Puerto is < 1 or > 65535)
            return false;

        if (string.IsNullOrWhiteSpace(opciones.UrlPublica))
            return true;

        if (!Uri.TryCreate(opciones.UrlPublica, UriKind.Absolute, out var uri)
            || (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
            || !string.IsNullOrEmpty(uri.UserInfo)
            || uri.AbsolutePath != "/"
            || !string.IsNullOrEmpty(uri.Query)
            || !string.IsNullOrEmpty(uri.Fragment))
        {
            return false;
        }

        return uri.Scheme == Uri.UriSchemeHttps || opciones.PermitirHttpSinTls;
    }
}

/// <summary>Resuelve la dirección que se muestra en el tablero.</summary>
public static class DireccionRedLocal
{
    public static string? Resolver(OpcionesRedLocal opciones)
    {
        if (!opciones.Habilitada)
            return null;

        if (!string.IsNullOrWhiteSpace(opciones.UrlPublica))
            return opciones.UrlPublica.Trim().TrimEnd('/');

        var host = ObtenerIpv4Privada() ?? Environment.MachineName;
        var esquema = opciones.PermitirHttpSinTls
            ? Uri.UriSchemeHttp
            : Uri.UriSchemeHttps;

        return new UriBuilder(esquema, host, opciones.Puerto)
            .Uri.GetLeftPart(UriPartial.Authority);
    }

    private static string? ObtenerIpv4Privada()
    {
        var candidatos = new List<CandidatoRed>();

        foreach (var red in NetworkInterface.GetAllNetworkInterfaces())
        {
            if (red.OperationalStatus != OperationalStatus.Up
                || red.NetworkInterfaceType is NetworkInterfaceType.Loopback
                    or NetworkInterfaceType.Tunnel)
            {
                continue;
            }

            try
            {
                var propiedades = red.GetIPProperties();
                var tienePuertaEnlace = propiedades.GatewayAddresses.Any(g =>
                    g.Address.AddressFamily == AddressFamily.InterNetwork
                    && !g.Address.Equals(IPAddress.Any));

                foreach (var unicast in propiedades.UnicastAddresses)
                {
                    if (EsIpv4Privada(unicast.Address))
                    {
                        candidatos.Add(new CandidatoRed(
                            unicast.Address.ToString(),
                            tienePuertaEnlace,
                            Prioridad(red.NetworkInterfaceType),
                            red.Speed));
                    }
                }
            }
            catch (NetworkInformationException)
            {
                // Un adaptador puede desaparecer mientras se enumeran las
                // interfaces. Se ignora y se continúa con los demás.
            }
        }

        return candidatos
            .OrderByDescending(c => c.TienePuertaEnlace)
            .ThenBy(c => c.PrioridadInterfaz)
            .ThenByDescending(c => c.Velocidad)
            .Select(c => c.Direccion)
            .FirstOrDefault();
    }

    private static int Prioridad(NetworkInterfaceType tipo) => tipo switch
    {
        NetworkInterfaceType.Wireless80211 => 0,
        NetworkInterfaceType.Ethernet => 1,
        NetworkInterfaceType.GigabitEthernet => 1,
        _ => 2
    };

    private static bool EsIpv4Privada(IPAddress direccion)
    {
        if (direccion.AddressFamily != AddressFamily.InterNetwork
            || IPAddress.IsLoopback(direccion))
        {
            return false;
        }

        var bytes = direccion.GetAddressBytes();
        return bytes[0] == 10
            || (bytes[0] == 172 && bytes[1] is >= 16 and <= 31)
            || (bytes[0] == 192 && bytes[1] == 168);
    }

    private sealed record CandidatoRed(
        string Direccion,
        bool TienePuertaEnlace,
        int PrioridadInterfaz,
        long Velocidad);
}
