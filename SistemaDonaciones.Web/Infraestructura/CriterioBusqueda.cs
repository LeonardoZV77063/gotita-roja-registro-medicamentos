using System.Text;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Reglas comunes para las búsquedas de pacientes, entregas y farmacia. La
/// normalización evita resultados distintos por tildes o mayúsculas y descarta
/// caracteres sin peso de ordenación que podrían hacer coincidir todos los
/// registros en SQL Server.
///
/// Reglas:
///   · Se descartan los caracteres que no pueden formar parte de un nombre, un
///     carnet o un número de formulario (emoji, símbolos, comodines de LIKE).
///   · Las comparaciones ignoran mayúsculas y tildes (colación CI_AI).
///   · El texto se separa en palabras y TODAS deben coincidir.
///   · Carnet: cada palabra debe coincidir con el comienzo del número.
///   · Nombres y apellidos: con el comienzo de alguna de sus palabras
///     («luc» encuentra «Ana Lucía»; el guion separa palabras, así «Gómez»
///     encuentra «Pérez-Gómez»).
///   · Medicamentos y números de formulario: en cualquier parte del texto.
///
/// <c>sp_BuscarPaciente</c>, definido en <c>BaseDeDatos/01-esquema.sql</c>, aplica
/// las mismas reglas.
/// </summary>
public static class CriterioBusqueda
{
    /// <summary>Colación sin distinción de mayúsculas ni de tildes.</summary>
    public const string Colacion = "Latin1_General_CI_AI";

    /// <summary>Carácter de escape para los patrones de LIKE.</summary>
    public const string CaracterEscape = "\\";

    /// <summary>Largo máximo, igual al parámetro de sp_BuscarPaciente.</summary>
    public const int LongitudMaxima = 80;

    /// <summary>Máximo de palabras que se combinan en una búsqueda.</summary>
    public const int PalabrasMaximas = 6;

    private static readonly HashSet<char> PuntuacionPermitida = new() { '-', '\'', '.', '/' };

    /// <summary>
    /// Devuelve el criterio depurado: sin caracteres extraños, con los espacios
    /// normalizados y recortado a <see cref="LongitudMaxima"/>. Puede quedar
    /// vacío aunque el original no lo fuera; ver <see cref="EsInvalido"/>.
    /// </summary>
    public static string Limpiar(string? texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return string.Empty;

        var normalizado = texto.Normalize(NormalizationForm.FormC);
        var sb = new StringBuilder(normalizado.Length);

        foreach (var c in normalizado)
        {
            // Los emoji y demás caracteres fuera del plano básico llegan como
            // pares sustitutos: char.IsLetterOrDigit devuelve false para cada
            // mitad, así que se descartan acá.
            if (char.IsLetterOrDigit(c) || PuntuacionPermitida.Contains(c))
                sb.Append(c);
            else if (char.IsWhiteSpace(c) || c == ',')
                sb.Append(' ');
        }

        var limpio = string.Join(' ',
            sb.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries));

        return limpio.Length > LongitudMaxima
            ? limpio[..LongitudMaxima].TrimEnd()
            : limpio;
    }

    /// <summary>
    /// Verdadero cuando la persona escribió algo pero no quedó nada buscable
    /// (por ejemplo, sólo un emoji). En ese caso la búsqueda debe devolver cero
    /// resultados, nunca «todos».
    /// </summary>
    public static bool EsInvalido(string? original, string limpio) =>
        !string.IsNullOrWhiteSpace(original) && limpio.Length == 0;

    /// <summary>
    /// Palabras del criterio ya depurado, sin repetir. El guion también separa:
    /// «Pérez-Gómez» busca «Pérez» y «Gómez», y «2026-0015» busca «2026» y
    /// «0015» (las dos están en el número de formulario).
    /// </summary>
    public static IReadOnlyList<string> Palabras(string limpio) =>
        limpio.Split(new[] { ' ', '-' }, StringSplitOptions.RemoveEmptyEntries)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(PalabrasMaximas)
            .ToList();

    /// <summary>Escapa los comodines de LIKE con <see cref="CaracterEscape"/>.</summary>
    public static string EscaparLike(string texto) =>
        texto.Replace(@"\", @"\\")
             .Replace("%", @"\%")
             .Replace("_", @"\_")
             .Replace("[", @"\[");

    /// <summary>Patrón «contiene».</summary>
    public static string PatronContiene(string palabra) => $"%{EscaparLike(palabra)}%";

    /// <summary>Patrón «empieza con».</summary>
    public static string PatronEmpieza(string palabra) => $"{EscaparLike(palabra)}%";

    /// <summary>
    /// Patrón «alguna palabra empieza con». Se aplica sobre " " + campo, así la
    /// primera palabra del campo también queda precedida por un espacio.
    /// </summary>
    public static string PatronInicioDePalabra(string palabra) => $"% {EscaparLike(palabra)}%";
}
