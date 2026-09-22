using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace SistemaDonaciones.Web.Infraestructura;

/// <summary>
/// Reconoce los errores de SQL Server que tienen una explicación para la
/// usuaria (una clave repetida, una restricción CHECK) sin exponer detalles del
/// motor.
/// </summary>
public static class ErroresBaseDatos
{
    /// <summary>2627 = UNIQUE/PRIMARY KEY; 2601 = índice único.</summary>
    private static readonly int[] NumerosDuplicado = { 2627, 2601 };

    /// <summary>547 = conflicto con una restricción CHECK o FOREIGN KEY.</summary>
    private const int NumeroRestriccion = 547;

    public static SqlException? SqlDe(Exception? ex)
    {
        while (ex is not null)
        {
            if (ex is SqlException sql) return sql;
            ex = ex.InnerException;
        }

        return null;
    }

    /// <summary>
    /// Verdadero si la excepción es una clave repetida. Si se indica el nombre
    /// de la restricción o del índice, además tiene que ser ésa.
    /// </summary>
    public static bool EsDuplicado(Exception ex, string? restriccion = null)
    {
        var sql = SqlDe(ex);
        if (sql is null || !NumerosDuplicado.Contains(sql.Number)) return false;

        return restriccion is null
               || sql.Message.Contains(restriccion, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>Verdadero si la excepción es una restricción CHECK o FOREIGN KEY violada.</summary>
    public static bool EsRestriccion(Exception ex, string? restriccion = null)
    {
        var sql = SqlDe(ex);
        if (sql is null || sql.Number != NumeroRestriccion) return false;

        return restriccion is null
               || sql.Message.Contains(restriccion, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>Texto del error del motor, para buscar el nombre de la restricción.</summary>
    public static string MensajeMotor(Exception ex) =>
        SqlDe(ex)?.Message ?? (ex as DbUpdateException)?.InnerException?.Message ?? ex.Message;
}
