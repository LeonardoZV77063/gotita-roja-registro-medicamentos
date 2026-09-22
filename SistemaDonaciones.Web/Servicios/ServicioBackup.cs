using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;

namespace SistemaDonaciones.Web.Servicios;

public class InformacionBackup
{
    public string NombreArchivo { get; set; } = string.Empty;
    public string RutaCompleta { get; set; } = string.Empty;
    public long TamanoBytes { get; set; }
    public DateTime FechaCreacion { get; set; }
    public string TamanoFormateado => $"{TamanoBytes / (1024.0 * 1024.0):N2} MB";
}

public class ServicioBackup
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;
    private readonly IConfiguration _config;
    private readonly ILogger<ServicioBackup> _log;

    public ServicioBackup(
        AppDbContext db,
        IWebHostEnvironment env,
        IConfiguration config,
        ILogger<ServicioBackup> log)
    {
        _db = db;
        _env = env;
        _config = config;
        _log = log;
    }

    // Obtiene la ruta física: wwwroot/../Almacen/bd_backups
    public string ObtenerRutaCarpetaBackups()
    {
        var rutaRaizAlmacen = _config["Almacenamiento:RutaRaiz"] ?? "Almacen";
        var carpeta = Path.Combine(_env.ContentRootPath, rutaRaizAlmacen, "bd_backups");

        if (!Directory.Exists(carpeta))
        {
            Directory.CreateDirectory(carpeta);
        }

        return carpeta;
    }

    // Genera la copia de seguridad SQL y aplica la rotación de máximo 10
    public async Task<bool> RealizarBackupAsync(CancellationToken ct = default)
    {
        try
        {
            var carpeta = ObtenerRutaCarpetaBackups();
            var nombreArchivo = $"DonacionMedicamentos_{DateTime.Now:yyyyMMdd_HHmmss}.bak";
            var rutaArchivo = Path.Combine(carpeta, nombreArchivo);

            var nombreBaseDatos = _db.Database.GetDbConnection().Database;

            // Comando SQL nativo para respaldar en el disco
            var sql = $"BACKUP DATABASE [{nombreBaseDatos}] TO DISK = N'{rutaArchivo}' WITH FORMAT, INIT, NAME = N'Backup-{nombreArchivo}'";

            await _db.Database.ExecuteSqlRawAsync(sql, ct);
            _log.LogInformation("Copia de seguridad creada exitosamente: {Archivo}", nombreArchivo);

            // Rotación automática: conservar máximo N archivos (10)
            AplicarRotacion(carpeta);

            return true;
        }
        catch (Exception ex)
        {
            _log.LogError(ex, "Error al generar la copia de seguridad de la base de datos.");
            return false;
        }
    }

    // Elimina los backups más antiguos si hay más de 10
    private void AplicarRotacion(string carpeta)
    {
        var maxArchivos = _config.GetValue<int?>("Backup:MaximoArchivos") ?? 10;
        var dirInfo = new DirectoryInfo(carpeta);

        var archivos = dirInfo.GetFiles("*.bak")
                              .OrderByDescending(f => f.LastWriteTime)
                              .ToList();

        if (archivos.Count > maxArchivos)
        {
            var archivosAEliminar = archivos.Skip(maxArchivos);
            foreach (var archivo in archivosAEliminar)
            {
                try
                {
                    archivo.Delete();
                    _log.LogInformation("Eliminado backup antiguo por política de rotación: {Archivo}", archivo.Name);
                }
                catch (Exception ex)
                {
                    _log.LogWarning(ex, "No se pudo eliminar el backup antiguo: {Archivo}", archivo.Name);
                }
            }
        }
    }

    // Retorna la lista de respaldos existentes para la vista Razor
    public List<InformacionBackup> ObtenerBackupsExistentes()
    {
        var carpeta = ObtenerRutaCarpetaBackups();
        var dirInfo = new DirectoryInfo(carpeta);

        return dirInfo.GetFiles("*.bak")
                      .OrderByDescending(f => f.LastWriteTime)
                      .Select(f => new InformacionBackup
                      {
                          NombreArchivo = f.Name,
                          RutaCompleta = f.FullName,
                          TamanoBytes = f.Length,
                          FechaCreacion = f.LastWriteTime
                      })
                      .ToList();
    }
}