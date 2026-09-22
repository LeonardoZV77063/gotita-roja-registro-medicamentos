using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>
/// Verifica al arrancar que la base esté lista y crea el primer usuario
/// administrador si todavía no hay ninguno.
///
/// El usuario inicial no se siembra desde el script SQL a propósito: la
/// contraseña debe pasar por el mismo derivador PBKDF2 que usa el inicio de
/// sesión, y eso sólo puede hacerlo la aplicación. La contraseña inicial se
/// toma de la configuración y debe cambiarse en el primer ingreso.
/// </summary>
public class InicializadorDatos
{
    /// <summary>
    /// Versión de esquema que espera este código. BaseDeDatos/01-esquema.sql la
    /// registra como propiedad extendida de la base.
    /// </summary>
    public const string VersionEsquemaEsperada = "2026-09-13";

    private readonly AppDbContext _db;
    private readonly ServicioContrasenas _contrasenas;
    private readonly IConfiguration _config;
    private readonly ILogger<InicializadorDatos> _log;

    public InicializadorDatos(
        AppDbContext db,
        ServicioContrasenas contrasenas,
        IConfiguration config,
        ILogger<InicializadorDatos> log)
    {
        _db = db;
        _contrasenas = contrasenas;
        _config = config;
        _log = log;
    }

    /// <summary>
    /// Indica si la base quedó lista. Si devuelve false, la aplicación arranca
    /// igual pero no va a poder operar: se prefiere un mensaje claro en el
    /// registro y en la pantalla de ingreso antes que una traza de excepción.
    /// </summary>
    public bool BaseLista { get; private set; }

    public async Task EjecutarAsync(CancellationToken ct = default)
    {
        var constructor = new Microsoft.Data.SqlClient.SqlConnectionStringBuilder(
            _db.Database.GetConnectionString() ?? string.Empty);

        // El proveedor de configuración puede reemplazar la conexión según el
        // entorno; registrar sólo servidor y base permite diagnosticar el destino.
        _log.LogInformation(
            "Conectando a SQL Server. Servidor: «{Servidor}» · Base: «{Base}» · Entorno: {Entorno}",
            constructor.DataSource,
            constructor.InitialCatalog,
            Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production");

        if (!await _db.Database.CanConnectAsync(ct))
        {
            _log.LogError(
                "No se pudo abrir la base «{Base}» en el servidor «{Servidor}».\n" +
                "  Causas habituales, en orden de probabilidad:\n" +
                "  1. La base todavía no existe: falta ejecutar BaseDeDatos/01-esquema.sql en SSMS.\n" +
                "  2. La cadena de conexión apunta a otro servidor. Si iniciaste con F5, la que manda\n" +
                "     es la de appsettings.Development.json, no la de appsettings.json.\n" +
                "  3. El servicio SQL Server (SQLEXPRESS) no está iniciado.\n" +
                "  Para confirmar que la base existe, ejecutá en SSMS:  SELECT name FROM sys.databases;",
                constructor.InitialCatalog, constructor.DataSource);
            return;
        }

        if (!await _db.Roles.AnyAsync(ct))
        {
            _log.LogError(
                "La base «{Base}» existe pero está vacía: falta ejecutar " +
                "BaseDeDatos/01-esquema.sql. La aplicación no puede iniciar sesiones " +
                "sin los catálogos base.",
                constructor.InitialCatalog);
            return;
        }

        BaseLista = true;

        await VerificarVersionEsquemaAsync(constructor.InitialCatalog, ct);

        if (await _db.Usuarios.AnyAsync(ct))
            return;

        var rolAdmin = await _db.Roles
            .FirstOrDefaultAsync(r => r.Nombre == Rol.Administrador, ct);

        if (rolAdmin is null)
        {
            _log.LogError("No existe el rol Administrador en la base.");
            return;
        }

        var usuario = _config["UsuarioInicial:NombreUsuario"] ?? "admin";
        var contrasena = _config["UsuarioInicial:Contrasena"] ?? "Cambiar.2026";
        var nombre = _config["UsuarioInicial:NombreCompleto"] ?? "Administrador del sistema";

        _db.Usuarios.Add(new Usuario
        {
            NombreUsuario = usuario,
            NombreCompleto = nombre,
            HashContrasena = _contrasenas.Derivar(contrasena),
            IdRol = rolAdmin.IdRol,
            Activo = true
        });

        await _db.SaveChangesAsync(ct);

        _log.LogWarning(
            "Se creó el usuario administrador inicial «{Usuario}». " +
            "CAMBIE SU CONTRASEÑA en el primer inicio de sesión.",
            usuario);
    }

    /// <summary>
    /// Avisa si la base no contiene la versión y columnas que consume esta
    /// aplicación. No detiene el arranque para mantener disponibles los módulos
    /// que no dependan de los objetos faltantes.
    ///
    /// Las dos verificaciones van por separado a propósito: si una falla —por
    /// ejemplo, sin permiso para leer sys.extended_properties— la otra tiene que
    /// informar igual.
    /// </summary>
    private async Task VerificarVersionEsquemaAsync(string baseDatos, CancellationToken ct)
    {
        // Columnas que agregaron las últimas versiones del esquema: si falta
        // alguna, la base se creó con un esquema anterior.
        await VerificarColumnaAsync(
            baseDatos, "Paciente", "IdMunicipioOrigen",
            "las pantallas de pacientes y de reportes", ct);

        await VerificarColumnaAsync(
            baseDatos, "Lote", "Anulado",
            "las pantallas de farmacia y el cálculo FIFO de las entregas", ct);

        await VerificarColumnaAsync(
            baseDatos, "Paciente", "IdPaisOrigen",
            "el formulario y la ficha de pacientes, los reportes y el mapa", ct);

        try
        {
            var version = await _db.Database
                .SqlQueryRaw<string>(
                    "SELECT CAST(value AS nvarchar(40)) AS Value FROM sys.extended_properties " +
                    "WHERE class = 0 AND name = N'VersionEsquema'")
                .FirstOrDefaultAsync(ct);

            if (version is null || string.CompareOrdinal(version, VersionEsquemaEsperada) < 0)
            {
                _log.LogWarning(
                    "La base «{Base}» tiene la versión de esquema «{Version}» y esta aplicación espera " +
                    "«{Esperada}». La base se creó con un esquema anterior y el proyecto no incluye " +
                    "scripts para actualizarla: debe crearse con BaseDeDatos/01-esquema.sql. " +
                    "Hasta entonces, algunas pantallas pueden fallar.",
                    baseDatos, version ?? "sin versión", VersionEsquemaEsperada);
            }
        }
        catch (Exception ex)
        {
            // Sin permiso para leer sys.extended_properties no se bloquea nada.
            _log.LogWarning(ex, "No se pudo leer la versión del esquema de la base «{Base}».", baseDatos);
        }
    }

    /// <summary>
    /// Verifica que exista una columna que consume esta versión. Si falta, las
    /// pantallas que la consultan fallan con «Invalid column name», así que se
    /// registra como error —no como aviso— para que el motivo esté en el
    /// registro antes del primer 500. No se corta el arranque: el resto del
    /// sistema sigue en pie.
    /// </summary>
    private async Task VerificarColumnaAsync(
        string baseDatos,
        string tabla,
        string columna,
        string queSeRompe,
        CancellationToken ct)
    {
        try
        {
            // COL_LENGTH devuelve smallint. Sin el CAST, EF intenta leer un
            // Int16 como Int32 y la verificación se cae con InvalidCastException
            // en lugar de contestar.
            // COL_LENGTH acepta expresiones, así que el nombre de la tabla y el
            // de la columna van como parámetros: nada se concatena dentro del
            // texto de la consulta.
            var ancho = await _db.Database
                .SqlQueryRaw<int>(
                    "SELECT CAST(ISNULL(COL_LENGTH(@tabla, @columna), 0) AS int) AS Value",
                    new SqlParameter("@tabla", $"dbo.{tabla}"),
                    new SqlParameter("@columna", columna))
                .FirstOrDefaultAsync(ct);

            if (ancho == 0)
            {
                _log.LogError(
                    "La tabla {Tabla} de la base «{Base}» no tiene la columna {Columna}: la base se " +
                    "creó con un esquema anterior al de esta versión y debe crearse con " +
                    "BaseDeDatos/01-esquema.sql. Hasta entonces, {QueSeRompe} van a fallar.",
                    tabla, baseDatos, columna, queSeRompe);
            }
        }
        catch (Exception ex)
        {
            _log.LogWarning(ex,
                "No se pudo verificar si la base «{Base}» tiene la columna {Tabla}.{Columna}.",
                baseDatos, tabla, columna);
        }
    }
}
