using System.Globalization;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc.DataAnnotations;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Servicios;

var builder = WebApplication.CreateBuilder(args);

// Una sola instancia por equipo. Publicada, la aplicación no tiene ventana
// (WinExe): si ya está corriendo, un segundo doble clic fallaría en silencio al
// encontrar el puerto ocupado y parecería que el sistema no abre. En su lugar
// se abre el navegador en la instancia existente y esta termina. En desarrollo
// no se aplica, para que el choque de puertos se vea en la consola.
using var instanciaUnica = new Mutex(false, @"Global\GotitaRoja.SistemaDonaciones", out var esPrimeraInstancia);

if (!esPrimeraInstancia && !builder.Environment.IsDevelopment())
{
    try
    {
        AbrirNavegador(DireccionNavegable(builder.Configuration["urls"]?.Split(';')));
    }
    catch
    {
        // Sin navegador predeterminado no hay nada más que hacer: la instancia
        // que ya corre sigue atendiendo.
    }

    return;
}

var configuracionRedLocal = builder.Configuration
    .GetSection(OpcionesRedLocal.Seccion)
    .Get<OpcionesRedLocal>() ?? new OpcionesRedLocal();

// Cultura de presentación. Los decimales de formularios se interpretan aparte
// con ProveedorEnlazadorDecimal porque los campos numéricos pueden enviar punto.
var culturaBoliviana = new CultureInfo("es-BO");
CultureInfo.DefaultThreadCurrentCulture = culturaBoliviana;
CultureInfo.DefaultThreadCurrentUICulture = culturaBoliviana;

var cadenaConexion = builder.Configuration.GetConnectionString("BaseDatos")
    ?? throw new InvalidOperationException(
        "Falta la cadena de conexión 'BaseDatos' en appsettings.json.");

builder.Services.AddDbContext<AppDbContext>(opciones =>
{
    opciones.UseSqlServer(cadenaConexion, sql =>
    {
        sql.CommandTimeout(60);

        // No habilitar reintentos sin envolver las transacciones explícitas en
        // una estrategia de ejecución. Pacientes y atenciones coordinan SQL y
        // archivos, por lo que repetir parcialmente la operación no es seguro.
    });

    if (builder.Environment.IsDevelopment())
    {
        opciones.EnableSensitiveDataLogging();
        opciones.EnableDetailedErrors();
    }

    // Las claves TINYINT IDENTITY están configuradas a propósito (ver
    // AppDbContext.ConfigurarCatalogos); el aviso de EF sobre ellas es ruido.
    opciones.ConfigureWarnings(w => w.Ignore(SqlServerEventId.ByteIdentityColumnWarning));
});

builder.Services.Configure<OpcionesAlmacenamiento>(
    builder.Configuration.GetSection(OpcionesAlmacenamiento.Seccion));

// Los cortes absolutos del mapa son configurables sin recompilar.
builder.Services.Configure<OpcionesMapa>(
    builder.Configuration.GetSection(OpcionesMapa.Seccion));

builder.Services
    .AddOptions<OpcionesRedLocal>()
    .Bind(builder.Configuration.GetSection(OpcionesRedLocal.Seccion))
    .Validate(OpcionesRedLocal.EsValida,
        "RedLocal contiene un puerto o una UrlPublica inválidos. Las direcciones HTTP requieren PermitirHttpSinTls=true.")
    .ValidateOnStart();

builder.Services.AddSingleton<ServicioContrasenas>();
builder.Services.AddScoped<ServicioArchivos>();
builder.Services.AddScoped<ServicioCatalogos>();
builder.Services.AddScoped<ServicioFarmacia>();
builder.Services.AddScoped<ServicioPacientes>();
builder.Services.AddScoped<ServicioAtenciones>();
builder.Services.AddScoped<ServicioReportes>();
builder.Services.AddScoped<InicializadorDatos>();
builder.Services.AddScoped<ServicioBitacora>();
builder.Services.AddScoped<ServicioBackup>();
builder.Services.AddHostedService<ServicioBackupSegundoPlano>();
builder.Services.AddHttpContextAccessor();

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(opciones =>
    {
        opciones.LoginPath = "/Cuenta/Ingresar";
        opciones.LogoutPath = "/Cuenta/Salir";
        opciones.AccessDeniedPath = "/Cuenta/SinPermiso";
        opciones.ExpireTimeSpan = TimeSpan.FromHours(8);
        opciones.SlidingExpiration = true;
        opciones.Cookie.Name = "SistemaDonaciones";
        opciones.Cookie.HttpOnly = true;
        opciones.Cookie.SameSite = SameSiteMode.Lax;
        opciones.Cookie.SecurePolicy = configuracionRedLocal.Habilitada
            && configuracionRedLocal.PermitirHttpSinTls
                ? CookieSecurePolicy.SameAsRequest
                : builder.Environment.IsDevelopment()
                    ? CookieSecurePolicy.SameAsRequest
                    : CookieSecurePolicy.Always;
    });

builder.Services.AddAuthorization();

// Debe registrarse antes de MVC para cubrir también los Required implícitos.
builder.Services.AddSingleton<IValidationAttributeAdapterProvider, ProveedorAdaptadoresValidacion>();

// Todo exige sesión iniciada salvo lo que se marque con [AllowAnonymous].
builder.Services.AddControllersWithViews(opciones =>
{
    var politica = new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();

    opciones.Filters.Add(new Microsoft.AspNetCore.Mvc.Authorization.AuthorizeFilter(politica));

    opciones.ModelBinderProviders.Insert(0, new ProveedorEnlazadorDecimal());

    opciones.ModelMetadataDetailsProviders.Add(new ProveedorMensajesValidacion());
    MensajesValidacion.ConfigurarEnlazador(opciones);
});

// Este límite del host debe mantenerse coordinado con Almacenamiento:TamanoMaximoMb.
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(o =>
{
    o.MultipartBodyLengthLimit = 20L * 1024 * 1024;
});

var app = builder.Build();

// En desarrollo se ve la traza completa, salvo que se configure
// "Errores:MostrarDetalle": false para probar la página de error que ve la
// usuaria en producción: mensaje genérico con un código de referencia, y el
// detalle sólo en el registro del servidor.
var mostrarDetalleErrores = app.Configuration.GetValue<bool?>("Errores:MostrarDetalle")
                            ?? app.Environment.IsDevelopment();

if (mostrarDetalleErrores)
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
}

if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

using (var alcance = app.Services.CreateScope())
{
    var inicializador = alcance.ServiceProvider.GetRequiredService<InicializadorDatos>();
    await inicializador.EjecutarAsync();
}

// Quien hace doble clic en el acceso directo espera ver el sistema: al terminar
// de arrancar se abre el navegador en la dirección en la que quedó escuchando.
app.Lifetime.ApplicationStarted.Register(() =>
{
    var url = DireccionNavegable(app.Urls);

    try
    {
        AbrirNavegador(url);
    }
    catch (Exception ex)
    {
        // Sin consola, una advertencia queda en el Visor de eventos de Windows.
        app.Logger.LogWarning(ex,
            "No se pudo abrir el navegador automáticamente. Se puede entrar manualmente a {Url}.", url);
    }
});

app.Run();

// Primera dirección de la lista, con preferencia por https. Las direcciones
// comodín de Kestrel (0.0.0.0, [::], +, *) no son navegables desde el propio
// equipo, así que se reemplazan por localhost.
static string DireccionNavegable(IEnumerable<string>? direcciones)
{
    var lista = direcciones?
        .Select(d => d.Trim())
        .Where(d => d.Length > 0)
        .ToList() ?? new List<string>();

    var url = lista.FirstOrDefault(d => d.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
              ?? lista.FirstOrDefault()
              ?? "http://localhost:5000";

    return url
        .Replace("[::]", "localhost")
        .Replace("0.0.0.0", "localhost")
        .Replace("+", "localhost")
        .Replace("*", "localhost");
}

static void AbrirNavegador(string url) =>
    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
    {
        FileName = url,
        UseShellExecute = true
    });
