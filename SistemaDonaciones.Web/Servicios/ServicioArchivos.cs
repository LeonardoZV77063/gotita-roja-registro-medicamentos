using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>Opciones de almacenamiento, configurables desde appsettings.json.</summary>
public class OpcionesAlmacenamiento
{
    public const string Seccion = "Almacenamiento";

    /// <summary>
    /// Carpeta raíz donde se guardan recetas y carnets. Puede ser una ruta local
    /// del servidor o una unidad montada. Se mantiene FUERA de wwwroot: los
    /// documentos médicos no deben servirse como archivos estáticos públicos.
    /// </summary>
    public string RutaRaiz { get; set; } = "Almacen";

    /// <summary>Tamaño máximo por archivo, en megabytes.</summary>
    public int TamanoMaximoMb { get; set; } = 10;

    public long TamanoMaximoBytes => TamanoMaximoMb * 1024L * 1024L;
}

/// <summary>Resultado de registrar un archivo.</summary>
public record ResultadoArchivo(ArchivoDigital Archivo, bool YaExistia);

/// <summary>
/// Guarda recetas y carnets fuera de wwwroot. Deduplica por SHA-256 para que un
/// contenido idéntico reutilice el mismo registro y binario.
/// </summary>
public class ServicioArchivos
{
    private readonly AppDbContext _db;
    private readonly OpcionesAlmacenamiento _opciones;
    private readonly ILogger<ServicioArchivos> _log;

    /// <summary>
    /// Archivos escritos en disco durante la operación en curso (el servicio
    /// vive lo que dura la solicitud). Si la transacción que los registra se
    /// revierte, <see cref="DescartarEscritosAsync"/> los borra para que no
    /// queden huérfanos.
    /// </summary>
    private readonly List<string> _escritosSinConfirmar = new();

    public ServicioArchivos(
        AppDbContext db,
        Microsoft.Extensions.Options.IOptions<OpcionesAlmacenamiento> opciones,
        ILogger<ServicioArchivos> log)
    {
        _db = db;
        _opciones = opciones.Value;
        _log = log;
    }

    public long TamanoMaximoBytes => _opciones.TamanoMaximoBytes;

    /// <summary>
    /// Registra un archivo subido. Si su contenido ya existe en la base, no lo
    /// vuelve a escribir: devuelve el registro anterior con YaExistia = true.
    /// </summary>
    public async Task<ResultadoArchivo> GuardarAsync(
        IFormFile archivo,
        int idUsuario,
        string subcarpeta,
        CancellationToken ct = default)
    {
        ValidarArchivo(archivo);

        // El límite configurable acota la carga en memoria usada para validar la
        // firma, calcular el hash y escribir el mismo contenido.
        using var memoria = new MemoryStream();
        await using (var entrada = archivo.OpenReadStream())
        {
            await entrada.CopyToAsync(memoria, ct);
        }

        var contenido = memoria.ToArray();

        // El tipo que declara el navegador se deduce de la extensión del
        // nombre: basta renombrar un .exe a .pdf para que diga application/pdf.
        // Se confirma mirando los primeros bytes del contenido.
        if (!ContenidoCoincideConTipo(contenido, archivo.ContentType))
            throw new ArgumentException(
                "El contenido del archivo no corresponde a una imagen JPG, PNG o WEBP " +
                "ni a un PDF. Vuelva a escanearlo o expórtelo en uno de esos formatos.");

        var hash = SHA256.HashData(contenido);

        var existente = await _db.Archivos
            .FirstOrDefaultAsync(a => a.HashSha256 == hash, ct);

        if (existente is not null)
        {
            _log.LogInformation(
                "Archivo duplicado detectado ({Nombre}); se reutiliza IdArchivo={Id}.",
                archivo.FileName, existente.IdArchivo);

            // Si el registro existe pero el binario se perdió del disco (copia
            // incompleta del almacenamiento, datos de prueba), el contenido
            // recién subido es idéntico —mismo hash— y se aprovecha para
            // reponerlo.
            var rutaExistente = Path.Combine(_opciones.RutaRaiz, existente.RutaAlmacenamiento);
            if (!File.Exists(rutaExistente))
            {
                Directory.CreateDirectory(Path.GetDirectoryName(rutaExistente)!);
                await File.WriteAllBytesAsync(rutaExistente, contenido, ct);
                _log.LogWarning(
                    "IdArchivo={Id} no estaba en disco; se repuso con el contenido recién subido.",
                    existente.IdArchivo);
            }

            return new ResultadoArchivo(existente, YaExistia: true);
        }

        // El hash hace determinista la ruta de un contenido y evita colisiones
        // entre nombres originales.
        var extension = ExtensionPara(archivo.ContentType);
        var nombreEnDisco = Convert.ToHexString(hash).ToLowerInvariant() + extension;
        var rutaRelativa = Path.Combine(
            subcarpeta,
            DateTime.Today.ToString("yyyy"),
            DateTime.Today.ToString("MM"),
            nombreEnDisco);

        var rutaAbsoluta = Path.Combine(_opciones.RutaRaiz, rutaRelativa);
        Directory.CreateDirectory(Path.GetDirectoryName(rutaAbsoluta)!);

        var yaEstabaEnDisco = File.Exists(rutaAbsoluta);
        await File.WriteAllBytesAsync(rutaAbsoluta, contenido, ct);

        // Sólo se anota lo que esta operación creó: si el archivo ya estaba en
        // disco (por ejemplo, de un intento anterior) no es nuestro para borrar.
        if (!yaEstabaEnDisco)
            _escritosSinConfirmar.Add(rutaAbsoluta);

        var registro = new ArchivoDigital
        {
            NombreOriginal = Path.GetFileName(archivo.FileName),
            RutaAlmacenamiento = rutaRelativa.Replace('\\', '/'),
            TipoMime = archivo.ContentType,
            TamanoBytes = contenido.LongLength,
            HashSha256 = hash,
            FechaCarga = DateTime.Now,
            IdUsuarioCarga = idUsuario
        };

        _db.Archivos.Add(registro);
        await _db.SaveChangesAsync(ct);

        return new ResultadoArchivo(registro, YaExistia: false);
    }

    /// <summary>
    /// Da por buenos los archivos escritos hasta ahora. Se llama después de
    /// confirmar la transacción que los registró.
    /// </summary>
    public void ConfirmarEscritos() => _escritosSinConfirmar.Clear();

    /// <summary>
    /// Borra del disco los archivos escritos por esta operación que no llegaron
    /// a quedar registrados. Se llama después de revertir la transacción. Nunca
    /// lanza: un archivo que no se pudo borrar se anota en el registro y la
    /// usuaria ve igual el mensaje del error original.
    /// </summary>
    public async Task DescartarEscritosAsync()
    {
        if (_escritosSinConfirmar.Count == 0) return;

        foreach (var ruta in _escritosSinConfirmar.ToList())
        {
            try
            {
                // Otra solicitud pudo haber subido el mismo contenido y
                // registrarlo mientras tanto: si la base ya lo referencia, se
                // conserva.
                var relativa = Path.GetRelativePath(_opciones.RutaRaiz, ruta).Replace('\\', '/');
                var referenciado = await _db.Archivos
                    .AsNoTracking()
                    .AnyAsync(a => a.RutaAlmacenamiento == relativa);

                if (!referenciado && File.Exists(ruta))
                    File.Delete(ruta);
            }
            catch (Exception ex)
            {
                _log.LogWarning(ex,
                    "No se pudo descartar el archivo huérfano {Ruta}; puede borrarse a mano.", ruta);
            }
        }

        _escritosSinConfirmar.Clear();
    }

    /// <summary>Abre el contenido de un archivo para enviarlo al navegador.</summary>
    public async Task<(byte[] Contenido, string TipoMime, string Nombre)?> LeerAsync(
        int idArchivo, CancellationToken ct = default)
    {
        var registro = await _db.Archivos
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.IdArchivo == idArchivo, ct);

        if (registro is null) return null;

        var ruta = Path.Combine(_opciones.RutaRaiz, registro.RutaAlmacenamiento);
        if (!File.Exists(ruta))
        {
            _log.LogWarning(
                "El registro IdArchivo={Id} apunta a {Ruta}, que no existe en disco.",
                idArchivo, ruta);
            return null;
        }

        var contenido = await File.ReadAllBytesAsync(ruta, ct);
        return (contenido, registro.TipoMime, registro.NombreOriginal);
    }

    private void ValidarArchivo(IFormFile archivo)
    {
        if (archivo is null || archivo.Length == 0)
            throw new ArgumentException("No se recibió ningún archivo.");

        if (archivo.Length > _opciones.TamanoMaximoBytes)
            throw new ArgumentException(
                $"El archivo supera el máximo permitido de {_opciones.TamanoMaximoMb} MB.");

        if (!ArchivoDigital.TiposMimePermitidos.Contains(archivo.ContentType))
            throw new ArgumentException(
                "Sólo se aceptan imágenes JPG, PNG, WEBP o documentos PDF.");
    }

    /// <summary>
    /// Compara la firma del contenido con el tipo declarado. JPG empieza con
    /// FF D8 FF; PNG con 89 50 4E 47 0D 0A 1A 0A; WEBP con «RIFF» y «WEBP» en
    /// el byte 8; PDF con «%PDF-», que la norma permite dentro del primer KB.
    /// </summary>
    private static bool ContenidoCoincideConTipo(byte[] contenido, string tipoMime)
    {
        static bool Empieza(byte[] datos, int desde, params byte[] firma) =>
            datos.Length >= desde + firma.Length
            && datos.AsSpan(desde, firma.Length).SequenceEqual(firma);

        return tipoMime switch
        {
            "image/jpeg" => Empieza(contenido, 0, 0xFF, 0xD8, 0xFF),
            "image/png" => Empieza(contenido, 0, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A),
            "image/webp" => Empieza(contenido, 0, (byte)'R', (byte)'I', (byte)'F', (byte)'F')
                            && Empieza(contenido, 8, (byte)'W', (byte)'E', (byte)'B', (byte)'P'),
            "application/pdf" => contenido
                .AsSpan(0, Math.Min(contenido.Length, 1024))
                .IndexOf("%PDF-"u8) >= 0,
            _ => false
        };
    }

    private static string ExtensionPara(string tipoMime) => tipoMime switch
    {
        "image/jpeg" => ".jpg",
        "image/png" => ".png",
        "image/webp" => ".webp",
        "application/pdf" => ".pdf",
        _ => ".bin"
    };
}
