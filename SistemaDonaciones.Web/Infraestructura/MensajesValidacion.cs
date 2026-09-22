using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.DataAnnotations;
using Microsoft.AspNetCore.Mvc.ModelBinding.Metadata;
using Microsoft.Extensions.Localization;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Mensajes de validación en español para los atributos que no traen uno propio.
///
/// Los atributos que ya declaran ErrorMessage no se tocan: siempre manda el
/// mensaje escrito a mano en el modelo.
/// </summary>
public static class MensajesValidacion
{
    public static void Aplicar(ValidationAttribute atributo)
    {
        if (!string.IsNullOrEmpty(atributo.ErrorMessageResourceName)
            || atributo.ErrorMessageResourceType is not null)
            return;

        // EmailAddress, Phone y Url traen su mensaje en inglés ya cargado en
        // ErrorMessage; se reconocen comparándolo con el de un atributo nuevo.
        if (!string.IsNullOrEmpty(atributo.ErrorMessage) && !TieneMensajePredeterminado(atributo))
            return;

        // Los marcadores {0}, {1} y {2} son los que cada atributo pasa a
        // FormatErrorMessage: {0} es siempre el nombre visible del campo.
        var mensaje = atributo switch
        {
            RequiredAttribute => "El campo «{0}» es obligatorio.",
            StringLengthAttribute s when s.MinimumLength > 0 =>
                "«{0}» debe tener entre {2} y {1} caracteres.",
            StringLengthAttribute => "«{0}» admite como máximo {1} caracteres.",
            MaxLengthAttribute => "«{0}» admite como máximo {1} caracteres o elementos.",
            MinLengthAttribute => "«{0}» debe tener al menos {1} caracteres o elementos.",
            RangeAttribute => "«{0}» debe estar entre {1} y {2}.",
            RegularExpressionAttribute => "El formato de «{0}» no es válido.",
            System.ComponentModel.DataAnnotations.CompareAttribute =>
                "«{0}» y «{1}» no coinciden.",
            EmailAddressAttribute => "«{0}» no es un correo electrónico válido.",
            PhoneAttribute => "«{0}» no es un número de teléfono válido.",
            UrlAttribute => "«{0}» no es una dirección web válida.",
            _ => null
        };

        if (mensaje is not null)
            atributo.ErrorMessage = mensaje;
    }

    private static bool TieneMensajePredeterminado(ValidationAttribute atributo) => atributo switch
    {
        EmailAddressAttribute => atributo.ErrorMessage == new EmailAddressAttribute().ErrorMessage,
        PhoneAttribute => atributo.ErrorMessage == new PhoneAttribute().ErrorMessage,
        UrlAttribute => atributo.ErrorMessage == new UrlAttribute().ErrorMessage,
        _ => false
    };

    /// <summary>Mensajes del enlazador de modelos (valores que no se pudieron convertir).</summary>
    public static void ConfigurarEnlazador(MvcOptions opciones)
    {
        var m = opciones.ModelBindingMessageProvider;

        m.SetMissingBindRequiredValueAccessor(campo => $"Falta un valor para «{campo}».");
        m.SetMissingKeyOrValueAccessor(() => "Falta un valor obligatorio.");
        m.SetMissingRequestBodyRequiredValueAccessor(() => "La solicitud llegó vacía.");
        m.SetValueMustNotBeNullAccessor(_ => "Este campo es obligatorio.");
        m.SetAttemptedValueIsInvalidAccessor((valor, campo) =>
            $"«{valor}» no es un valor válido para «{campo}».");
        m.SetNonPropertyAttemptedValueIsInvalidAccessor(valor =>
            $"«{valor}» no es un valor válido.");
        m.SetUnknownValueIsInvalidAccessor(campo => $"El valor indicado para «{campo}» no es válido.");
        m.SetNonPropertyUnknownValueIsInvalidAccessor(() => "El valor indicado no es válido.");
        m.SetValueIsInvalidAccessor(valor => $"«{valor}» no es un valor válido.");
        m.SetValueMustBeANumberAccessor(campo => $"«{campo}» debe ser un número.");
        m.SetNonPropertyValueMustBeANumberAccessor(() => "El valor debe ser un número.");
    }
}

/// <summary>
/// Aplica <see cref="MensajesValidacion"/> a los atributos declarados en los
/// modelos. Cubre la validación del servidor y la del navegador, porque ambas
/// leen el mensaje del mismo atributo.
/// </summary>
public class ProveedorMensajesValidacion : IValidationMetadataProvider
{
    public void CreateValidationMetadata(ValidationMetadataProviderContext context)
    {
        foreach (var atributo in context.Attributes.OfType<ValidationAttribute>())
            MensajesValidacion.Aplicar(atributo);

        foreach (var atributo in context.ValidationMetadata.ValidatorMetadata.OfType<ValidationAttribute>())
            MensajesValidacion.Aplicar(atributo);
    }
}

/// <summary>
/// Cubre el caso que el proveedor de metadatos no ve: para las propiedades de
/// tipo valor (byte, int, decimal, DateTime) ASP.NET crea al vuelo un
/// [Required] implícito sólo para generar data-val-required en el HTML, y ese
/// atributo nace con el mensaje en inglés.
/// </summary>
public class ProveedorAdaptadoresValidacion : IValidationAttributeAdapterProvider
{
    private readonly IValidationAttributeAdapterProvider _base = new ValidationAttributeAdapterProvider();

    public IAttributeAdapter? GetAttributeAdapter(
        ValidationAttribute attribute, IStringLocalizer? stringLocalizer)
    {
        MensajesValidacion.Aplicar(attribute);
        return _base.GetAttributeAdapter(attribute, stringLocalizer);
    }
}
