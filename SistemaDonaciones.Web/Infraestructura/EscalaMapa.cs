namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Escala de colores del mapa epidemiológico.
///
/// Los cortes viven en configuración para poder ajustarlos al volumen de la
/// institución sin recompilar.
///
/// Son cortes absolutos y no relativos al máximo del período. Una escala
/// relativa siempre produce un rojo, aunque el departamento con más atenciones
/// tenga tres: «extremo» dejaría de querer decir nada y dos períodos no se
/// podrían comparar, porque el rojo se mudaría de departamento sin que hubiera
/// cambiado nada en la realidad.
/// </summary>
public class OpcionesMapa
{
    public const string Seccion = "MapaDeCalor";

    /// <summary>Hasta esta cantidad de atenciones, demanda baja.</summary>
    public int Baja { get; set; } = 2;

    /// <summary>Hasta esta cantidad, demanda moderada.</summary>
    public int Moderada { get; set; } = 5;

    /// <summary>Hasta esta cantidad, demanda alta. Por encima, muy alta.</summary>
    public int Alta { get; set; } = 10;

    /// <summary>
    /// Techo de los cortes. No es una restricción de negocio: es para que
    /// «Alta = 2147483647» en appsettings no desborde al sumarle uno y devuelva
    /// un rango invertido, que Highcharts pintaría sin avisar.
    /// </summary>
    private const int TopeCorte = 1_000_000;

    /// <summary>
    /// Los cuatro niveles, en orden, listos para la leyenda y para las
    /// dataClasses de Highcharts. Si los números de appsettings vinieran
    /// desordenados, en cero o fuera de rango se normalizan aquí para evitar
    /// clases solapadas.
    /// </summary>
    public IReadOnlyList<NivelMapa> Niveles()
    {
        var baja = Math.Min(Math.Max(1, Baja), TopeCorte);
        var moderada = Math.Min(Math.Max(baja + 1, Moderada), TopeCorte + 1);
        var alta = Math.Min(Math.Max(moderada + 1, Alta), TopeCorte + 2);

        return new[]
        {
            new NivelMapa("Demanda baja",     1,            baja,     "#2e7d32"),
            new NivelMapa("Demanda moderada", baja + 1,     moderada, "#f9a825"),
            new NivelMapa("Demanda alta",     moderada + 1, alta,     "#ef6c00"),
            new NivelMapa("Demanda muy alta", alta + 1,     null,     "#c62828")
        };
    }
}

/// <summary>
/// Un escalón de la escala. <c>Hasta</c> en null es el último, que
/// no tiene techo.
/// </summary>
public record NivelMapa(string Nombre, int Desde, int? Hasta, string Color)
{
    /// <summary>«3 a 5» o «11 o más», para la leyenda y para el pie de la tabla.</summary>
    public string Rango => Hasta is null
        ? $"{Desde} o más"
        : Desde == Hasta ? $"{Desde}" : $"{Desde} a {Hasta}";
}
