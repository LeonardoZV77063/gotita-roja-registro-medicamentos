using System.Globalization;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Interpreta importes y cantidades escritos con coma o con punto decimal.
///
/// La aplicación corre con cultura es-BO, donde la coma es el separador decimal
/// y el punto el de miles. Sin embargo, un
/// &lt;input type="number"&gt; siempre envía el valor con punto ("12.34"), sin
/// importar el idioma del navegador. Este enlazador evita interpretar ese punto
/// como separador de miles.
///
/// Reglas, en orden:
///   · Se ignoran los espacios (también el no separable).
///   · Si aparecen punto y coma, el último que aparece es el decimal y el otro
///     es de miles: "1.234,56" y "1,234.56" valen 1234,56.
///   · Si aparece un solo separador una única vez, es el decimal:
///     "12.34" y "12,34" valen 12,34; "0.01" vale 0,01.
///   · Si el mismo separador aparece varias veces, es de miles y los grupos
///     deben ser de tres dígitos: "1.234.567" vale 1234567.
///   · No se aceptan exponentes, símbolos ni dígitos que no sean 0-9.
///
/// La ambigüedad de "1.234" (¿mil doscientos o uno coma dos?) se resuelve como
/// decimal a propósito: es lo que manda un campo numérico del navegador y, en
/// cantidades de medicamentos y costos unitarios, lo que la usuaria escribe.
/// </summary>
public static class NumeroFlexible
{
    public static bool TryParse(string? texto, out decimal valor)
    {
        valor = 0m;
        if (string.IsNullOrWhiteSpace(texto)) return false;

        var limpio = new string(texto.Where(c => !char.IsWhiteSpace(c)).ToArray());
        if (limpio.Length == 0) return false;

        var puntos = limpio.Count(c => c == '.');
        var comas = limpio.Count(c => c == ',');

        char? separadorDecimal = null;
        char? separadorMiles = null;

        if (puntos > 0 && comas > 0)
        {
            separadorDecimal = limpio.LastIndexOf('.') > limpio.LastIndexOf(',') ? '.' : ',';
            separadorMiles = separadorDecimal == '.' ? ',' : '.';

            var vecesDecimal = separadorDecimal == '.' ? puntos : comas;
            if (vecesDecimal > 1) return false;
        }
        else if (puntos + comas > 0)
        {
            var separador = puntos > 0 ? '.' : ',';
            if (puntos + comas == 1) separadorDecimal = separador;
            else separadorMiles = separador;
        }

        if (separadorMiles is char miles)
        {
            var parteEntera = separadorDecimal is char dec
                ? limpio[..limpio.LastIndexOf(dec)]
                : limpio;

            var grupos = parteEntera.TrimStart('-', '+').Split(miles);
            if (grupos[0].Length is 0 or > 3 || grupos.Skip(1).Any(g => g.Length != 3))
                return false;

            limpio = limpio.Replace(miles.ToString(), string.Empty);
        }

        if (separadorDecimal == ',')
            limpio = limpio.Replace(',', '.');

        return decimal.TryParse(
            limpio,
            NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint,
            CultureInfo.InvariantCulture,
            out valor);
    }
}

/// <summary>Enlazador de decimal y decimal? que usa <see cref="NumeroFlexible"/>.</summary>
public class EnlazadorDecimalFlexible : IModelBinder
{
    public Task BindModelAsync(ModelBindingContext contexto)
    {
        ArgumentNullException.ThrowIfNull(contexto);

        var nombre = contexto.ModelName;
        var recibido = contexto.ValueProvider.GetValue(nombre);
        if (recibido == ValueProviderResult.None) return Task.CompletedTask;

        contexto.ModelState.SetModelValue(nombre, recibido);

        var texto = recibido.FirstValue;
        var metadatos = contexto.ModelMetadata;
        var mensajes = metadatos.ModelBindingMessageProvider;

        if (string.IsNullOrWhiteSpace(texto))
        {
            // Igual que el enlazador estándar: vacío es null para decimal? y
            // error de "obligatorio" para decimal.
            if (metadatos.IsReferenceOrNullableType)
                contexto.Result = ModelBindingResult.Success(null);
            else
                contexto.ModelState.TryAddModelError(
                    nombre, mensajes.ValueMustNotBeNullAccessor(recibido.ToString()));

            return Task.CompletedTask;
        }

        if (NumeroFlexible.TryParse(texto, out var valor))
        {
            contexto.Result = ModelBindingResult.Success(valor);
        }
        else
        {
            contexto.ModelState.TryAddModelError(
                nombre,
                mensajes.AttemptedValueIsInvalidAccessor(texto, metadatos.GetDisplayName()));
        }

        return Task.CompletedTask;
    }
}

/// <summary>Registra <see cref="EnlazadorDecimalFlexible"/> para decimal y decimal?.</summary>
public class ProveedorEnlazadorDecimal : IModelBinderProvider
{
    public IModelBinder? GetBinder(ModelBinderProviderContext context) =>
        context.Metadata.UnderlyingOrModelType == typeof(decimal)
            ? new EnlazadorDecimalFlexible()
            : null;
}
