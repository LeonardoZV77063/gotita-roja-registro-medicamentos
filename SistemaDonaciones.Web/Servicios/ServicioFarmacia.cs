using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Servicios;


/// <summary>Se lanza cuando el inventario no alcanza para cubrir una entrega.</summary>
public class StockInsuficienteException : Exception
{
    public StockInsuficienteException(string mensaje) : base(mensaje) { }
}

/// <summary>
/// Inventario por lotes con costeo FIFO.
///
/// Cada ingreso conserva su costo histórico. Las entregas consumen del lote más
/// antiguo al más nuevo y suman el costo de las cantidades tomadas de cada lote,
/// sin promediar precios de ingresos distintos.
///
/// El reparto lo hace el procedimiento almacenado sp_ConsumirLotesFifo, que
/// resuelve la asignación con una suma corrida en un solo INSERT (sin cursor) y
/// bloquea los lotes con UPDLOCK para que dos entregas simultáneas no se lleven
/// las mismas unidades.
///
/// Un lote sólo puede salir en una entrega si ya había ingresado a esa fecha. El
/// procedimiento, la simulación y el cálculo de stock aplican el mismo corte.
/// </summary>
public class ServicioFarmacia
{
    private readonly AppDbContext _db;
    private readonly ServicioBitacora _bitacora;
    private readonly ILogger<ServicioFarmacia> _log;

    public ServicioFarmacia(
    AppDbContext db,
    ServicioBitacora bitacora,
    ILogger<ServicioFarmacia> log)
    {
        _db = db;
        _bitacora = bitacora;
        _log = log;
    }

    /// <summary>
    /// Descuenta del inventario la cantidad de una línea de entrega y devuelve
    /// el monto real que representa, según el precio de cada lote consumido.
    /// El procedimiento además actualiza MontoTotal y OrigenCosto de la línea.
    /// </summary>
    public async Task<decimal> ConsumirFifoAsync(
        int idAtencionDetalle,
        int idMedicamento,
        decimal cantidad,
        CancellationToken ct = default)
    {
        var pMonto = new SqlParameter("@MontoTotal", SqlDbType.Decimal)
        {
            Precision = 14,
            Scale = 2,
            Direction = ParameterDirection.Output
        };

        try
        {
            await _db.Database.ExecuteSqlRawAsync(
                "EXEC sp_ConsumirLotesFifo @IdAtencionDetalle, @IdMedicamento, @Cantidad, @MontoTotal OUTPUT",
                new[]
                {
                    new SqlParameter("@IdAtencionDetalle", SqlDbType.Int) { Value = idAtencionDetalle },
                    new SqlParameter("@IdMedicamento", SqlDbType.Int) { Value = idMedicamento },
                    new SqlParameter("@Cantidad", SqlDbType.Decimal)
                        { Precision = 10, Scale = 2, Value = cantidad },
                    pMonto
                },
                ct);
        }
        catch (SqlException ex) when (ex.Number == 50001)
        {
            // 50001 es el error que levanta el procedimiento cuando no alcanza
            // el stock. Se traduce a una excepción propia para que el
            // controlador muestre el mensaje sin exponer detalles del motor.
            throw new StockInsuficienteException(ex.Message);
        }

        var monto = pMonto.Value as decimal? ?? 0m;

        _log.LogInformation(
            "FIFO aplicado a detalle {Detalle}: {Cantidad} unidades del medicamento {Medicamento} por {Monto} Bs.",
            idAtencionDetalle, cantidad, idMedicamento, monto);

        return monto;
    }

    /// <summary>Deshace los consumos de una línea y devuelve las unidades a sus lotes.</summary>
    public async Task DevolverConsumosAsync(int idAtencionDetalle, CancellationToken ct = default)
    {
        var consumos = await _db.ConsumosLote
            .Where(c => c.IdAtencionDetalle == idAtencionDetalle)
            .ToListAsync(ct);

        if (consumos.Count == 0) return;

        // El trigger TR_ConsumoLote_ActualizarStock devuelve las cantidades a
        // los lotes al borrar las filas.
        _db.ConsumosLote.RemoveRange(consumos);
        await _db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// Stock disponible de un medicamento a una fecha: suma los lotes vivos que
    /// ya habían ingresado ese día. Sin fecha, se toma hoy.
    /// </summary>
    public async Task<decimal> StockDisponibleAsync(
        int idMedicamento, DateTime? fechaCorte = null, CancellationToken ct = default)
    {
        var corte = FechaDeCorte(fechaCorte);

        return await _db.Lotes
            .Where(l => l.IdMedicamento == idMedicamento
                        && l.CantidadDisponible > 0
                        && !l.Anulado
                        && l.FechaIngreso <= corte)
            .SumAsync(l => l.CantidadDisponible, ct);
    }

    /// <summary>
    /// Existencias para la pantalla de Farmacia. Con <paramref name="soloConStock"/>
    /// en false también aparecen los medicamentos agotados o sin lotes, con
    /// cero unidades. La vista vw_ValorStock sólo contiene filas con stock, por
    /// lo que los demás medicamentos se completan aquí.
    /// </summary>
    public async Task<List<ValorStock>> ExistenciasAsync(
        string? criterio, bool soloConStock, CancellationToken ct = default)
    {
        var texto = CriterioBusqueda.Limpiar(criterio);
        if (CriterioBusqueda.EsInvalido(criterio, texto))
            return new List<ValorStock>();

        var palabras = CriterioBusqueda.Palabras(texto);

        var stock = _db.ValoresStock.AsNoTracking();
        foreach (var palabra in palabras)
        {
            var patron = CriterioBusqueda.PatronContiene(palabra);
            stock = stock.Where(v => EF.Functions.Like(
                EF.Functions.Collate(v.Nombre, CriterioBusqueda.Colacion),
                patron, CriterioBusqueda.CaracterEscape));
        }

        var existencias = await stock.ToListAsync(ct);

        if (!soloConStock)
        {
            var medicamentos = _db.Medicamentos.AsNoTracking().Where(m => m.Activo);
            foreach (var palabra in palabras)
            {
                var patron = CriterioBusqueda.PatronContiene(palabra);
                medicamentos = medicamentos.Where(m => EF.Functions.Like(
                    EF.Functions.Collate(m.Nombre, CriterioBusqueda.Colacion),
                    patron, CriterioBusqueda.CaracterEscape));
            }

            var conStock = existencias.Select(e => e.IdMedicamento).ToHashSet();

            var sinStock = await medicamentos
                .Select(m => new { m.IdMedicamento, m.Nombre })
                .ToListAsync(ct);

            existencias.AddRange(sinStock
                .Where(m => !conStock.Contains(m.IdMedicamento))
                .Select(m => new ValorStock
                {
                    IdMedicamento = m.IdMedicamento,
                    Nombre = m.Nombre,
                    UnidadesEnStock = 0m,
                    ValorStockBs = 0m,
                    ProximoVencimiento = null
                }));
        }

        return existencias
            .OrderBy(e => e.Nombre, StringComparer.CurrentCultureIgnoreCase)
            .ToList();
    }

    /// <summary>
    /// Vista previa del reparto FIFO sin tocar la base: sirve para mostrarle a
    /// la usuaria de qué lotes va a salir la entrega y a qué precio, antes de
    /// confirmarla.
    /// </summary>
    public async Task<List<RepartoLote>> SimularFifoAsync(
        int idMedicamento, decimal cantidad, DateTime? fechaCorte = null, CancellationToken ct = default)
    {
        var corte = FechaDeCorte(fechaCorte);

        var lotes = await _db.Lotes
            .AsNoTracking()
            .Include(l => l.TipoIngreso)
            .Where(l => l.IdMedicamento == idMedicamento
                        && l.CantidadDisponible > 0
                        && !l.Anulado
                        && l.FechaIngreso <= corte)
            .OrderBy(l => l.FechaIngreso)
            .ThenBy(l => l.IdLote)
            .ToListAsync(ct);

        var reparto = new List<RepartoLote>();
        var pendiente = cantidad;

        foreach (var lote in lotes)
        {
            if (pendiente <= 0) break;

            var toma = Math.Min(pendiente, lote.CantidadDisponible);
            reparto.Add(new RepartoLote(
                lote.IdLote,
                lote.NumeroLote,
                lote.FechaIngreso,
                lote.TipoIngreso?.Descripcion ?? "—",
                toma,
                lote.CostoUnitario,
                toma * lote.CostoUnitario));

            pendiente -= toma;
        }

        return reparto;
    }

    /// <summary>Fecha más antigua que se acepta para un ingreso, contra errores de tipeo del año.</summary>
    public static readonly DateTime IngresoMinimo = new(2000, 1, 1);

    /// <summary>
    /// La fecha hasta la que un lote puede participar de una entrega o de una
    /// simulación. Nunca es posterior a hoy.
    /// </summary>
    private static DateTime FechaDeCorte(DateTime? fecha)
    {
        var hoy = DateTime.Today;
        return fecha is null || fecha.Value.Date > hoy ? hoy : fecha.Value.Date;
    }

    /// <summary>Registra un ingreso de medicamento al inventario.</summary>
    public async Task<Lote> RegistrarIngresoAsync(
    Lote lote,
    CancellationToken ct = default)
    {
        // El controlador ya lo valida; se repite acá porque es la regla que
        // protege al FIFO y este método es la única puerta de entrada de lotes.
        ValidarDatosLote(lote);

        lote.CantidadDisponible =
            lote.CantidadIngresada;

        lote.FechaRegistro =
            DateTime.Now;

        _db.Lotes.Add(lote);

        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            lote.IdUsuarioRegistro,
            "Lote",
            lote.IdLote,
            "INSERT",
            null,
            Instantanea(lote),
            ct);

        _log.LogInformation(
            "Ingreso de {Cantidad} unidades del medicamento {Medicamento} a {Costo} Bs c/u (lote {Lote}).",
            lote.CantidadIngresada,
            lote.IdMedicamento,
            lote.CostoUnitario,
            lote.IdLote);

        return lote;
    }

    /// <summary>Verdadero si ya salió algo de este lote.</summary>
    public Task<bool> TieneSalidasAsync(int idLote, CancellationToken ct = default) =>
        _db.ConsumosLote.AnyAsync(c => c.IdLote == idLote, ct);

    /// <summary>
    /// Corrige un ingreso mal cargado.
    ///
    /// Sólo se permite mientras no haya salido nada del lote. Si ya hubo
    /// entregas, cambiarle el costo reescribiría hacia atrás el valor de
    /// donaciones ya informadas y comprobantes ya impresos: en ese caso el
    /// camino es anular el saldo con <see cref="AnularLoteAsync"/> y registrar
    /// el ingreso correcto por separado.
    /// </summary>
    public async Task<Lote> EditarLoteAsync(
        Lote datos, int idUsuario, CancellationToken ct = default)
    {
        ValidarDatosLote(datos);

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            // El lote se lee con UPDLOCK/HOLDLOCK y dentro de la transacción: es
            // el mismo bloqueo que toma sp_ConsumirLotesFifo antes de reservar
            // unidades, así que mientras dure esta corrección ninguna entrega
            // puede consumir de este lote. Sin eso, entre la verificación de
            // «no tiene salidas» y el guardado cabía una entrega: la corrección
            // le habría cambiado el costo a una entrega ya registrada y, al
            // reescribir CantidadDisponible, habría devuelto al inventario
            // unidades que ya se entregaron.
            var lote = await _db.Lotes
                .FromSqlInterpolated(
                    $"SELECT * FROM Lote WITH (UPDLOCK, HOLDLOCK) WHERE IdLote = {datos.IdLote}")
                .FirstOrDefaultAsync(ct)
                ?? throw new ReglaNegocioException("El ingreso indicado no existe.");

            if (lote.Anulado)
                throw new ReglaNegocioException(
                    "Este ingreso está anulado y ya no se corrige. Si las unidades siguen " +
                    "en el depósito, regístrelas como un ingreso nuevo con los datos correctos.");

            if (await TieneSalidasAsync(lote.IdLote, ct))
                throw new ReglaNegocioException(
                    "De este ingreso ya salieron medicamentos, así que no se puede corregir: " +
                    "cambiarlo ahora alteraría el monto de entregas ya registradas y de " +
                    "comprobantes ya impresos. Anúlelo y registre el ingreso correcto: las " +
                    "entregas anteriores conservan el costo que tenían.");

            var anterior = Instantanea(lote);

            lote.IdTipoIngreso = datos.IdTipoIngreso;
            lote.NumeroLote = string.IsNullOrWhiteSpace(datos.NumeroLote)
                ? null : datos.NumeroLote.Trim();
            lote.FechaIngreso = datos.FechaIngreso.Date;
            lote.FechaVencimiento = datos.FechaVencimiento?.Date;
            lote.CostoUnitario = datos.CostoUnitario;
            lote.Origen = string.IsNullOrWhiteSpace(datos.Origen) ? null : datos.Origen.Trim();
            lote.NumeroFactura = string.IsNullOrWhiteSpace(datos.NumeroFactura)
                ? null : datos.NumeroFactura.Trim();

            // Sin salidas, lo disponible es todo lo ingresado: las dos cantidades
            // se mueven juntas o CK_Lote_Cantidades corta la operación.
            lote.CantidadIngresada = datos.CantidadIngresada;
            lote.CantidadDisponible = datos.CantidadIngresada;

            await _db.SaveChangesAsync(ct);

            await _bitacora.RegistrarAsync(
                idUsuario, "Lote", lote.IdLote, "UPDATE", anterior, Instantanea(lote), ct);

            await tx.CommitAsync(ct);

            _log.LogInformation(
                "Ingreso {Lote} corregido: {Cantidad} unidades a {Costo} Bs c/u.",
                lote.IdLote, lote.CantidadIngresada, lote.CostoUnitario);

            return lote;
        }
        catch
        {
            await tx.RevertirSinFallarAsync();
            _db.ChangeTracker.Clear();
            throw;
        }
    }

    /// <summary>
    /// Da de baja un ingreso mal cargado. El lote sale del stock, de la
    /// valuación y del FIFO, pero no se borra ni se le tocan las cantidades: lo
    /// que ya se entregó con él conserva su costo, porque un comprobante
    /// impreso el mes pasado no puede cambiar de monto.
    ///
    /// Es reversible a nivel de datos —basta apagar la bandera— y queda en la
    /// bitácora con motivo, fecha y autor.
    /// </summary>
    public async Task<Lote> AnularLoteAsync(
        int idLote, string? motivo, int idUsuario, CancellationToken ct = default)
    {
        var texto = motivo?.Trim();

        if (string.IsNullOrWhiteSpace(texto))
            throw new ReglaNegocioException(
                "Escriba por qué se anula el ingreso. Es lo que va a leer quien revise " +
                "el inventario dentro de seis meses.");

        if (texto.Length > 200)
            texto = texto[..200];

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            // Mismo bloqueo que en la corrección: si dos administradores anulan
            // el mismo ingreso a la vez, el segundo espera y encuentra la
            // bandera ya puesta, en lugar de pisar el motivo y el autor del
            // primero.
            var lote = await _db.Lotes
                .FromSqlInterpolated(
                    $"SELECT * FROM Lote WITH (UPDLOCK, HOLDLOCK) WHERE IdLote = {idLote}")
                .FirstOrDefaultAsync(ct)
                ?? throw new ReglaNegocioException("El ingreso indicado no existe.");

            if (lote.Anulado)
                throw new ReglaNegocioException("Este ingreso ya estaba anulado.");

            // Un lote del que ya salió todo no aporta nada al inventario:
            // anularlo no cambiaría ni el stock ni la valuación, y en cambio lo
            // dejaría bloqueado para siempre. Lo que ya se entregó con un costo
            // equivocado se corrige anulando esas entregas, no el ingreso.
            if (lote.CantidadDisponible <= 0)
                throw new ReglaNegocioException(
                    "De este ingreso ya salió todo, así que anularlo no cambiaría el " +
                    "inventario ni el valor del stock. Si alguna entrega quedó con un " +
                    "monto equivocado, anule esa entrega desde su propia pantalla.");

            var anterior = Instantanea(lote);
            var retiradas = lote.CantidadDisponible;

            lote.Anulado = true;
            lote.MotivoAnulacion = texto;
            lote.FechaAnulacion = DateTime.Now;
            lote.IdUsuarioAnulacion = idUsuario;

            await _db.SaveChangesAsync(ct);

            await _bitacora.RegistrarAsync(
                idUsuario, "Lote", lote.IdLote, "UPDATE", anterior, Instantanea(lote), ct);

            await tx.CommitAsync(ct);

            _log.LogWarning(
                "Ingreso {Lote} anulado por el usuario {Usuario}: salen del inventario {Cantidad} " +
                "unidades por {Valor} Bs. Motivo: {Motivo}",
                lote.IdLote, idUsuario, retiradas, retiradas * lote.CostoUnitario, texto);

            return lote;
        }
        catch
        {
            await tx.RevertirSinFallarAsync();
            _db.ChangeTracker.Clear();
            throw;
        }
    }

    /// <summary>Reglas que valen tanto para un ingreso nuevo como para su corrección.</summary>
    private static void ValidarDatosLote(Lote lote)
    {
        if (lote.FechaIngreso.Date > DateTime.Today)
            throw new ReglaNegocioException(
                "La fecha de ingreso no puede ser posterior a hoy: un lote que todavía " +
                "no llegó no puede entregarse.");

        if (lote.FechaIngreso.Date < IngresoMinimo)
            throw new ReglaNegocioException(
                $"La fecha de ingreso no puede ser anterior a {IngresoMinimo:dd/MM/yyyy}. Revise el año.");

        if (lote.FechaVencimiento.HasValue && lote.FechaVencimiento.Value.Date <= lote.FechaIngreso.Date)
            throw new ReglaNegocioException(
                "El vencimiento debe ser posterior a la fecha de ingreso.");

        if (lote.CantidadIngresada <= 0)
            throw new ReglaNegocioException("La cantidad debe ser mayor que cero.");

        if (lote.CostoUnitario < 0)
            throw new ReglaNegocioException("El costo no puede ser negativo.");
    }

    /// <summary>Instantánea del lote para la bitácora.</summary>
    private static object Instantanea(Lote l) => new
    {
        l.IdMedicamento,
        l.IdTipoIngreso,
        l.NumeroLote,
        l.FechaIngreso,
        l.FechaVencimiento,
        l.CantidadIngresada,
        l.CantidadDisponible,
        l.CostoUnitario,
        l.Origen,
        l.NumeroFactura,
        l.Anulado,
        l.MotivoAnulacion
    };
}

/// <summary>Una línea de la simulación FIFO.</summary>
public record RepartoLote(
    int IdLote,
    string? NumeroLote,
    DateTime FechaIngreso,
    string TipoIngreso,
    decimal Cantidad,
    decimal CostoUnitario,
    decimal Subtotal);
