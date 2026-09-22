using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.ViewModels;

public class LoginViewModel
{
    [Required(ErrorMessage = "Ingrese su usuario.")]
    [Display(Name = "Usuario")]
    public string NombreUsuario { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ingrese su contraseña.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña")]
    public string Contrasena { get; set; } = string.Empty;

    [Display(Name = "Mantener la sesión iniciada")]
    public bool Recordarme { get; set; }

    public string? UrlRetorno { get; set; }
}

public class CambiarContrasenaViewModel
{
    [Required(ErrorMessage = "Ingrese su contraseña actual.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña actual")]
    public string ContrasenaActual { get; set; } = string.Empty;

    [Required(ErrorMessage = "Ingrese la nueva contraseña.")]
    [StringLength(100, MinimumLength = 8,
        ErrorMessage = "La contraseña debe tener al menos 8 caracteres.")]
    [DataType(DataType.Password)]
    [Display(Name = "Nueva contraseña")]
    public string ContrasenaNueva { get; set; } = string.Empty;

    [DataType(DataType.Password)]
    [Compare(nameof(ContrasenaNueva), ErrorMessage = "Las contraseñas no coinciden.")]
    [Display(Name = "Repetir la nueva contraseña")]
    public string ContrasenaConfirmacion { get; set; } = string.Empty;
}

public class UsuarioFormViewModel
{
    public int IdUsuario { get; set; }

    [Required(ErrorMessage = "El nombre de usuario es obligatorio.")]
    [StringLength(60)]
    [Display(Name = "Usuario")]
    public string NombreUsuario { get; set; } = string.Empty;

    [Required(ErrorMessage = "El nombre completo es obligatorio.")]
    [StringLength(120)]
    [Display(Name = "Nombre completo")]
    public string NombreCompleto { get; set; } = string.Empty;

    [StringLength(120)]
    [EmailAddress(ErrorMessage = "El correo no tiene un formato válido.")]
    [Display(Name = "Correo electrónico")]
    public string? Email { get; set; }

    [Display(Name = "Rol")]
    public byte IdRol { get; set; }

    [Display(Name = "Activo")]
    public bool Activo { get; set; } = true;

    /// <summary>Sólo se usa al crear, o cuando se quiere restablecer la clave.</summary>
    [StringLength(100, MinimumLength = 8,
        ErrorMessage = "La contraseña debe tener al menos 8 caracteres.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña")]
    public string? Contrasena { get; set; }

    public bool EsNuevo => IdUsuario == 0;
}
