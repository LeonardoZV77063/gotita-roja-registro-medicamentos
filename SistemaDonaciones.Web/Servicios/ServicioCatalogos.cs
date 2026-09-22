using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Infraestructura;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Servicios;

/// <summary>
/// Normaliza los textos que la usuaria escribe libremente (medicamento,
/// diagnóstico, establecimiento) contra sus tablas de catálogo.
///
/// Los catálogos admiten texto nuevo sin perder normalización: el sistema busca
/// o crea la fila correspondiente para mantener consistentes las estadísticas y
/// el inventario.
/// </summary>
public class ServicioCatalogos
{
    private readonly AppDbContext _db;
    private readonly ServicioBitacora _bitacora;
    public ServicioCatalogos(
    AppDbContext db,
    ServicioBitacora bitacora)
    {
        _db = db;
        _bitacora = bitacora;
    }

    /// <summary>
    /// Busca un medicamento por nombre: primero la coincidencia exacta y, si no
    /// hay, la que sólo difiere en mayúsculas o tildes («ONDANSETRON» →
    /// «Ondansetrón»). Así el texto escrito sin tilde no crea un medicamento
    /// duplicado con su propio stock vacío.
    /// </summary>
    public async Task<Medicamento?> BuscarMedicamentoAsync(
        string? nombre, CancellationToken ct = default)
    {
        var limpio = Normalizar(nombre);
        if (limpio is null) return null;

        return await _db.Medicamentos.FirstOrDefaultAsync(m => m.Nombre == limpio, ct)
               ?? await _db.Medicamentos
                   .OrderByDescending(m => m.Activo)
                   .ThenBy(m => m.IdMedicamento)
                   .FirstOrDefaultAsync(m =>
                       EF.Functions.Collate(m.Nombre, CriterioBusqueda.Colacion) == limpio, ct);
    }

    /// <summary>
    /// Devuelve el medicamento con ese nombre, creándolo si es la primera vez
    /// que aparece. La comparación ignora mayúsculas, tildes y espacios sobrantes.
    /// </summary>
    public async Task<Medicamento> ObtenerOCrearMedicamentoAsync(
    string nombre,
    int idUsuario,
    CancellationToken ct = default)
    {
        var limpio = Normalizar(nombre)
            ?? throw new ArgumentException("El nombre del medicamento es obligatorio.");

        if (limpio.Length > 120)
            throw new ArgumentException("El nombre del medicamento admite como máximo 120 caracteres.");

        var existente = await BuscarMedicamentoAsync(limpio, ct);

        if (existente is not null)
        {
            // Un medicamento dado de baja que vuelve a aparecer se reactiva.
            if (!existente.Activo)
            {
                existente.Activo = true;
                await _db.SaveChangesAsync(ct);

            }


            return existente;
        }

        var nuevo = new Medicamento
        {
            Nombre = limpio,
            Activo = true,
            FechaAlta = DateTime.Now
        };

        _db.Medicamentos.Add(nuevo);
        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            idUsuario,
            "Medicamento",
            nuevo.IdMedicamento,
            "INSERT",
            null,
            new
            {
                nuevo.Nombre,
                nuevo.Activo
            },
            ct);

        return nuevo;
    }
   

    /// <summary>Ídem para el hospital de procedencia, que es opcional.</summary>
    public async Task<Establecimiento?> ObtenerOCrearEstablecimientoAsync(
        string? nombre, CancellationToken ct = default)
    {
        var limpio = Normalizar(nombre);
        if (limpio is null) return null;

        if (limpio.Length > 120)
            throw new ArgumentException("El nombre del establecimiento admite como máximo 120 caracteres.");

        var existente = await _db.Establecimientos.FirstOrDefaultAsync(e => e.Nombre == limpio, ct)
                        ?? await _db.Establecimientos
                            .OrderByDescending(e => e.Activo)
                            .ThenBy(e => e.IdEstablecimiento)
                            .FirstOrDefaultAsync(e =>
                                EF.Functions.Collate(e.Nombre, CriterioBusqueda.Colacion) == limpio, ct);

        if (existente is not null)
        {
            if (!existente.Activo)
            {
                existente.Activo = true;
                await _db.SaveChangesAsync(ct);
            }
            return existente;
        }

        var nuevo = new Establecimiento { Nombre = limpio, Activo = true };
        _db.Establecimientos.Add(nuevo);
        await _db.SaveChangesAsync(ct);
        return nuevo;
    }

    /// <summary>
    /// Asigna el siguiente número de formulario. La numeración es anual y
    /// correlativa (2026-0001, 2026-0002…).
    /// </summary>
    public async Task<string> SugerirNumeroFormularioAsync(CancellationToken ct = default)
    {
        var anio = DateTime.Today.Year;
        var prefijo = $"{anio}-";

        // Se leen todos los números del año y se busca el mayor que sea
        // realmente numérico. Tomar sólo el último por orden alfabético fallaba
        // si en la base quedaba algún número con formato distinto —cargado a
        // mano o importado—: el TryParse no lo entendía, el correlativo volvía a
        // 1 y el alta chocaba contra UQ_Atencion_Formulario.
        var numerosDelAnio = await _db.Atenciones
            .Where(a => a.NumeroFormulario.StartsWith(prefijo))
            .Select(a => a.NumeroFormulario)
            .ToListAsync(ct);

        var ultimoNumero = numerosDelAnio
            .Select(n => int.TryParse(n[prefijo.Length..], out var v) ? v : 0)
            .DefaultIfEmpty(0)
            .Max();

        return $"{prefijo}{ultimoNumero + 1:0000}";
    }

    /// <summary>Nombres de medicamentos para el autocompletado del formulario.</summary>
    public Task<List<string>> SugerirMedicamentosAsync(
        string termino, int maximo = 10, CancellationToken ct = default)
    {
        var patrones = PatronesSugerencia(termino);
        if (patrones is null) return Task.FromResult(new List<string>());

        var consulta = _db.Medicamentos.AsNoTracking().Where(m => m.Activo);

        foreach (var patron in patrones)
            consulta = consulta.Where(m => EF.Functions.Like(
                EF.Functions.Collate(m.Nombre, CriterioBusqueda.Colacion),
                patron, CriterioBusqueda.CaracterEscape));

        return consulta
            .OrderBy(m => m.Nombre)
            .Take(maximo)
            .Select(m => m.Nombre)
            .ToListAsync(ct);
    }

    /// <summary>Ídem para diagnósticos.</summary>
    public Task<List<string>> SugerirDiagnosticosAsync(
        string termino, int maximo = 10, CancellationToken ct = default)
    {
        var patrones = PatronesSugerencia(termino);
        if (patrones is null) return Task.FromResult(new List<string>());

        var consulta = _db.Diagnosticos.AsNoTracking().Where(d => d.Activo);

        foreach (var patron in patrones)
            consulta = consulta.Where(d => EF.Functions.Like(
                EF.Functions.Collate(d.Descripcion, CriterioBusqueda.Colacion),
                patron, CriterioBusqueda.CaracterEscape));

        return consulta
            .OrderBy(d => d.Descripcion)
            .Take(maximo)
            .Select(d => d.Descripcion)
            .ToListAsync(ct);
    }

    /// <summary>Ídem para establecimientos.</summary>
    public Task<List<string>> SugerirEstablecimientosAsync(
        string termino, int maximo = 10, CancellationToken ct = default)
    {
        var patrones = PatronesSugerencia(termino);
        if (patrones is null) return Task.FromResult(new List<string>());

        var consulta = _db.Establecimientos.AsNoTracking().Where(e => e.Activo);

        foreach (var patron in patrones)
            consulta = consulta.Where(e => EF.Functions.Like(
                EF.Functions.Collate(e.Nombre, CriterioBusqueda.Colacion),
                patron, CriterioBusqueda.CaracterEscape));

        return consulta
            .OrderBy(e => e.Nombre)
            .Take(maximo)
            .Select(e => e.Nombre)
            .ToListAsync(ct);
    }

    /// <summary>
    /// Patrones «contiene» para el autocompletado, uno por palabra. Devuelve
    /// null cuando el término no tiene nada buscable (un emoji): en ese caso no
    /// se sugiere nada, en lugar de sugerir toda la lista.
    /// </summary>
    private static List<string>? PatronesSugerencia(string? termino)
    {
        var limpio = CriterioBusqueda.Limpiar(termino);

        if (CriterioBusqueda.EsInvalido(termino, limpio))
            return null;

        return CriterioBusqueda.Palabras(limpio).Select(CriterioBusqueda.PatronContiene).ToList();
    }

    /// <summary>Quita espacios sobrantes; devuelve null si no queda nada.</summary>
    private static string? Normalizar(string? texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return null;
        return System.Text.RegularExpressions.Regex
            .Replace(texto.Trim(), @"\s+", " ");
    }
}
