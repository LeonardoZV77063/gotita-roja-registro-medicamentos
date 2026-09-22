using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Data;
using SistemaDonaciones.Web.Models.Entidades;
using SistemaDonaciones.Web.Models.ViewModels;
using SistemaDonaciones.Web.Servicios;
using SistemaDonaciones.Web.Infraestructura;

namespace SistemaDonaciones.Web.Controllers;

/// <summary>
/// Usuarios, catálogos y bitácora. Reservado al rol Administrador.
///
/// Los catálogos se administran desde la aplicación para no depender de cambios
/// directos en la base de datos.
/// </summary>
[Authorize(Roles = Rol.Administrador)]
public class AdministracionController : Controller
{

    private readonly ServicioBitacora _bitacora;
    private readonly AppDbContext _db;
    private readonly ServicioContrasenas _contrasenas;

    public AdministracionController(
    AppDbContext db,
    ServicioContrasenas contrasenas,
    ServicioBitacora bitacora)
    {
        _db = db;
        _contrasenas = contrasenas;
        _bitacora = bitacora;
    }

    // Usuarios

    [HttpGet]
    public async Task<IActionResult> Usuarios(CancellationToken ct) =>
        View(await _db.Usuarios
            .AsNoTracking()
            .Include(u => u.Rol)
            .OrderBy(u => u.NombreCompleto)
            .ToListAsync(ct));

    [HttpGet]
    public async Task<IActionResult> UsuarioForm(int? id, CancellationToken ct)
    {
        ViewBag.Roles = await _db.Roles.AsNoTracking().ToListAsync(ct);

        if (id is null) return View(new UsuarioFormViewModel());

        var usuario = await _db.Usuarios
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.IdUsuario == id, ct);

        if (usuario is null) return NotFound();

        return View(new UsuarioFormViewModel
        {
            IdUsuario = usuario.IdUsuario,
            NombreUsuario = usuario.NombreUsuario,
            NombreCompleto = usuario.NombreCompleto,
            Email = usuario.Email,
            IdRol = usuario.IdRol,
            Activo = usuario.Activo
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UsuarioForm(UsuarioFormViewModel modelo, CancellationToken ct)
    {
        if (modelo.EsNuevo && string.IsNullOrWhiteSpace(modelo.Contrasena))
            ModelState.AddModelError(nameof(modelo.Contrasena),
                "Defina una contraseña inicial.");

        // Un rol inexistente terminaba en la violación de FK_Usuario_Rol.
        if (ModelState.GetFieldValidationState(nameof(modelo.IdRol)) != Microsoft.AspNetCore.Mvc.ModelBinding.ModelValidationState.Invalid
            && !await _db.Roles.AnyAsync(r => r.IdRol == modelo.IdRol, ct))
            ModelState.AddModelError(nameof(modelo.IdRol), "Seleccione un rol.");

        if (!ModelState.IsValid)
        {
            ViewBag.Roles = await _db.Roles.AsNoTracking().ToListAsync(ct);
            return View(modelo);
        }

        var nombreEnUso = await _db.Usuarios.AnyAsync(
            u => u.NombreUsuario == modelo.NombreUsuario && u.IdUsuario != modelo.IdUsuario, ct);

        if (nombreEnUso)
        {
            ModelState.AddModelError(nameof(modelo.NombreUsuario),
                "Ese nombre de usuario ya está en uso.");
            ViewBag.Roles = await _db.Roles.AsNoTracking().ToListAsync(ct);
            return View(modelo);
        }

        if (modelo.EsNuevo)
        {
            var usuario = new Usuario
            {
                NombreUsuario = modelo.NombreUsuario.Trim(),
                NombreCompleto = modelo.NombreCompleto.Trim(),
                Email = string.IsNullOrWhiteSpace(modelo.Email)
                    ? null
                    : modelo.Email.Trim(),

                IdRol = modelo.IdRol,
                Activo = modelo.Activo,

                HashContrasena =
                    _contrasenas.Derivar(modelo.Contrasena!)
            };

            _db.Usuarios.Add(usuario);

            await _db.SaveChangesAsync(ct);

            await _bitacora.RegistrarAsync(
                User.IdUsuario(),
                "Usuario",
                usuario.IdUsuario,
                "INSERT",
                null,
                new
                {
                    usuario.NombreUsuario,
                    usuario.NombreCompleto,
                    usuario.Email,
                    usuario.IdRol,
                    usuario.Activo
                },
                ct);
        }
        else
        {
            var usuario = await _db.Usuarios.FindAsync(
                new object?[] { modelo.IdUsuario },
                ct);

            if (usuario is null)
                return NotFound();

            var anterior = new
            {
                usuario.NombreUsuario,
                usuario.NombreCompleto,
                usuario.Email,
                usuario.IdRol,
                usuario.Activo
            };

            usuario.NombreUsuario =
                modelo.NombreUsuario.Trim();

            usuario.NombreCompleto =
                modelo.NombreCompleto.Trim();

            usuario.Email =
                string.IsNullOrWhiteSpace(modelo.Email)
                    ? null
                    : modelo.Email.Trim();

            usuario.IdRol =
                modelo.IdRol;

            usuario.Activo =
                modelo.Activo;

            if (!string.IsNullOrWhiteSpace(modelo.Contrasena))
            {
                usuario.HashContrasena =
                    _contrasenas.Derivar(modelo.Contrasena);
            }

            await _db.SaveChangesAsync(ct);

            await _bitacora.RegistrarAsync(
                User.IdUsuario(),
                "Usuario",
                usuario.IdUsuario,
                "UPDATE",
                anterior,
                new
                {
                    usuario.NombreUsuario,
                    usuario.NombreCompleto,
                    usuario.Email,
                    usuario.IdRol,
                    usuario.Activo
                },
                ct);
        }

        TempData["Exito"] = "Los datos del usuario fueron guardados.";
        return RedirectToAction(nameof(Usuarios));
    }

    // Catálogos

    [HttpGet]
    public async Task<IActionResult> Catalogos(CancellationToken ct)
    {
        ViewBag.Condiciones = await _db.CondicionesAtencion
            .AsNoTracking().OrderBy(c => c.Descripcion).ToListAsync(ct);

        ViewBag.Establecimientos = await _db.Establecimientos
            .AsNoTracking().OrderBy(e => e.Nombre).ToListAsync(ct);

        ViewBag.Unidades = await _db.UnidadesMedida
            .AsNoTracking().OrderBy(u => u.Descripcion).ToListAsync(ct);

        ViewBag.TiposIngreso = await _db.TiposIngreso
            .AsNoTracking().OrderBy(t => t.Descripcion).ToListAsync(ct);

        ViewBag.Diagnosticos = await _db.Diagnosticos
            .AsNoTracking().OrderBy(d => d.Descripcion).ToListAsync(ct);

        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AgregarCondicion(string? descripcion, CancellationToken ct)
    {
        var texto = Limpiar(descripcion);

        if (texto is null)
        {
            TempData["Error"] = "Escriba el nombre de la condición que quiere agregar.";
            return RedirectToAction(nameof(Catalogos));
        }

        if (texto.Length > 40)
        {
            TempData["Error"] = "El nombre de la condición admite como máximo 40 caracteres.";
            return RedirectToAction(nameof(Catalogos));
        }

        if (await _db.CondicionesAtencion.AnyAsync(c => c.Descripcion == texto, ct))
        {
            TempData["Error"] = $"La condición «{texto}» ya existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        var condicion = new CondicionAtencion { Descripcion = texto, Activo = true };
        _db.CondicionesAtencion.Add(condicion);

        try
        {
            await _db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ErroresBaseDatos.EsDuplicado(ex))
        {
            TempData["Error"] = $"La condición «{texto}» ya existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "CondicionAtencion",
            condicion.IdCondicion,
            "INSERT",
            null,
            new { condicion.Descripcion, condicion.Activo },
            ct);

        TempData["Exito"] = $"Se agregó la condición «{texto}».";
        return RedirectToAction(nameof(Catalogos));
    }
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AgregarDiagnostico(
    string? descripcion,
    string? codigoCie10,
    CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(descripcion))
        {
            TempData["Error"] = "Escriba el diagnóstico.";
            return RedirectToAction(nameof(Catalogos));
        }

        var texto = Limpiar(descripcion)!;

        if (texto.Length > 160 || (codigoCie10?.Trim().Length ?? 0) > 10)
        {
            TempData["Error"] = "El diagnóstico admite hasta 160 caracteres y el código CIE-10 hasta 10.";
            return RedirectToAction(nameof(Catalogos));
        }

        var yaExiste = await _db.Diagnosticos
            .AnyAsync(d => d.Descripcion == texto, ct);

        if (yaExiste)
        {
            TempData["Error"] = "Ese diagnóstico ya existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        var diagnostico = new Diagnostico
        {
            Descripcion = texto,
            CodigoCie10 = string.IsNullOrWhiteSpace(codigoCie10)
                ? null
                : codigoCie10.Trim().ToUpperInvariant(),
            Activo = true
        };

        _db.Diagnosticos.Add(diagnostico);
        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "Diagnostico",
            diagnostico.IdDiagnostico,
            "INSERT",
            null,
            new
            {
                diagnostico.Descripcion,
                diagnostico.CodigoCie10,
                diagnostico.Activo
            },
            ct);

        TempData["Exito"] =
            $"Se agregó el diagnóstico «{texto}».";

        return RedirectToAction(nameof(Catalogos));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AgregarUnidad(
        string? descripcion, string? abreviatura, CancellationToken ct)
    {
        var texto = Limpiar(descripcion);
        var abrev = Limpiar(abreviatura);

        if (texto is null || abrev is null)
        {
            TempData["Error"] = "Escriba el nombre de la unidad y su abreviatura.";
            return RedirectToAction(nameof(Catalogos));
        }

        if (texto.Length > 40 || abrev.Length > 10)
        {
            TempData["Error"] = "El nombre admite hasta 40 caracteres y la abreviatura hasta 10.";
            return RedirectToAction(nameof(Catalogos));
        }

        if (await _db.UnidadesMedida.AnyAsync(u => u.Descripcion == texto, ct))
        {
            TempData["Error"] = $"La unidad «{texto}» ya existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        var unidad = new UnidadMedida { Descripcion = texto, Abreviatura = abrev };
        _db.UnidadesMedida.Add(unidad);

        try
        {
            await _db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ErroresBaseDatos.EsDuplicado(ex))
        {
            TempData["Error"] = $"La unidad «{texto}» ya existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "UnidadMedida",
            unidad.IdUnidadMedida,
            "INSERT",
            null,
            new { unidad.Descripcion, unidad.Abreviatura },
            ct);

        TempData["Exito"] = $"Se agregó la unidad «{texto}».";
        return RedirectToAction(nameof(Catalogos));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AlternarEstablecimiento(int id, CancellationToken ct)
    {
        var establecimiento = await _db.Establecimientos.FindAsync(new object?[] { id }, ct);
        if (establecimiento is null)
        {
            TempData["Error"] = "El establecimiento indicado no existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        var anterior = new { establecimiento.Nombre, establecimiento.Activo };
        establecimiento.Activo = !establecimiento.Activo;
        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "Establecimiento",
            establecimiento.IdEstablecimiento,
            "UPDATE",
            anterior,
            new { establecimiento.Nombre, establecimiento.Activo },
            ct);

        TempData["Exito"] = establecimiento.Activo
            ? $"«{establecimiento.Nombre}» vuelve a aparecer en las sugerencias."
            : $"«{establecimiento.Nombre}» quedó desactivado.";

        return RedirectToAction(nameof(Catalogos));
    }

    /// <summary>Recorta y deja un solo espacio entre palabras; null si queda vacío.</summary>
    private static string? Limpiar(string? texto) =>
        string.IsNullOrWhiteSpace(texto)
            ? null
            : System.Text.RegularExpressions.Regex.Replace(texto.Trim(), @"\s+", " ");

    // Bitácora

    /// <summary>
    /// Historial de cambios escrito por los triggers y los servicios de la
    /// aplicación.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Bitacora(int pagina = 1, CancellationToken ct = default)
    {
        const int porPagina = 50;

        var total = await _db.Bitacoras.CountAsync(ct);

        var registros = await _db.Bitacoras
            .AsNoTracking()
            .Include(b => b.Usuario)
            .OrderByDescending(b => b.IdBitacora)
            .Skip((Math.Max(1, pagina) - 1) * porPagina)
            .Take(porPagina)
            .ToListAsync(ct);

        ViewBag.Pagina = pagina;
        ViewBag.TotalPaginas = Math.Max(1, (int)Math.Ceiling(total / (double)porPagina));
        ViewBag.Total = total;

        return View(registros);
    }
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditarDiagnostico(
    int idDiagnostico,
    string? descripcion,
    string? codigoCie10,
    CancellationToken ct)
    {
        var diagnostico = await _db.Diagnosticos
            .FirstOrDefaultAsync(
                d => d.IdDiagnostico == idDiagnostico,
                ct);

        if (diagnostico is null)
        {
            TempData["Error"] = "El diagnóstico no existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        if (string.IsNullOrWhiteSpace(descripcion))
        {
            TempData["Error"] = "La descripción es obligatoria.";
            return RedirectToAction(nameof(Catalogos));
        }

        var nuevaDescripcion = Limpiar(descripcion)!;

        if (nuevaDescripcion.Length > 160 || (codigoCie10?.Trim().Length ?? 0) > 10)
        {
            TempData["Error"] = "El diagnóstico admite hasta 160 caracteres y el código CIE-10 hasta 10.";
            return RedirectToAction(nameof(Catalogos));
        }

        var repetido = await _db.Diagnosticos.AnyAsync(
            d => d.IdDiagnostico != idDiagnostico
                 && d.Descripcion == nuevaDescripcion,
            ct);

        if (repetido)
        {
            TempData["Error"] =
                "Ya existe otro diagnóstico con esa descripción.";

            return RedirectToAction(nameof(Catalogos));
        }

        var anterior = new
        {
            diagnostico.Descripcion,
            diagnostico.CodigoCie10,
            diagnostico.Activo
        };

        diagnostico.Descripcion = nuevaDescripcion;

        diagnostico.CodigoCie10 =
            string.IsNullOrWhiteSpace(codigoCie10)
                ? null
                : codigoCie10.Trim().ToUpperInvariant();

        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "Diagnostico",
            diagnostico.IdDiagnostico,
            "UPDATE",
            anterior,
            new
            {
                diagnostico.Descripcion,
                diagnostico.CodigoCie10,
                diagnostico.Activo
            },
            ct);

        TempData["Exito"] =
            "Diagnóstico actualizado correctamente.";

        return RedirectToAction(nameof(Catalogos));
    }
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CambiarEstadoDiagnostico(
    int idDiagnostico,
    CancellationToken ct)
    {
        var diagnostico = await _db.Diagnosticos
            .FirstOrDefaultAsync(
                d => d.IdDiagnostico == idDiagnostico,
                ct);

        if (diagnostico is null)
        {
            TempData["Error"] = "El diagnóstico no existe.";
            return RedirectToAction(nameof(Catalogos));
        }

        var anterior = new
        {
            diagnostico.Descripcion,
            diagnostico.CodigoCie10,
            diagnostico.Activo
        };

        diagnostico.Activo = !diagnostico.Activo;

        await _db.SaveChangesAsync(ct);

        await _bitacora.RegistrarAsync(
            User.IdUsuario(),
            "Diagnostico",
            diagnostico.IdDiagnostico,
            "UPDATE",
            anterior,
            new
            {
                diagnostico.Descripcion,
                diagnostico.CodigoCie10,
                diagnostico.Activo
            },
            ct);

        TempData["Exito"] =
            diagnostico.Activo
                ? "Diagnóstico activado."
                : "Diagnóstico desactivado.";

        return RedirectToAction(nameof(Catalogos));
    }

    [HttpGet]
    public IActionResult Backups([FromServices] ServicioBackup servicioBackup)
    {
        var lista = servicioBackup.ObtenerBackupsExistentes();
        return View(lista);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CrearBackupManual([FromServices] ServicioBackup servicioBackup)
    {
        var exito = await servicioBackup.RealizarBackupAsync();
        if (exito)
        {
            TempData["Exito"] = "Copia de seguridad creada correctamente.";
        }
        else
        {
            TempData["Error"] = "No se pudo crear la copia de seguridad. Revise el registro del servidor.";
        }

        return RedirectToAction(nameof(Backups));
    }
}
