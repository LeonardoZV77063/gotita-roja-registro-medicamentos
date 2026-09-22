using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

public class Rol
{
    public const string Administrador = "Administrador";
    public const string Operador = "Operador";

    public byte IdRol { get; set; }

    [Required]
    [StringLength(40)]
    [Display(Name = "Rol")]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(160)]
    [Display(Name = "Descripción")]
    public string? Descripcion { get; set; }

    public ICollection<Usuario> Usuarios { get; set; } = new List<Usuario>();
}

/// <summary>
/// Usuario del sistema. La contraseña nunca se guarda en claro: HashContrasena
/// almacena el resultado de PBKDF2 junto con su sal, en un único VARBINARY.
/// Ver <see cref="Servicios.ServicioContrasenas"/>.
/// </summary>
public class Usuario
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

    public byte[] HashContrasena { get; set; } = Array.Empty<byte>();

    [Display(Name = "Rol")]
    public byte IdRol { get; set; }

    public bool Activo { get; set; } = true;

    [Display(Name = "Último acceso")]
    public DateTime? UltimoAcceso { get; set; }

    public Rol? Rol { get; set; }
}

/// <summary>
/// Bitácora escrita por los triggers y por la aplicación para registrar autor,
/// acción y momento de cada cambio auditado.
/// </summary>
public class Bitacora
{
    public long IdBitacora { get; set; }
    public int? IdUsuario { get; set; }

    [Required]
    [StringLength(128)]
    public string TablaAfectada { get; set; } = string.Empty;

    public int? IdRegistroAfectado { get; set; }

    [Required]
    [StringLength(6)]
    public string Accion { get; set; } = string.Empty;

    public string? DatosAnteriores { get; set; }
    public string? DatosNuevos { get; set; }
    public DateTime FechaHora { get; set; }

    [StringLength(45)]
    public string? DireccionIp { get; set; }

    public Usuario? Usuario { get; set; }
}
