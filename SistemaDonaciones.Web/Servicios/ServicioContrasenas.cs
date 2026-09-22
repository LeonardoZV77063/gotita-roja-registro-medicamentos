using System.Security.Cryptography;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>
/// Derivación y verificación de contraseñas con PBKDF2-HMAC-SHA256.
///
/// Se usa la implementación de la biblioteca base de .NET en lugar de un paquete
/// externo: una dependencia menos que mantener, coherente con el requisito de
/// que el sistema siga funcionando sin intervención de los desarrolladores.
///
/// Formato almacenado en Usuario.HashContrasena (varbinary(256)):
///
///     [0]        versión del formato (1)
///     [1..4]     iteraciones, entero de 32 bits big-endian
///     [5..20]    sal aleatoria de 16 bytes
///     [21..52]   subclave derivada de 32 bytes
///
/// Guardar las iteraciones junto al hash permite subirlas en el futuro sin
/// invalidar las contraseñas ya existentes.
/// </summary>
public class ServicioContrasenas
{
    private const byte VersionFormato = 1;
    private const int TamanoSal = 16;
    private const int TamanoSubclave = 32;
    private const int IteracionesActuales = 210_000;

    /// <summary>Genera el hash de una contraseña nueva.</summary>
    public byte[] Derivar(string contrasena)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(contrasena);

        var sal = RandomNumberGenerator.GetBytes(TamanoSal);
        var subclave = Rfc2898DeriveBytes.Pbkdf2(
            password: contrasena,
            salt: sal,
            iterations: IteracionesActuales,
            hashAlgorithm: HashAlgorithmName.SHA256,
            outputLength: TamanoSubclave);

        var resultado = new byte[1 + 4 + TamanoSal + TamanoSubclave];
        resultado[0] = VersionFormato;
        EscribirEnteroBigEndian(resultado.AsSpan(1, 4), IteracionesActuales);
        sal.CopyTo(resultado.AsSpan(5, TamanoSal));
        subclave.CopyTo(resultado.AsSpan(5 + TamanoSal, TamanoSubclave));

        return resultado;
    }

    /// <summary>
    /// Verifica una contraseña contra el hash almacenado. La comparación es de
    /// tiempo constante para no filtrar información por el tiempo de respuesta.
    /// </summary>
    public bool Verificar(string contrasena, byte[]? hashAlmacenado)
    {
        if (string.IsNullOrEmpty(contrasena)) return false;
        if (hashAlmacenado is null || hashAlmacenado.Length != 1 + 4 + TamanoSal + TamanoSubclave)
            return false;
        if (hashAlmacenado[0] != VersionFormato) return false;

        var iteraciones = LeerEnteroBigEndian(hashAlmacenado.AsSpan(1, 4));
        if (iteraciones <= 0) return false;

        var sal = hashAlmacenado.AsSpan(5, TamanoSal).ToArray();
        var subclaveEsperada = hashAlmacenado.AsSpan(5 + TamanoSal, TamanoSubclave).ToArray();

        var subclaveCalculada = Rfc2898DeriveBytes.Pbkdf2(
            password: contrasena,
            salt: sal,
            iterations: iteraciones,
            hashAlgorithm: HashAlgorithmName.SHA256,
            outputLength: TamanoSubclave);

        return CryptographicOperations.FixedTimeEquals(subclaveCalculada, subclaveEsperada);
    }

    /// <summary>
    /// Indica si el hash fue generado con menos iteraciones de las actuales, para
    /// volver a derivarlo silenciosamente en el próximo inicio de sesión.
    /// </summary>
    public bool NecesitaActualizacion(byte[]? hashAlmacenado)
    {
        if (hashAlmacenado is null || hashAlmacenado.Length < 5) return true;
        if (hashAlmacenado[0] != VersionFormato) return true;
        return LeerEnteroBigEndian(hashAlmacenado.AsSpan(1, 4)) < IteracionesActuales;
    }

    private static void EscribirEnteroBigEndian(Span<byte> destino, int valor)
    {
        destino[0] = (byte)(valor >> 24);
        destino[1] = (byte)(valor >> 16);
        destino[2] = (byte)(valor >> 8);
        destino[3] = (byte)valor;
    }

    private static int LeerEnteroBigEndian(ReadOnlySpan<byte> origen) =>
        (origen[0] << 24) | (origen[1] << 16) | (origen[2] << 8) | origen[3];
}
