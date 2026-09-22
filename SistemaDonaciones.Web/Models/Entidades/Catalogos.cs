using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// Catálogos administrables desde la aplicación.
/// Todos llevan Descripcion única y bandera Activo en lugar de borrado físico,
/// porque un valor retirado hoy debe seguir explicando los registros históricos.
/// </summary>

public class Sexo
{
    public byte IdSexo { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    [StringLength(20)]
    [Display(Name = "Descripción")]
    public string Descripcion { get; set; } = string.Empty;

    public bool Activo { get; set; } = true;

    public ICollection<Paciente> Pacientes { get; set; } = new List<Paciente>();
}

public class CondicionAtencion
{
    public byte IdCondicion { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    [StringLength(40)]
    [Display(Name = "Condición")]
    public string Descripcion { get; set; } = string.Empty;

    public bool Activo { get; set; } = true;

    public ICollection<Atencion> Atenciones { get; set; } = new List<Atencion>();
}

public class Establecimiento
{
    public int IdEstablecimiento { get; set; }

    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [StringLength(120)]
    [Display(Name = "Hospital / establecimiento")]
    public string Nombre { get; set; } = string.Empty;

    public bool Activo { get; set; } = true;

    public ICollection<Atencion> Atenciones { get; set; } = new List<Atencion>();
}

/// <summary>
/// El diagnóstico llega escrito en la receta. La aplicación lo normaliza contra
/// esta tabla y crea la fila si no existe, para que la usuaria pueda escribir
/// libremente sin que el texto se repita en cada atención.
/// </summary>
public class Diagnostico
{
    public int IdDiagnostico { get; set; }

    [Required(ErrorMessage = "El diagnóstico es obligatorio.")]
    [StringLength(160)]
    [Display(Name = "Diagnóstico")]
    public string Descripcion { get; set; } = string.Empty;

    [StringLength(10)]
    [Display(Name = "Código CIE-10")]
    public string? CodigoCie10 { get; set; }

    public bool Activo { get; set; } = true;

    public ICollection<Atencion> Atenciones { get; set; } = new List<Atencion>();
}

public class UnidadMedida
{
    public byte IdUnidadMedida { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    [StringLength(40)]
    [Display(Name = "Unidad")]
    public string Descripcion { get; set; } = string.Empty;

    [Required(ErrorMessage = "La abreviatura es obligatoria.")]
    [StringLength(10)]
    [Display(Name = "Abreviatura")]
    public string Abreviatura { get; set; } = string.Empty;

    public ICollection<Medicamento> Medicamentos { get; set; } = new List<Medicamento>();
}

public class TipoIngreso
{
    public byte IdTipoIngreso { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    [StringLength(40)]
    [Display(Name = "Tipo de ingreso")]
    public string Descripcion { get; set; } = string.Empty;

    public ICollection<Lote> Lotes { get; set; } = new List<Lote>();
}
/// <summary>
/// País de origen del paciente. Bolivia es el único país con catálogo de
/// departamentos, provincias y municipios; para los demás se registra sólo el
/// país.
/// </summary>
public class Pais
{
    public short IdPais { get; set; }

    [Required(ErrorMessage = "El nombre del país es obligatorio.")]
    [StringLength(60)]
    [Display(Name = "País")]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Verdadero sólo para Bolivia. Un índice único filtrado en la base impide
    /// que haya dos, para que la aplicación nunca tenga que elegir.
    /// </summary>
    public bool EsLocal { get; set; }

    public bool Activo { get; set; } = true;

    public ICollection<Paciente> Pacientes { get; set; } = new List<Paciente>();
}

public class Departamento
{
    public int IdDepartamento { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public ICollection<Provincia> Provincias { get; set; }
        = new List<Provincia>();
}

public class Provincia
{
    public int IdProvincia { get; set; }

    public int IdDepartamento { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public Departamento? Departamento { get; set; }

    public ICollection<Municipio> Municipios { get; set; }
        = new List<Municipio>();
}

public class Municipio
{
    public int IdMunicipio { get; set; }

    public int IdProvincia { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public Provincia? Provincia { get; set; }

    public ICollection<Paciente> Pacientes { get; set; }
        = new List<Paciente>();
}
