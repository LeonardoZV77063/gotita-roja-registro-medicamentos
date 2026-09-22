using Microsoft.EntityFrameworkCore.Storage;

namespace SistemaDonaciones.Web.Infraestructura;

public static class ExtensionesTransaccion
{
    /// <summary>
    /// Revierte la transacción sin lanzar. Algunos errores graves del motor ya
    /// la revierten del lado del servidor, y un segundo Rollback falla con
    /// «This SqlTransaction has completed»: esa excepción taparía el error
    /// original, que es el que hay que mostrar y registrar.
    /// </summary>
    public static async Task RevertirSinFallarAsync(this IDbContextTransaction transaccion)
    {
        try
        {
            await transaccion.RollbackAsync(CancellationToken.None);
        }
        catch (InvalidOperationException)
        {
            // La transacción ya no estaba activa.
        }
    }
}
