namespace SistemaDonaciones.Web.Servicios;

public class ServicioBackupSegundoPlano : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _config;
    private readonly ILogger<ServicioBackupSegundoPlano> _log;

    public ServicioBackupSegundoPlano(
        IServiceScopeFactory scopeFactory,
        IConfiguration config,
        ILogger<ServicioBackupSegundoPlano> log)
    {
        _scopeFactory = scopeFactory;
        _config = config;
        _log = log;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _log.LogInformation("Servicio de copias de seguridad en segundo plano iniciado.");

        while (!stoppingToken.IsCancellationRequested)
        {
            var habilitado = _config.GetValue<bool?>("Backup:Habilitado") ?? true;
            var intervaloMinutos = _config.GetValue<int?>("Backup:IntervaloMinutos") ?? 1;

            if (habilitado)
            {
                using (var scope = _scopeFactory.CreateScope())
                {
                    var servicioBackup = scope.ServiceProvider.GetRequiredService<ServicioBackup>();
                    await servicioBackup.RealizarBackupAsync(stoppingToken);
                }
            }

            // Esperar el intervalo configurado (ej: 1 minuto para pruebas)
            await Task.Delay(TimeSpan.FromMinutes(intervaloMinutos), stoppingToken);
        }
    }
}