using System.ComponentModel.DataAnnotations;

namespace SistemaDonaciones.Web.Models.Entidades;

/// <summary>
/// Tipos sin clave primaria, mapeados a las vistas y a los resultados de los
/// procedimientos almacenados. Son de solo lectura: EF los materializa pero no
/// los rastrea ni intenta guardarlos.
/// </summary>

/// <summary>Vista vw_KardexMedicamento: ingresos y salidas de cada medicamento.</summary>
public class KardexMedicamento
{
    public int IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>INGRESO, SALIDA o ANULACION.</summary>
    [Display(Name = "Movimiento")]
    public string Movimiento { get; set; } = string.Empty;

    [Display(Name = "Fecha")]
    public DateTime Fecha { get; set; }

    [Display(Name = "Concepto")]
    public string Concepto { get; set; } = string.Empty;

    [Display(Name = "Cantidad")]
    public decimal Cantidad { get; set; }

    [Display(Name = "Costo unitario (Bs)")]
    public decimal CostoUnitario { get; set; }

    [Display(Name = "Valor (Bs)")]
    public decimal Valor { get; set; }

    public bool EsIngreso => Movimiento == "INGRESO";

    /// <summary>Una entrega a un paciente.</summary>
    public bool EsSalida => Movimiento == "SALIDA";

    /// <summary>
    /// Reversión de un ingreso. Descuenta inventario, pero no representa una
    /// entrega a un paciente.
    /// </summary>
    public bool EsAnulacion => Movimiento == "ANULACION";
}

/// <summary>Vista vw_ValorStock: existencias y su valor a costo real de adquisición.</summary>
public class ValorStock
{
    public int IdMedicamento { get; set; }

    [Display(Name = "Medicamento")]
    public string Nombre { get; set; } = string.Empty;

    [Display(Name = "Unidades en stock")]
    public decimal UnidadesEnStock { get; set; }

    [Display(Name = "Valor del stock (Bs)")]
    public decimal ValorStockBs { get; set; }

    [Display(Name = "Próximo vencimiento")]
    public DateTime? ProximoVencimiento { get; set; }

    public bool TieneVencimientoProximo(int dias = 90) =>
        ProximoVencimiento.HasValue
        && ProximoVencimiento.Value.Date <= DateTime.Today.AddDays(dias);
}

/// <summary>Vista vw_HistorialPaciente: una fila por medicamento entregado.</summary>
public class HistorialPaciente
{
    public int IdPaciente { get; set; }

    [Display(Name = "Carnet")]
    public string NumeroDocumento { get; set; } = string.Empty;

    [Display(Name = "Paciente")]
    public string Paciente { get; set; } = string.Empty;

    public int IdAtencion { get; set; }

    [Display(Name = "N° formulario")]
    public string NumeroFormulario { get; set; } = string.Empty;

    [Display(Name = "Fecha")]
    public DateTime FechaAtencion { get; set; }

    [Display(Name = "Diagnóstico")]
    public string Diagnostico { get; set; } = string.Empty;

    [Display(Name = "Condición")]
    public string Condicion { get; set; } = string.Empty;

    [Display(Name = "Establecimiento")]
    public string? Establecimiento { get; set; }

    [Display(Name = "Medicamento")]
    public string Medicamento { get; set; } = string.Empty;

    [Display(Name = "Cantidad")]
    public decimal Cantidad { get; set; }

    [Display(Name = "Monto donado (Bs)")]
    public decimal MontoDonado { get; set; }

    public string RutaReceta { get; set; } = string.Empty;
}

/// <summary>Resultado de sp_BuscarPaciente: la primera pantalla de cada atención.</summary>
public class ResultadoBusquedaPaciente
{
    public int IdPaciente { get; set; }

    [Display(Name = "Carnet")]
    public string NumeroDocumento { get; set; } = string.Empty;

    [Display(Name = "Complemento")]
    public string? ComplementoDoc { get; set; }

    [Display(Name = "Paciente")]
    public string NombreCompleto { get; set; } = string.Empty;

    [Display(Name = "Fecha de nacimiento")]
    public DateTime FechaNacimiento { get; set; }

    [Display(Name = "Edad")]
    public int Edad { get; set; }

    [Display(Name = "Sexo")]
    public string Sexo { get; set; } = string.Empty;

    [Display(Name = "Atenciones")]
    public int TotalAtenciones { get; set; }

    [Display(Name = "Última atención")]
    public DateTime? UltimaAtencion { get; set; }

    /// <summary>Carnet vigente ya cargado; si viene nulo hay que pedirlo una vez.</summary>
    public int? IdArchivoCarnet { get; set; }

    public bool TieneCarnetCargado => IdArchivoCarnet.HasValue;
}

/// <summary>
/// Fila de sp_ReporteEstadistico. El procedimiento usa GROUPING SETS, así que
/// las columnas de agrupación vienen nulas en las filas de subtotal y total.
/// </summary>
public class FilaReporteEstadistico
{
    [Display(Name = "Sexo")]
    public string? Sexo { get; set; }

    [Display(Name = "Condición")]
    public string? Condicion { get; set; }

    [Display(Name = "Grupo etario")]
    public string? GrupoEtario { get; set; }

    [Display(Name = "Atenciones")]
    public int Atenciones { get; set; }

    [Display(Name = "Monto donado (Bs)")]
    public decimal? MontoDonado { get; set; }

    [Display(Name = "Monto promedio (Bs)")]
    public decimal? MontoPromedio { get; set; }

    /// <summary>Fila de total general: ninguna dimensión está presente.</summary>
    public bool EsTotalGeneral =>
        Sexo is null && Condicion is null && GrupoEtario is null;

    public string Etiqueta
    {
        get
        {
            if (EsTotalGeneral) return "TOTAL GENERAL";
            if (Sexo is not null && Condicion is not null) return $"{Sexo} — {Condicion}";
            if (Sexo is not null) return Sexo;
            if (Condicion is not null) return Condicion;
            return GrupoEtario ?? "—";
        }
    }

    public string Dimension
    {
        get
        {
            if (EsTotalGeneral) return "Total";
            if (Sexo is not null && Condicion is not null) return "Sexo y condición";
            if (Sexo is not null) return "Sexo";
            if (Condicion is not null) return "Condición";
            return "Grupo etario";
        }
    }
}
