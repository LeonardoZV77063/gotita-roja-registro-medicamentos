using Microsoft.EntityFrameworkCore;
using SistemaDonaciones.Web.Models.Entidades;

namespace SistemaDonaciones.Web.Data;

/// <summary>
/// Contexto Database First cuya fuente de verdad es
/// <c>BaseDeDatos/01-esquema.sql</c>.
///
/// No se usan migraciones de EF: el esquema incluye triggers, columnas
/// calculadas, índices filtrados y procedimientos mantenidos en SQL.
///
/// Las columnas booleanas con DEFAULT 1 no se configuran con
/// <c>HasDefaultValue(true)</c>: EF omitiría los valores <c>false</c> al insertar
/// y SQL terminaría guardándolos como activos.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // Catálogos
    public DbSet<Sexo> Sexos => Set<Sexo>();
    public DbSet<CondicionAtencion> CondicionesAtencion => Set<CondicionAtencion>();
    public DbSet<Establecimiento> Establecimientos => Set<Establecimiento>();
    public DbSet<Diagnostico> Diagnosticos => Set<Diagnostico>();
    public DbSet<UnidadMedida> UnidadesMedida => Set<UnidadMedida>();
    public DbSet<TipoIngreso> TiposIngreso => Set<TipoIngreso>();
    public DbSet<Pais> Paises => Set<Pais>();
    public DbSet<Departamento> Departamentos => Set<Departamento>();
    public DbSet<Provincia> Provincias => Set<Provincia>();
    public DbSet<Municipio> Municipios => Set<Municipio>();

    // Seguridad y auditoría
    public DbSet<Rol> Roles => Set<Rol>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Bitacora> Bitacoras => Set<Bitacora>();

    // Pacientes y atenciones
    public DbSet<ArchivoDigital> Archivos => Set<ArchivoDigital>();
    public DbSet<Paciente> Pacientes => Set<Paciente>();
    public DbSet<PacienteDocumento> PacienteDocumentos => Set<PacienteDocumento>();
    public DbSet<Medicamento> Medicamentos => Set<Medicamento>();
    public DbSet<Atencion> Atenciones => Set<Atencion>();
    public DbSet<AtencionDetalle> AtencionDetalles => Set<AtencionDetalle>();

    // Farmacia y exportaciones
    public DbSet<Lote> Lotes => Set<Lote>();
    public DbSet<ConsumoLote> ConsumosLote => Set<ConsumoLote>();
    public DbSet<RespaldoExportacion> Exportaciones => Set<RespaldoExportacion>();

    // Vistas y resultados de procedimientos (solo lectura)
    public DbSet<KardexMedicamento> Kardex => Set<KardexMedicamento>();
    public DbSet<ValorStock> ValoresStock => Set<ValorStock>();
    public DbSet<HistorialPaciente> HistorialesPaciente => Set<HistorialPaciente>();
    public DbSet<ResultadoBusquedaPaciente> BusquedaPacientes => Set<ResultadoBusquedaPaciente>();
    public DbSet<FilaReporteEstadistico> ReporteEstadistico => Set<FilaReporteEstadistico>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        ConfigurarCatalogos(mb);
        ConfigurarSeguridad(mb);
        ConfigurarArchivos(mb);
        ConfigurarPacientes(mb);
        ConfigurarAtenciones(mb);
        ConfigurarFarmacia(mb);
        ConfigurarConsultas(mb);

        // Se restringe el borrado en cascada salvo en la relación que SQL
        // declara explícitamente para los consumos de un detalle.
        foreach (var fk in mb.Model.GetEntityTypes()
                     .SelectMany(t => t.GetForeignKeys())
                     .Where(fk => !fk.IsOwnership && fk.DeleteBehavior == DeleteBehavior.Cascade))
        {
            if (fk.DeclaringEntityType.ClrType != typeof(ConsumoLote))
                fk.DeleteBehavior = DeleteBehavior.Restrict;
        }
    }

    /// <remarks>
    /// Las claves TINYINT (Sexo, CondicionAtencion, UnidadMedida, TipoIngreso y
    /// Rol) son IDENTITY en la base, pero EF Core sólo asume valores generados
    /// por convención en claves int, long, short y Guid. <c>UseIdentityColumn</c>
    /// evita que EF intente insertar el valor cero explícitamente.
    /// </remarks>
    private static void ConfigurarCatalogos(ModelBuilder mb)
    {
        mb.Entity<Sexo>(e =>
        {
            e.ToTable("Sexo");
            e.HasKey(x => x.IdSexo);
            e.Property(x => x.IdSexo).UseIdentityColumn();
            e.Property(x => x.Descripcion).HasMaxLength(20).IsRequired();
            e.HasIndex(x => x.Descripcion).IsUnique();
        });

        mb.Entity<CondicionAtencion>(e =>
        {
            e.ToTable("CondicionAtencion");
            e.HasKey(x => x.IdCondicion);
            e.Property(x => x.IdCondicion).UseIdentityColumn();
            e.Property(x => x.Descripcion).HasMaxLength(40).IsRequired();
            e.HasIndex(x => x.Descripcion).IsUnique();
        });

        mb.Entity<Establecimiento>(e =>
        {
            e.ToTable("Establecimiento");
            e.HasKey(x => x.IdEstablecimiento);
            e.Property(x => x.Nombre).HasMaxLength(120).IsRequired();
            e.HasIndex(x => x.Nombre).IsUnique();
        });

        mb.Entity<Diagnostico>(e =>
        {
            e.ToTable("Diagnostico");
            e.HasKey(x => x.IdDiagnostico);
            e.Property(x => x.Descripcion).HasMaxLength(160).IsRequired();
            e.Property(x => x.CodigoCie10).HasMaxLength(10).IsUnicode(false);
            e.HasIndex(x => x.Descripcion).IsUnique();
        });

        mb.Entity<UnidadMedida>(e =>
        {
            e.ToTable("UnidadMedida");
            e.HasKey(x => x.IdUnidadMedida);
            e.Property(x => x.IdUnidadMedida).UseIdentityColumn();
            e.Property(x => x.Descripcion).HasMaxLength(40).IsRequired();
            e.Property(x => x.Abreviatura).HasMaxLength(10).IsRequired();
            e.HasIndex(x => x.Descripcion).IsUnique();
        });

        mb.Entity<TipoIngreso>(e =>
        {
            e.ToTable("TipoIngreso");
            e.HasKey(x => x.IdTipoIngreso);
            e.Property(x => x.IdTipoIngreso).UseIdentityColumn();
            e.Property(x => x.Descripcion).HasMaxLength(40).IsRequired();
            e.HasIndex(x => x.Descripcion).IsUnique();
        });
        mb.Entity<Pais>(e =>
        {
            e.ToTable("Pais");
            e.HasKey(x => x.IdPais);
            e.Property(x => x.Nombre).HasMaxLength(60).IsRequired();

            // No configurar los DEFAULT de Activo y EsLocal; véase la cabecera.

            e.HasIndex(x => x.Nombre).IsUnique().HasDatabaseName("UQ_Pais_Nombre");

            // Un solo país local: índice único filtrado, igual que en la base.
            e.HasIndex(x => x.EsLocal)
             .IsUnique()
             .HasFilter("[EsLocal] = 1")
             .HasDatabaseName("UX_Pais_Local");
        });

        mb.Entity<Departamento>(e =>
        {
            e.ToTable("Departamento");
            e.HasKey(x => x.IdDepartamento);

            e.Property(x => x.Nombre)
                .HasMaxLength(80)
                .IsRequired();

            e.HasIndex(x => x.Nombre)
                .IsUnique();
        });

        mb.Entity<Provincia>(e =>
        {
            e.ToTable("Provincia");
            e.HasKey(x => x.IdProvincia);

            e.Property(x => x.Nombre)
                .HasMaxLength(100)
                .IsRequired();

            e.HasOne(x => x.Departamento)
                .WithMany(d => d.Provincias)
                .HasForeignKey(x => x.IdDepartamento)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => new
            {
                x.IdDepartamento,
                x.Nombre
            }).IsUnique();
        });

        mb.Entity<Municipio>(e =>
        {
            e.ToTable("Municipio");
            e.HasKey(x => x.IdMunicipio);

            e.Property(x => x.Nombre)
                .HasMaxLength(100)
                .IsRequired();

            e.HasOne(x => x.Provincia)
                .WithMany(p => p.Municipios)
                .HasForeignKey(x => x.IdProvincia)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(x => new
            {
                x.IdProvincia,
                x.Nombre
            }).IsUnique();
        });
    }

    private static void ConfigurarSeguridad(ModelBuilder mb)
    {
        mb.Entity<Rol>(e =>
        {
            e.ToTable("Rol");
            e.HasKey(x => x.IdRol);
            e.Property(x => x.IdRol).UseIdentityColumn();
            e.Property(x => x.Nombre).HasMaxLength(40).IsRequired();
            e.Property(x => x.Descripcion).HasMaxLength(160);
            e.HasIndex(x => x.Nombre).IsUnique();
        });

        mb.Entity<Usuario>(e =>
        {
            e.ToTable("Usuario");
            e.HasKey(x => x.IdUsuario);
            e.Property(x => x.NombreUsuario).HasMaxLength(60).IsRequired();
            e.Property(x => x.NombreCompleto).HasMaxLength(120).IsRequired();
            e.Property(x => x.Email).HasMaxLength(120);
            e.Property(x => x.HashContrasena).HasColumnType("varbinary(256)").IsRequired();
            e.Property(x => x.UltimoAcceso).HasColumnType("datetime2(0)");
            e.HasIndex(x => x.NombreUsuario).IsUnique();

            e.HasOne(x => x.Rol)
             .WithMany(r => r.Usuarios)
             .HasForeignKey(x => x.IdRol)
             .OnDelete(DeleteBehavior.Restrict);
        });

        mb.Entity<Bitacora>(e =>
        {
            e.ToTable("Bitacora");
            e.HasKey(x => x.IdBitacora);
            // SYSNAME en SQL Server equivale a nvarchar(128) NOT NULL.
            e.Property(x => x.TablaAfectada).HasColumnType("sysname").IsRequired();
            e.Property(x => x.Accion).HasColumnType("char(6)").IsRequired();
            e.Property(x => x.DireccionIp).HasMaxLength(45).IsUnicode(false);
            e.Property(x => x.FechaHora)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.HasOne(x => x.Usuario)
             .WithMany()
             .HasForeignKey(x => x.IdUsuario)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigurarArchivos(ModelBuilder mb)
    {
        mb.Entity<ArchivoDigital>(e =>
        {
            e.ToTable("ArchivoDigital");
            e.HasKey(x => x.IdArchivo);
            e.Property(x => x.NombreOriginal).HasMaxLength(255).IsRequired();
            e.Property(x => x.RutaAlmacenamiento).HasMaxLength(500).IsRequired();
            e.Property(x => x.TipoMime).HasMaxLength(100).IsUnicode(false).IsRequired();
            e.Property(x => x.HashSha256).HasColumnType("binary(32)").IsRequired();
            e.Property(x => x.FechaCarga)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            // Un mismo contenido no se almacena dos veces.
            e.HasIndex(x => x.HashSha256).IsUnique();

            e.HasOne(x => x.UsuarioCarga)
             .WithMany()
             .HasForeignKey(x => x.IdUsuarioCarga)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigurarPacientes(ModelBuilder mb)
    {
        mb.Entity<Paciente>(e =>
        {
            e.ToTable("Paciente");
            e.HasKey(x => x.IdPaciente);
            e.Property(x => x.NumeroDocumento).HasMaxLength(20).IsUnicode(false).IsRequired();
            e.Property(x => x.ComplementoDoc).HasMaxLength(5).IsUnicode(false);
            e.Property(x => x.ExtensionDoc).HasMaxLength(5).IsUnicode(false);
            e.Property(x => x.Nombres).HasMaxLength(80).IsRequired();
            e.Property(x => x.ApellidoPaterno).HasMaxLength(60).IsRequired();
            e.Property(x => x.ApellidoMaterno).HasMaxLength(60);
            e.Property(x => x.FechaNacimiento).HasColumnType("date");
            e.Property(x => x.Telefono).HasMaxLength(20).IsUnicode(false);
            e.Property(x => x.Direccion)
             .HasMaxLength(250);
            e.Property(x => x.Observaciones).HasMaxLength(400);
            e.Property(x => x.FechaRegistro)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");


            // Se resuelven en memoria a partir de las dos ubicaciones ya
            // cargadas; no son columnas ni relaciones de la base.
            e.Ignore(x => x.MunicipioProcedencia);
            e.Ignore(x => x.OrigenSupuesto);
            e.Ignore(x => x.EsDelExterior);

            // Columna calculada NO persistida: se recalcula en cada lectura, así
            // la edad nunca queda vieja. EF la lee pero jamás la escribe.
            e.Property(x => x.Edad)
             .HasComputedColumnSql(
                 "DATEDIFF(YEAR, FechaNacimiento, GETDATE()) - CASE WHEN (MONTH(FechaNacimiento) > MONTH(GETDATE())) " +
                 "OR (MONTH(FechaNacimiento) = MONTH(GETDATE()) AND DAY(FechaNacimiento) > DAY(GETDATE())) THEN 1 ELSE 0 END",
                 stored: false)
             .ValueGeneratedOnAddOrUpdate();

            e.HasIndex(x => new { x.NumeroDocumento, x.ComplementoDoc })
             .IsUnique()
             .HasDatabaseName("IX_Paciente_Documento");

            e.HasIndex(x => new { x.ApellidoPaterno, x.ApellidoMaterno, x.Nombres })
             .HasDatabaseName("IX_Paciente_Apellidos");

            e.Property(x => x.Zona).HasMaxLength(120);
            e.Property(x => x.Calle).HasMaxLength(120);
            e.Property(x => x.NumeroDomicilio).HasMaxLength(20);

            e.HasIndex(x => x.IdMunicipioOrigen)
             .HasDatabaseName("IX_Paciente_MunicipioOrigen");

            e.HasIndex(x => x.IdPaisOrigen)
             .HasDatabaseName("IX_Paciente_PaisOrigen");

            e.HasOne(x => x.Sexo)
             .WithMany(s => s.Pacientes)
             .HasForeignKey(x => x.IdSexo)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Municipio)
             .WithMany(m => m.Pacientes)
             .HasForeignKey(x => x.IdMunicipio)
             .OnDelete(DeleteBehavior.Restrict);

            // Segunda relación con Municipio: el lugar de origen. Va sin
            // colección inversa porque Municipio.Pacientes ya significa
            // «los que viven acá».
            e.HasOne(x => x.MunicipioOrigen)
             .WithMany()
             .HasForeignKey(x => x.IdMunicipioOrigen)
             .OnDelete(DeleteBehavior.Restrict);

            // País de origen: para un paciente del exterior es todo lo que se
            // registra de su procedencia.
            e.HasOne(x => x.PaisOrigen)
             .WithMany(p => p.Pacientes)
             .HasForeignKey(x => x.IdPaisOrigen)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.UsuarioRegistro)
             .WithMany()
             .HasForeignKey(x => x.IdUsuarioRegistro)
             .OnDelete(DeleteBehavior.Restrict);
        });

        mb.Entity<PacienteDocumento>(e =>
        {
            e.ToTable("PacienteDocumento");
            e.HasKey(x => x.IdPacienteDocumento);
            e.Property(x => x.FechaRegistro)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.HasIndex(x => x.IdArchivo).IsUnique();

            // Índice filtrado: un solo carnet vigente por paciente.
            e.HasIndex(x => x.IdPaciente)
             .IsUnique()
             .HasFilter("[Vigente] = 1")
             .HasDatabaseName("IX_PacDoc_UnicoVigente");

            e.HasOne(x => x.Paciente)
             .WithMany(p => p.Documentos)
             .HasForeignKey(x => x.IdPaciente)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Archivo)
             .WithMany()
             .HasForeignKey(x => x.IdArchivo)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigurarAtenciones(ModelBuilder mb)
    {
        mb.Entity<Atencion>(e =>
        {
            // La tabla tiene triggers (auditoría e impedir borrado). Sin este
            // aviso, EF genera INSERT … OUTPUT INSERTED, que SQL Server rechaza
            // sobre tablas con triggers habilitados.
            e.ToTable("Atencion", tb =>
            {
                tb.HasTrigger("TR_Atencion_Auditoria");
                tb.HasTrigger("TR_Atencion_ImpedirBorrado");
            });

            e.HasKey(x => x.IdAtencion);
            e.Property(x => x.NumeroFormulario).HasMaxLength(20).IsUnicode(false).IsRequired();
            e.Property(x => x.FechaAtencion).HasColumnType("date");
            e.Property(x => x.Observaciones).HasMaxLength(400);
            e.Property(x => x.Estado)
             .HasMaxLength(10).IsUnicode(false)
             .HasDefaultValue(Atencion.EstadoRegistrada);
            e.Property(x => x.MotivoAnulacion).HasMaxLength(300);
            e.Property(x => x.FechaRegistro)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.HasIndex(x => x.NumeroFormulario).IsUnique();
            e.HasIndex(x => x.IdArchivoReceta).IsUnique();
            e.HasIndex(x => new { x.IdPaciente, x.FechaAtencion })
             .HasDatabaseName("IX_Atencion_Paciente");
            e.HasIndex(x => x.FechaAtencion).HasDatabaseName("IX_Atencion_Fecha");

            e.HasOne(x => x.Paciente)
             .WithMany(p => p.Atenciones)
             .HasForeignKey(x => x.IdPaciente)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Diagnostico)
             .WithMany(d => d.Atenciones)
             .HasForeignKey(x => x.IdDiagnostico)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Condicion)
             .WithMany(c => c.Atenciones)
             .HasForeignKey(x => x.IdCondicion)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Establecimiento)
             .WithMany(es => es.Atenciones)
             .HasForeignKey(x => x.IdEstablecimiento)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.ArchivoReceta)
             .WithMany()
             .HasForeignKey(x => x.IdArchivoReceta)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.UsuarioRegistro)
             .WithMany()
             .HasForeignKey(x => x.IdUsuarioRegistro)
             .OnDelete(DeleteBehavior.Restrict);

            e.Ignore(x => x.MontoTotal);
            e.Ignore(x => x.EstaAnulada);
        });

        mb.Entity<AtencionDetalle>(e =>
        {
            e.ToTable("AtencionDetalle");
            e.HasKey(x => x.IdAtencionDetalle);
            e.Property(x => x.Cantidad).HasColumnType("decimal(10,2)");
            e.Property(x => x.CostoUnitario).HasColumnType("decimal(12,2)");
            e.Property(x => x.MontoTotal).HasColumnType("decimal(14,2)");
            e.Property(x => x.OrigenCosto)
             .HasMaxLength(10).IsUnicode(false)
             .HasDefaultValue(AtencionDetalle.OrigenManual);

            e.HasIndex(x => new { x.IdAtencion, x.IdMedicamento }).IsUnique();
            e.HasIndex(x => x.IdMedicamento).HasDatabaseName("IX_Detalle_Medicamento");

            e.HasOne(x => x.Atencion)
             .WithMany(a => a.Detalles)
             .HasForeignKey(x => x.IdAtencion)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Medicamento)
             .WithMany()
             .HasForeignKey(x => x.IdMedicamento)
             .OnDelete(DeleteBehavior.Restrict);

            e.Ignore(x => x.CosteadoPorInventario);
        });
    }

    private static void ConfigurarFarmacia(ModelBuilder mb)
    {
        mb.Entity<Medicamento>(e =>
        {
            e.ToTable("Medicamento");
            e.HasKey(x => x.IdMedicamento);
            e.Property(x => x.Nombre).HasMaxLength(120).IsRequired();
            e.Property(x => x.NombreGenerico).HasMaxLength(120);
            e.Property(x => x.Concentracion).HasMaxLength(40);
            e.Property(x => x.FechaAlta)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.HasIndex(x => x.Nombre).IsUnique();

            e.HasOne(x => x.UnidadMedida)
             .WithMany(u => u.Medicamentos)
             .HasForeignKey(x => x.IdUnidadMedida)
             .OnDelete(DeleteBehavior.Restrict);

            e.Ignore(x => x.NombreCompleto);
        });

        mb.Entity<Lote>(e =>
        {
            e.ToTable("Lote");
            e.HasKey(x => x.IdLote);
            e.Property(x => x.NumeroLote).HasMaxLength(40);
            e.Property(x => x.FechaIngreso).HasColumnType("date");
            e.Property(x => x.FechaVencimiento).HasColumnType("date");
            e.Property(x => x.CantidadIngresada).HasColumnType("decimal(10,2)");
            e.Property(x => x.CantidadDisponible).HasColumnType("decimal(10,2)");
            e.Property(x => x.CostoUnitario).HasColumnType("decimal(12,2)");
            e.Property(x => x.Origen).HasMaxLength(120);
            e.Property(x => x.NumeroFactura).HasMaxLength(40);
            e.Property(x => x.FechaRegistro)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.Property(x => x.Anulado).HasDefaultValue(false);
            e.Property(x => x.MotivoAnulacion).HasMaxLength(200);
            e.Property(x => x.FechaAnulacion).HasColumnType("datetime2(0)");

            // Índice filtrado que hace barato al FIFO. Deja fuera los lotes
            // agotados y anulados, que no participan en el FIFO.
            e.HasIndex(x => new { x.IdMedicamento, x.FechaIngreso, x.IdLote })
             .HasFilter("[CantidadDisponible] > 0 AND [Anulado] = 0")
             .HasDatabaseName("IX_Lote_Fifo");

            e.HasOne(x => x.Medicamento)
             .WithMany(m => m.Lotes)
             .HasForeignKey(x => x.IdMedicamento)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.TipoIngreso)
             .WithMany(t => t.Lotes)
             .HasForeignKey(x => x.IdTipoIngreso)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.UsuarioRegistro)
             .WithMany()
             .HasForeignKey(x => x.IdUsuarioRegistro)
             .OnDelete(DeleteBehavior.Restrict);

            // Quién anuló el ingreso. Sin colección inversa: Usuario no lleva
            // la lista de lotes que dio de baja.
            e.HasOne(x => x.UsuarioAnulacion)
             .WithMany()
             .HasForeignKey(x => x.IdUsuarioAnulacion)
             .OnDelete(DeleteBehavior.Restrict);

            e.Ignore(x => x.ValorDisponible);
            e.Ignore(x => x.DisponibleReal);
            e.Ignore(x => x.Agotado);
            e.Ignore(x => x.Vencido);
        });

        mb.Entity<ConsumoLote>(e =>
        {
            // Declarar el trigger evita que EF use OUTPUT sobre esta tabla.
            e.ToTable("ConsumoLote", tb => tb.HasTrigger("TR_ConsumoLote_ActualizarStock"));

            e.HasKey(x => x.IdConsumo);
            e.Property(x => x.Cantidad).HasColumnType("decimal(10,2)");
            e.Property(x => x.CostoUnitario).HasColumnType("decimal(12,2)");
            e.Property(x => x.FechaRegistro)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.Property(x => x.Subtotal)
             .HasColumnType("decimal(23,4)")
             .HasComputedColumnSql("[Cantidad] * [CostoUnitario]", stored: true)
             .ValueGeneratedOnAddOrUpdate();

            e.HasIndex(x => new { x.IdAtencionDetalle, x.IdLote }).IsUnique();
            e.HasIndex(x => x.IdLote).HasDatabaseName("IX_Consumo_Lote");

            e.HasOne(x => x.AtencionDetalle)
             .WithMany(d => d.Consumos)
             .HasForeignKey(x => x.IdAtencionDetalle)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(x => x.Lote)
             .WithMany(l => l.Consumos)
             .HasForeignKey(x => x.IdLote)
             .OnDelete(DeleteBehavior.Restrict);
        });

        mb.Entity<RespaldoExportacion>(e =>
        {
            e.ToTable("RespaldoExportacion");
            e.HasKey(x => x.IdExportacion);
            e.Property(x => x.PeriodoDesde).HasColumnType("date");
            e.Property(x => x.PeriodoHasta).HasColumnType("date");
            e.Property(x => x.Destino).HasMaxLength(120);
            e.Property(x => x.Observaciones).HasMaxLength(300);
            e.Property(x => x.FechaGeneracion)
             .HasColumnType("datetime2(0)")
             .HasDefaultValueSql("SYSDATETIME()");

            e.HasOne(x => x.ArchivoGenerado)
             .WithMany()
             .HasForeignKey(x => x.IdArchivoGenerado)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(x => x.Usuario)
             .WithMany()
             .HasForeignKey(x => x.IdUsuario)
             .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void ConfigurarConsultas(ModelBuilder mb)
    {
        mb.Entity<KardexMedicamento>(e =>
        {
            e.HasNoKey().ToView("vw_KardexMedicamento");
            e.Property(x => x.Fecha).HasColumnType("date");
            e.Property(x => x.Cantidad).HasColumnType("decimal(10,2)");
            e.Property(x => x.CostoUnitario).HasColumnType("decimal(12,2)");
            e.Property(x => x.Valor).HasColumnType("decimal(23,4)");
            e.Ignore(x => x.EsIngreso);
        });

        mb.Entity<ValorStock>(e =>
        {
            e.HasNoKey().ToView("vw_ValorStock");
            e.Property(x => x.UnidadesEnStock).HasColumnType("decimal(38,2)");
            e.Property(x => x.ValorStockBs).HasColumnType("decimal(38,4)");
            // La vista llama a la columna ValorStock; el nombre en C# lleva Bs
            // para no chocar con el nombre del tipo.
            e.Property(x => x.ValorStockBs).HasColumnName("ValorStock");
            e.Property(x => x.ProximoVencimiento).HasColumnType("date");
        });

        mb.Entity<HistorialPaciente>(e =>
        {
            e.HasNoKey().ToView("vw_HistorialPaciente");
            e.Property(x => x.FechaAtencion).HasColumnType("date");
            e.Property(x => x.Cantidad).HasColumnType("decimal(10,2)");
            e.Property(x => x.MontoDonado).HasColumnType("decimal(14,2)");
        });

        // Resultados de procedimientos almacenados: no tienen tabla ni vista
        // detrás, se materializan con FromSqlRaw.
        mb.Entity<ResultadoBusquedaPaciente>(e =>
        {
            e.HasNoKey().ToView(null);
            e.Property(x => x.FechaNacimiento).HasColumnType("date");
            e.Property(x => x.UltimaAtencion).HasColumnType("date");
            e.Ignore(x => x.TieneCarnetCargado);
        });

        mb.Entity<FilaReporteEstadistico>(e =>
        {
            e.HasNoKey().ToView(null);
            e.Property(x => x.MontoDonado).HasColumnType("decimal(38,2)");
            e.Property(x => x.MontoPromedio).HasColumnType("decimal(38,2)");
            e.Ignore(x => x.EsTotalGeneral);
            e.Ignore(x => x.Etiqueta);
            e.Ignore(x => x.Dimension);
        });
    }
}
