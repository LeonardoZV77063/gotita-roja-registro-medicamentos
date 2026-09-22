/* ═══════════════════════════════════════════════════════════════════════════
   ESQUEMA COMPLETO PARA INSTALACIONES NUEVAS
   Motor: Microsoft SQL Server 2019+

   Este archivo es la fuente estructural del modelo Database First. Se ejecuta
   manualmente; la aplicación no crea ni migra el esquema con Entity Framework.

   Convenciones relevantes:
   · DECIMAL para cantidades y dinero; DATE y DATETIME2 según precisión temporal.
   · Los registros históricos se desactivan o anulan, no se borran físicamente.
   · Recetas y carnets se guardan fuera de la base; aquí sólo quedan ruta,
     metadatos y hash SHA-256.
   ═══════════════════════════════════════════════════════════════════════════ */

/* ───────────────────────────────────────────────────────────────────────────
   0. CREACIÓN DE LA BASE

   Sólo la creación de la base es idempotente. Las 22 tablas y demás objetos de
   este archivo no están protegidos contra una segunda ejecución completa.
   USE evita que el esquema se cree por accidente en master o en otra base.
   ─────────────────────────────────────────────────────────────────────────── */

IF DB_ID('DonacionMedicamentos') IS NULL
    CREATE DATABASE DonacionMedicamentos;
GO

USE DonacionMedicamentos;
GO


/* ───────────────────────────────────────────────────────────────────────────
   1. CATÁLOGOS
   Los valores naturales son únicos. Los catálogos que admiten retiro conservan
   una bandera Activo para no romper referencias históricas.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Sexo (
    IdSexo          TINYINT       IDENTITY(1,1) NOT NULL,
    Descripcion     NVARCHAR(20)  NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Sexo_Activo DEFAULT (1),
    CONSTRAINT PK_Sexo        PRIMARY KEY (IdSexo),
    CONSTRAINT UQ_Sexo_Desc   UNIQUE (Descripcion)
);
GO

/* Bolivia es el único país con catálogo territorial cargado. Para los demás,
   el origen del paciente se registra sólo a nivel de país. */
CREATE TABLE Pais (
    IdPais          SMALLINT      IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(60)  NOT NULL,
    EsLocal         BIT           NOT NULL CONSTRAINT DF_Pais_EsLocal DEFAULT (0),
    Activo          BIT           NOT NULL CONSTRAINT DF_Pais_Activo  DEFAULT (1),
    CONSTRAINT PK_Pais        PRIMARY KEY (IdPais),
    CONSTRAINT UQ_Pais_Nombre UNIQUE (Nombre)
);
GO

-- Un solo país local, o la aplicación tendría que elegir entre dos.
CREATE UNIQUE INDEX UX_Pais_Local ON Pais (EsLocal) WHERE EsLocal = 1;
GO

CREATE TABLE CondicionAtencion (
    IdCondicion     TINYINT       IDENTITY(1,1) NOT NULL,
    Descripcion     NVARCHAR(40)  NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Cond_Activo DEFAULT (1),
    CONSTRAINT PK_CondicionAtencion      PRIMARY KEY (IdCondicion),
    CONSTRAINT UQ_CondicionAtencion_Desc UNIQUE (Descripcion)
);
GO

CREATE TABLE Establecimiento (
    IdEstablecimiento INT          IDENTITY(1,1) NOT NULL,
    Nombre            NVARCHAR(120) NOT NULL,
    Activo            BIT           NOT NULL CONSTRAINT DF_Estab_Activo DEFAULT (1),
    CONSTRAINT PK_Establecimiento        PRIMARY KEY (IdEstablecimiento),
    CONSTRAINT UQ_Establecimiento_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE Diagnostico (
    IdDiagnostico   INT           IDENTITY(1,1) NOT NULL,
    Descripcion     NVARCHAR(160) NOT NULL,
    CodigoCie10     VARCHAR(10)   NULL,          -- opcional, para estadística formal
    Activo          BIT           NOT NULL CONSTRAINT DF_Diag_Activo DEFAULT (1),
    CONSTRAINT PK_Diagnostico      PRIMARY KEY (IdDiagnostico),
    CONSTRAINT UQ_Diagnostico_Desc UNIQUE (Descripcion)
);
GO

CREATE TABLE UnidadMedida (
    IdUnidadMedida  TINYINT       IDENTITY(1,1) NOT NULL,
    Descripcion     NVARCHAR(40)  NOT NULL,
    Abreviatura     NVARCHAR(10)  NOT NULL,
    CONSTRAINT PK_UnidadMedida      PRIMARY KEY (IdUnidadMedida),
    CONSTRAINT UQ_UnidadMedida_Desc UNIQUE (Descripcion)
);
GO


/* ───────────────────────────────────────────────────────────────────────────
   2. SEGURIDAD Y AUDITORÍA
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Rol (
    IdRol           TINYINT       IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(40)  NOT NULL,
    Descripcion     NVARCHAR(160) NULL,
    CONSTRAINT PK_Rol        PRIMARY KEY (IdRol),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE Usuario (
    IdUsuario       INT           IDENTITY(1,1) NOT NULL,
    NombreUsuario   NVARCHAR(60)  NOT NULL,
    NombreCompleto  NVARCHAR(120) NOT NULL,
    Email           NVARCHAR(120) NULL,
    HashContrasena  VARBINARY(256) NOT NULL,     -- nunca la contraseña en claro
    IdRol           TINYINT       NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT (1),
    UltimoAcceso    DATETIME2(0)  NULL,
    CONSTRAINT PK_Usuario         PRIMARY KEY (IdUsuario),
    CONSTRAINT UQ_Usuario_Nombre  UNIQUE (NombreUsuario),
    CONSTRAINT FK_Usuario_Rol     FOREIGN KEY (IdRol) REFERENCES Rol (IdRol)
);
GO

CREATE TABLE Bitacora (
    IdBitacora        BIGINT        IDENTITY(1,1) NOT NULL,
    IdUsuario         INT           NULL,
    TablaAfectada     SYSNAME       NOT NULL,
    IdRegistroAfectado INT          NULL,
    Accion            CHAR(6)       NOT NULL,
    DatosAnteriores   NVARCHAR(MAX) NULL,        -- JSON
    DatosNuevos       NVARCHAR(MAX) NULL,        -- JSON
    FechaHora         DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Bitacora_Fecha DEFAULT (SYSDATETIME()),
    DireccionIp       VARCHAR(45)   NULL,
    CONSTRAINT PK_Bitacora        PRIMARY KEY (IdBitacora),
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuario (IdUsuario),
    CONSTRAINT CK_Bitacora_Accion  CHECK (Accion IN ('INSERT','UPDATE','DELETE'))
);
GO


/* ───────────────────────────────────────────────────────────────────────────
   3. ARCHIVOS DIGITALES
   Una sola tabla registra recetas y carnets. El contenido permanece en el
   almacenamiento configurado; HashSha256 evita duplicar archivos idénticos.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE ArchivoDigital (
    IdArchivo          INT           IDENTITY(1,1) NOT NULL,
    NombreOriginal     NVARCHAR(255) NOT NULL,
    RutaAlmacenamiento NVARCHAR(500) NOT NULL,
    TipoMime           VARCHAR(100)  NOT NULL,
    TamanoBytes        BIGINT        NOT NULL,
    HashSha256         BINARY(32)    NOT NULL,
    FechaCarga         DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Archivo_Fecha DEFAULT (SYSDATETIME()),
    IdUsuarioCarga     INT           NOT NULL,
    CONSTRAINT PK_ArchivoDigital       PRIMARY KEY (IdArchivo),
    CONSTRAINT UQ_ArchivoDigital_Hash  UNIQUE (HashSha256),
    CONSTRAINT FK_Archivo_Usuario      FOREIGN KEY (IdUsuarioCarga)
        REFERENCES Usuario (IdUsuario),
    CONSTRAINT CK_Archivo_Tamano       CHECK (TamanoBytes > 0),
    CONSTRAINT CK_Archivo_Mime         CHECK (TipoMime IN
        ('image/jpeg','image/png','image/webp','application/pdf'))
);
GO


/* ───────────────────────────────────────────────────────────────────────────
   4. UBICACIÓN TERRITORIAL
   Departamento -> Provincia -> Municipio. Paciente referencia municipios de
   residencia y origen; Provincia y Departamento se derivan por las FK.
   CodigoINE identifica de forma estable los elementos del catálogo oficial.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Departamento (
    IdDepartamento INT          IDENTITY(1,1) NOT NULL,
    Nombre         NVARCHAR(80) NOT NULL,
    CodigoINE      VARCHAR(2)   NULL,
    CONSTRAINT PK_Departamento        PRIMARY KEY (IdDepartamento),
    CONSTRAINT UQ_Departamento_Nombre UNIQUE (Nombre),
    CONSTRAINT UQ_Departamento_INE    UNIQUE (CodigoINE)
);
GO

CREATE TABLE Provincia (
    IdProvincia    INT           IDENTITY(1,1) NOT NULL,
    IdDepartamento INT           NOT NULL,
    Nombre         NVARCHAR(100) NOT NULL,
    CodigoINE      VARCHAR(4)    NULL,
    CONSTRAINT PK_Provincia PRIMARY KEY (IdProvincia),
    CONSTRAINT UQ_Provincia_Nombre UNIQUE (IdDepartamento, Nombre),
    CONSTRAINT UQ_Provincia_INE UNIQUE (CodigoINE),
    CONSTRAINT FK_Provincia_Departamento FOREIGN KEY (IdDepartamento)
        REFERENCES Departamento (IdDepartamento)
);
GO

CREATE TABLE Municipio (
    IdMunicipio  INT           IDENTITY(1,1) NOT NULL,
    IdProvincia  INT           NOT NULL,
    Nombre       NVARCHAR(150) NOT NULL,
    CodigoINE    VARCHAR(6)    NULL,
    CONSTRAINT PK_Municipio PRIMARY KEY (IdMunicipio),
    CONSTRAINT UQ_Municipio_Nombre UNIQUE (IdProvincia, Nombre),
    CONSTRAINT UQ_Municipio_INE UNIQUE (CodigoINE),
    CONSTRAINT FK_Municipio_Provincia FOREIGN KEY (IdProvincia)
        REFERENCES Provincia (IdProvincia)
);
GO

CREATE INDEX IX_Provincia_Departamento ON Provincia (IdDepartamento, Nombre);
CREATE INDEX IX_Municipio_Provincia ON Municipio (IdProvincia, Nombre);
GO


/* ───────────────────────────────────────────────────────────────────────────
   5. PACIENTE
   La edad NO se almacena: es un dato derivado de FechaNacimiento y guardarlo
   violaría la 3FN (además de quedar desactualizado cada cumpleaños).
   Se expone como columna calculada, siempre correcta al momento de leerla.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Paciente (
    IdPaciente       INT           IDENTITY(1,1) NOT NULL,
    NumeroDocumento  VARCHAR(20)   NOT NULL,
    ComplementoDoc   VARCHAR(5)    NULL,         -- complemento del CI boliviano
    ExtensionDoc     VARCHAR(5)    NULL,         -- departamento emisor
    Nombres          NVARCHAR(80)  NOT NULL,
    ApellidoPaterno  NVARCHAR(60)  NOT NULL,
    ApellidoMaterno  NVARCHAR(60)  NULL,
    FechaNacimiento  DATE          NOT NULL,
    IdSexo           TINYINT       NOT NULL,
    Telefono         VARCHAR(20)   NULL,
    Observaciones    NVARCHAR(400) NULL,

    -- Residencia actual: dónde vive hoy. Provincia y Departamento se derivan.
    IdMunicipio      INT           NULL,

    -- Direccion conserva la referencia libre; Zona, Calle y NumeroDomicilio
    -- permiten registrar la dirección de forma estructurada.
    Zona             NVARCHAR(120) NULL,
    Calle            NVARCHAR(120) NULL,
    NumeroDomicilio  NVARCHAR(20)  NULL,
    Direccion        NVARCHAR(250) NULL,

    -- Lugar de origen, separado de la residencia. Si falta, la aplicación usa
    -- la residencia como procedencia supuesta y lo informa en pantalla.
    IdMunicipioOrigen INT          NULL,

    -- Para pacientes del exterior se registra el país y IdMunicipioOrigen queda
    -- en NULL. La aplicación mantiene esa coherencia; un CHECK no puede consultar
    -- Pais para decidir si el país es local.
    IdPaisOrigen     SMALLINT      NULL,

    Activo           BIT           NOT NULL CONSTRAINT DF_Paciente_Activo DEFAULT (1),
    FechaRegistro    DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Paciente_Fecha DEFAULT (SYSDATETIME()),
    IdUsuarioRegistro INT          NOT NULL,

    -- Edad vigente, derivada. No ocupa espacio ni se desincroniza.
    Edad AS (DATEDIFF(YEAR, FechaNacimiento, GETDATE())
             - CASE WHEN (MONTH(FechaNacimiento) > MONTH(GETDATE()))
                      OR (MONTH(FechaNacimiento) = MONTH(GETDATE())
                          AND DAY(FechaNacimiento) > DAY(GETDATE()))
                    THEN 1 ELSE 0 END),

    CONSTRAINT PK_Paciente          PRIMARY KEY (IdPaciente),
    CONSTRAINT UQ_Paciente_Documento UNIQUE (NumeroDocumento, ComplementoDoc),
    CONSTRAINT FK_Paciente_Sexo     FOREIGN KEY (IdSexo) REFERENCES Sexo (IdSexo),
    CONSTRAINT FK_Paciente_Usuario  FOREIGN KEY (IdUsuarioRegistro)
        REFERENCES Usuario (IdUsuario),
    CONSTRAINT FK_Paciente_PaisOrigen FOREIGN KEY (IdPaisOrigen)
        REFERENCES Pais (IdPais),
    CONSTRAINT FK_Paciente_Municipio FOREIGN KEY (IdMunicipio)
        REFERENCES Municipio (IdMunicipio),
    CONSTRAINT FK_Paciente_MunicipioOrigen FOREIGN KEY (IdMunicipioOrigen)
        REFERENCES Municipio (IdMunicipio),
    CONSTRAINT CK_Paciente_FechaNac CHECK (FechaNacimiento <= CAST(GETDATE() AS DATE))
);
GO

-- UQ_Paciente_Documento ya crea el índice único necesario para la búsqueda por CI.
-- Búsqueda por apellido cuando la paciente no recuerda su número.
CREATE INDEX IX_Paciente_Apellidos
    ON Paciente (ApellidoPaterno, ApellidoMaterno, Nombres);
CREATE INDEX IX_Paciente_Municipio
    ON Paciente (IdMunicipio);
CREATE INDEX IX_Paciente_MunicipioOrigen
    ON Paciente (IdMunicipioOrigen);
CREATE INDEX IX_Paciente_PaisOrigen
    ON Paciente (IdPaisOrigen);
CREATE INDEX IX_Paciente_Sexo
    ON Paciente (IdSexo);
CREATE INDEX IX_Paciente_FechaNacimiento
    ON Paciente (FechaNacimiento);
GO


/* Historial de carnets del paciente: el carnet se renueva, y conservar el
   anterior permite auditar entregas hechas con el documento vigente entonces. */
CREATE TABLE PacienteDocumento (
    IdPacienteDocumento INT          IDENTITY(1,1) NOT NULL,
    IdPaciente          INT          NOT NULL,
    IdArchivo           INT          NOT NULL,
    FechaRegistro       DATETIME2(0) NOT NULL
        CONSTRAINT DF_PacDoc_Fecha DEFAULT (SYSDATETIME()),
    Vigente             BIT          NOT NULL CONSTRAINT DF_PacDoc_Vigente DEFAULT (1),
    CONSTRAINT PK_PacienteDocumento    PRIMARY KEY (IdPacienteDocumento),
    CONSTRAINT FK_PacDoc_Paciente      FOREIGN KEY (IdPaciente)
        REFERENCES Paciente (IdPaciente),
    CONSTRAINT FK_PacDoc_Archivo       FOREIGN KEY (IdArchivo)
        REFERENCES ArchivoDigital (IdArchivo),
    CONSTRAINT UQ_PacDoc_Archivo       UNIQUE (IdArchivo)
);
GO

-- Un solo carnet vigente por paciente (índice filtrado).
CREATE UNIQUE INDEX IX_PacDoc_UnicoVigente
    ON PacienteDocumento (IdPaciente) WHERE Vigente = 1;
GO


/* ───────────────────────────────────────────────────────────────────────────
   6. MEDICAMENTO
   La aplicación normaliza el nombre escrito en la interfaz y crea la fila si
   no existe. Atenciones e inventario referencian siempre el identificador.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Medicamento (
    IdMedicamento   INT           IDENTITY(1,1) NOT NULL,
    Nombre          NVARCHAR(120) NOT NULL,
    NombreGenerico  NVARCHAR(120) NULL,
    Concentracion   NVARCHAR(40)  NULL,
    IdUnidadMedida  TINYINT       NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Medicamento_Activo DEFAULT (1),
    FechaAlta       DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Medicamento_Fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_Medicamento        PRIMARY KEY (IdMedicamento),
    CONSTRAINT UQ_Medicamento_Nombre UNIQUE (Nombre),
    CONSTRAINT FK_Medicamento_Unidad FOREIGN KEY (IdUnidadMedida)
        REFERENCES UnidadMedida (IdUnidadMedida)
);
GO


/* ───────────────────────────────────────────────────────────────────────────
   7. ATENCIÓN (la entrega)
   IdArchivoReceta es NOT NULL: sin receta escaneada no hay atención.
   La obligatoriedad se aplica también como restricción del motor.
   ─────────────────────────────────────────────────────────────────────────── */

CREATE TABLE Atencion (
    IdAtencion        INT           IDENTITY(1,1) NOT NULL,
    NumeroFormulario  VARCHAR(20)   NOT NULL,
    IdPaciente        INT           NOT NULL,
    FechaAtencion     DATE          NOT NULL,
    IdDiagnostico     INT           NOT NULL,
    IdCondicion       TINYINT       NOT NULL,
    IdEstablecimiento INT           NULL,        -- opcional
    IdArchivoReceta   INT           NOT NULL,    -- receta obligatoria
    Observaciones     NVARCHAR(400) NULL,
    Estado            VARCHAR(10)   NOT NULL
        CONSTRAINT DF_Atencion_Estado DEFAULT ('REGISTRADA'),
    MotivoAnulacion   NVARCHAR(300) NULL,
    FechaRegistro     DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Atencion_Fecha DEFAULT (SYSDATETIME()),
    IdUsuarioRegistro INT           NOT NULL,

    CONSTRAINT PK_Atencion            PRIMARY KEY (IdAtencion),
    CONSTRAINT UQ_Atencion_Formulario UNIQUE (NumeroFormulario),
    CONSTRAINT FK_Atencion_Paciente   FOREIGN KEY (IdPaciente)
        REFERENCES Paciente (IdPaciente),
    CONSTRAINT FK_Atencion_Diagnostico FOREIGN KEY (IdDiagnostico)
        REFERENCES Diagnostico (IdDiagnostico),
    CONSTRAINT FK_Atencion_Condicion  FOREIGN KEY (IdCondicion)
        REFERENCES CondicionAtencion (IdCondicion),
    CONSTRAINT FK_Atencion_Estab      FOREIGN KEY (IdEstablecimiento)
        REFERENCES Establecimiento (IdEstablecimiento),
    CONSTRAINT FK_Atencion_Receta     FOREIGN KEY (IdArchivoReceta)
        REFERENCES ArchivoDigital (IdArchivo),
    CONSTRAINT FK_Atencion_Usuario    FOREIGN KEY (IdUsuarioRegistro)
        REFERENCES Usuario (IdUsuario),
    CONSTRAINT UQ_Atencion_Receta     UNIQUE (IdArchivoReceta),
    CONSTRAINT CK_Atencion_Estado     CHECK (Estado IN ('REGISTRADA','ANULADA')),
    CONSTRAINT CK_Atencion_Fecha      CHECK (FechaAtencion <= CAST(GETDATE() AS DATE))
);
GO

-- Índices para historial del paciente y reportes por período.
CREATE INDEX IX_Atencion_Paciente ON Atencion (IdPaciente, FechaAtencion DESC);
CREATE INDEX IX_Atencion_Fecha    ON Atencion (FechaAtencion)
    INCLUDE (IdDiagnostico, IdCondicion);
GO


/* Detalle: una receta puede traer varios medicamentos. Sin esta tabla habría
   que repetir la atención por cada medicamento (rompe 1FN) o poner columnas
   Medicamento1, Medicamento2… (rompe 1FN y no escala). */
CREATE TABLE AtencionDetalle (
    IdAtencionDetalle INT           IDENTITY(1,1) NOT NULL,
    IdAtencion        INT           NOT NULL,
    IdMedicamento     INT           NOT NULL,
    Cantidad          DECIMAL(10,2) NOT NULL,
    CostoUnitario     DECIMAL(12,2) NULL,        -- informativo bajo FIFO
    MontoTotal        DECIMAL(14,2) NOT NULL,
    OrigenCosto       VARCHAR(10)   NOT NULL
        CONSTRAINT DF_Detalle_Origen DEFAULT ('MANUAL'),

    /* MontoTotal se almacena, no se calcula. En modo MANUAL sería derivable
       (Cantidad × CostoUnitario), pero en modo FIFO la línea sale de varios
       lotes a precios distintos y no existe un "precio unitario" único que la
       reproduzca sin arrastrar centavos de redondeo. Guardar el monto exacto
       evita que el total de la donación difiera de la suma de sus consumos. */

    CONSTRAINT PK_AtencionDetalle      PRIMARY KEY (IdAtencionDetalle),
    CONSTRAINT FK_Detalle_Atencion     FOREIGN KEY (IdAtencion)
        REFERENCES Atencion (IdAtencion),
    CONSTRAINT FK_Detalle_Medicamento  FOREIGN KEY (IdMedicamento)
        REFERENCES Medicamento (IdMedicamento),
    CONSTRAINT UQ_Detalle_AtencionMed  UNIQUE (IdAtencion, IdMedicamento),
    CONSTRAINT CK_Detalle_Cantidad     CHECK (Cantidad > 0),
    CONSTRAINT CK_Detalle_Costo        CHECK (CostoUnitario IS NULL OR CostoUnitario >= 0),
    CONSTRAINT CK_Detalle_Monto        CHECK (MontoTotal >= 0),
    CONSTRAINT CK_Detalle_Origen       CHECK (OrigenCosto IN ('MANUAL','FIFO'))
);
GO

CREATE INDEX IX_Detalle_Medicamento ON AtencionDetalle (IdMedicamento);
GO


/* ═══════════════════════════════════════════════════════════════════════════
   MÓDULO DE FARMACIA
   ═══════════════════════════════════════════════════════════════════════════ */

CREATE TABLE TipoIngreso (
    IdTipoIngreso   TINYINT       IDENTITY(1,1) NOT NULL,
    Descripcion     NVARCHAR(40)  NOT NULL,
    CONSTRAINT PK_TipoIngreso      PRIMARY KEY (IdTipoIngreso),
    CONSTRAINT UQ_TipoIngreso_Desc UNIQUE (Descripcion)
);
GO

/* Cada ingreso conserva su costo histórico por lote; no se reemplaza por un
   costo promedio del medicamento. */
CREATE TABLE Lote (
    IdLote             INT           IDENTITY(1,1) NOT NULL,
    IdMedicamento      INT           NOT NULL,
    IdTipoIngreso      TINYINT       NOT NULL,
    NumeroLote         NVARCHAR(40)  NULL,
    FechaIngreso       DATE          NOT NULL,
    FechaVencimiento   DATE          NULL,
    CantidadIngresada  DECIMAL(10,2) NOT NULL,
    CantidadDisponible DECIMAL(10,2) NOT NULL,
    CostoUnitario      DECIMAL(12,2) NOT NULL,
    Origen             NVARCHAR(120) NULL,       -- proveedor o donante
    NumeroFactura      NVARCHAR(40)  NULL,
    FechaRegistro      DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Lote_Fecha DEFAULT (SYSDATETIME()),
    IdUsuarioRegistro  INT           NOT NULL,

    -- Un lote anulado sale del stock, la valuación y el FIFO sin borrar sus
    -- cantidades ni alterar el costo histórico de consumos existentes.
    Anulado            BIT           NOT NULL
        CONSTRAINT DF_Lote_Anulado DEFAULT (0),
    MotivoAnulacion    NVARCHAR(200) NULL,
    FechaAnulacion     DATETIME2(0)  NULL,
    IdUsuarioAnulacion INT           NULL,

    CONSTRAINT PK_Lote               PRIMARY KEY (IdLote),
    CONSTRAINT FK_Lote_Medicamento   FOREIGN KEY (IdMedicamento)
        REFERENCES Medicamento (IdMedicamento),
    CONSTRAINT FK_Lote_TipoIngreso   FOREIGN KEY (IdTipoIngreso)
        REFERENCES TipoIngreso (IdTipoIngreso),
    CONSTRAINT FK_Lote_Usuario       FOREIGN KEY (IdUsuarioRegistro)
        REFERENCES Usuario (IdUsuario),
    CONSTRAINT FK_Lote_UsuarioAnulacion FOREIGN KEY (IdUsuarioAnulacion)
        REFERENCES Usuario (IdUsuario),
    -- Los cuatro campos de la anulación viajan juntos: nadie puede quedar
    -- fuera del inventario sin que conste quién lo sacó y por qué.
    CONSTRAINT CK_Lote_Anulacion     CHECK (
        (Anulado = 0 AND MotivoAnulacion IS NULL
                     AND FechaAnulacion IS NULL
                     AND IdUsuarioAnulacion IS NULL)
        OR
        (Anulado = 1 AND MotivoAnulacion IS NOT NULL
                     AND FechaAnulacion IS NOT NULL
                     AND IdUsuarioAnulacion IS NOT NULL)),
    CONSTRAINT CK_Lote_Cantidades    CHECK (CantidadIngresada > 0
                                        AND CantidadDisponible >= 0
                                        AND CantidadDisponible <= CantidadIngresada),
    CONSTRAINT CK_Lote_Costo         CHECK (CostoUnitario >= 0),
    CONSTRAINT CK_Lote_Vencimiento   CHECK (FechaVencimiento IS NULL
                                        OR FechaVencimiento > FechaIngreso),
    -- Impide que el FIFO use un lote antes de su ingreso real.
    CONSTRAINT CK_Lote_FechaIngreso  CHECK (FechaIngreso <= CAST(GETDATE() AS DATE))
);
GO

-- El índice que hace barato al FIFO: lotes de un medicamento, del más viejo
-- al más nuevo, filtrando los ya agotados y los anulados.
CREATE INDEX IX_Lote_Fifo
    ON Lote (IdMedicamento, FechaIngreso, IdLote)
    INCLUDE (CantidadDisponible, CostoUnitario)
    WHERE CantidadDisponible > 0 AND Anulado = 0;
GO


/* Resuelve el N:M entre el detalle y los lotes consumidos; una misma línea
   puede tomar unidades de varios lotes con costos distintos. */
CREATE TABLE ConsumoLote (
    IdConsumo         INT           IDENTITY(1,1) NOT NULL,
    IdAtencionDetalle INT           NOT NULL,
    IdLote            INT           NOT NULL,
    Cantidad          DECIMAL(10,2) NOT NULL,
    CostoUnitario     DECIMAL(12,2) NOT NULL,   -- copia histórica del lote
    Subtotal AS (Cantidad * CostoUnitario) PERSISTED,
    FechaRegistro     DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Consumo_Fecha DEFAULT (SYSDATETIME()),

    CONSTRAINT PK_ConsumoLote        PRIMARY KEY (IdConsumo),
    CONSTRAINT FK_Consumo_Detalle    FOREIGN KEY (IdAtencionDetalle)
        REFERENCES AtencionDetalle (IdAtencionDetalle) ON DELETE CASCADE,
    CONSTRAINT FK_Consumo_Lote       FOREIGN KEY (IdLote) REFERENCES Lote (IdLote),
    CONSTRAINT UQ_Consumo_DetalleLote UNIQUE (IdAtencionDetalle, IdLote),
    CONSTRAINT CK_Consumo_Cantidad   CHECK (Cantidad > 0)
);
GO

CREATE INDEX IX_Consumo_Lote ON ConsumoLote (IdLote);
GO


/* Registro de las copias enviadas al exterior — la trazabilidad de qué
   período se exportó, cuándo y quién lo hizo. La exportación es manual;
   lo que el sistema garantiza es que quede constancia de ella. */
CREATE TABLE RespaldoExportacion (
    IdExportacion    INT           IDENTITY(1,1) NOT NULL,
    PeriodoDesde     DATE          NOT NULL,
    PeriodoHasta     DATE          NOT NULL,
    CantidadAtenciones INT         NOT NULL,
    Destino          NVARCHAR(120) NULL,
    IdArchivoGenerado INT          NULL,
    IdUsuario        INT           NOT NULL,
    FechaGeneracion  DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Export_Fecha DEFAULT (SYSDATETIME()),
    Observaciones    NVARCHAR(300) NULL,
    CONSTRAINT PK_RespaldoExportacion PRIMARY KEY (IdExportacion),
    CONSTRAINT FK_Export_Archivo  FOREIGN KEY (IdArchivoGenerado)
        REFERENCES ArchivoDigital (IdArchivo),
    CONSTRAINT FK_Export_Usuario  FOREIGN KEY (IdUsuario) REFERENCES Usuario (IdUsuario),
    CONSTRAINT CK_Export_Periodo  CHECK (PeriodoHasta >= PeriodoDesde)
);
GO


/* ═══════════════════════════════════════════════════════════════════════════
   8. TRIGGERS
   ═══════════════════════════════════════════════════════════════════════════ */

/* Descuenta el stock del lote cuando se registra un consumo, y lo devuelve
   si el consumo se elimina. Mantener CantidadDisponible en Lote es una
   desnormalización deliberada: sin ella, cada consulta de stock tendría que
   sumar todo el histórico de ConsumoLote. El trigger garantiza que el valor
   no se separe nunca de la realidad. */
CREATE OR ALTER TRIGGER TR_ConsumoLote_ActualizarStock
ON ConsumoLote
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM inserted)
       AND NOT EXISTS (SELECT 1 FROM deleted)
        RETURN;

    /* Un solo UPDATE, acotado a los lotes que la operación tocó. Los consumos
       insertados restan y los eliminados devuelven; una misma sentencia puede
       hacer ambas cosas, así que se calcula el neto por lote antes de aplicar. */
    ;WITH Movimiento AS (
        SELECT IdLote, SUM(Cantidad) AS Delta FROM inserted GROUP BY IdLote
        UNION ALL
        SELECT IdLote, -SUM(Cantidad)         FROM deleted  GROUP BY IdLote
    ),
    Neto AS (
        SELECT IdLote, SUM(Delta) AS Delta FROM Movimiento GROUP BY IdLote
    )
    UPDATE L
       SET L.CantidadDisponible = L.CantidadDisponible - N.Delta
      FROM Lote L
      JOIN Neto N ON N.IdLote = L.IdLote;

    /* CK_Lote_Cantidades rechaza el consumo si el UPDATE deja el saldo fuera
       del rango válido. El trigger no ejecuta ROLLBACK para no apropiarse de la
       transacción del llamador. */
END;
GO


/* Auditoría de la tabla Atencion: toda alta y toda modificación quedan
   registradas con el estado anterior en JSON. Nada se pierde.

   El autor del cambio es el usuario que la aplicación informa con
   sp_set_session_context 'IdUsuario' (lo hace al anular). Si no llegó —por
   ejemplo, un UPDATE hecho a mano desde SSMS— se anota a quien registró la
   entrega, que era el único dato disponible antes. */
CREATE OR ALTER TRIGGER TR_Atencion_Auditoria
ON Atencion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuarioSesion INT = TRY_CAST(SESSION_CONTEXT(N'IdUsuario') AS INT);

    IF @IdUsuarioSesion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM Usuario WHERE IdUsuario = @IdUsuarioSesion)
        SET @IdUsuarioSesion = NULL;

    INSERT INTO Bitacora (IdUsuario, TablaAfectada, IdRegistroAfectado,
                          Accion, DatosAnteriores, DatosNuevos)
    SELECT ISNULL(@IdUsuarioSesion, i.IdUsuarioRegistro),
           'Atencion',
           i.IdAtencion,
           CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN 'UPDATE' ELSE 'INSERT' END,
           (SELECT * FROM deleted d WHERE d.IdAtencion = i.IdAtencion
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT * FROM inserted x WHERE x.IdAtencion = i.IdAtencion
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
      FROM inserted i;
END;
GO


/* Impide borrar físicamente una atención: el respaldo para auditoría no
   admite huecos. En su lugar la marca como ANULADA. */
CREATE OR ALTER TRIGGER TR_Atencion_ImpedirBorrado
ON Atencion
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE A
       SET A.Estado = 'ANULADA',
           A.MotivoAnulacion = ISNULL(A.MotivoAnulacion,
                                      'Anulada por solicitud de borrado')
      FROM Atencion A
      JOIN deleted d ON d.IdAtencion = A.IdAtencion;
END;
GO


/* ═══════════════════════════════════════════════════════════════════════════
   9. PROCEDIMIENTOS ALMACENADOS
   ═══════════════════════════════════════════════════════════════════════════ */

/* Asigna una cantidad solicitada a los lotes disponibles, del más antiguo al
   más nuevo, escribiendo una fila de ConsumoLote por cada lote tocado y
   devolviendo el costo real de la entrega.

   Sin cursor: la suma corrida (SUM ... OVER) dice cuánto stock hay acumulado
   hasta cada lote, y con eso se resuelve en un solo INSERT qué lotes entran y
   cuánto sale de cada uno.
       AcumAntes = stock de todos los lotes anteriores
       participa el lote si AcumAntes < cantidad pedida
       toma = lote completo, o lo que falte si es el último

   Sólo participan los lotes que ya habían ingresado a la fecha de la atención
   a la que pertenece la línea: un lote no puede salir antes de llegar. */
CREATE OR ALTER PROCEDURE sp_ConsumirLotesFifo
    @IdAtencionDetalle INT,
    @IdMedicamento     INT,
    @Cantidad          DECIMAL(10,2),
    @MontoTotal        DECIMAL(14,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Disponible DECIMAL(14,2);
    DECLARE @FechaCorte DATE;
    DECLARE @Msg        NVARCHAR(400);

    /* La aplicación registra una entrega completa dentro de una sola
       transacción y llama a este procedimiento una vez por medicamento. Si ya
       hay una transacción abierta, el procedimiento se suma a ella en lugar de
       abrir la suya: confirmar o revertir es responsabilidad de quien la abrió. */
    DECLARE @TranPropia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;

    IF @TranPropia = 1
        BEGIN TRANSACTION;

    BEGIN TRY

        SELECT @FechaCorte = a.FechaAtencion
          FROM AtencionDetalle d
          JOIN Atencion a ON a.IdAtencion = d.IdAtencion
         WHERE d.IdAtencionDetalle = @IdAtencionDetalle;

        IF @FechaCorte IS NULL
            THROW 50002, N'La línea de entrega indicada no existe.', 1;

        -- UPDLOCK/HOLDLOCK: impide que otra sesión reserve los mismos lotes
        SELECT @Disponible = SUM(CantidadDisponible)
          FROM Lote WITH (UPDLOCK, HOLDLOCK)
         WHERE IdMedicamento = @IdMedicamento
           AND CantidadDisponible > 0
           AND Anulado = 0
           AND FechaIngreso <= @FechaCorte;

        IF ISNULL(@Disponible, 0) < @Cantidad
        BEGIN
            SET @Msg = CONCAT(
                N'Stock insuficiente de «',
                ISNULL((SELECT Nombre FROM Medicamento WHERE IdMedicamento = @IdMedicamento),
                       CONCAT(N'medicamento ', @IdMedicamento)),
                N'»: se piden ', CAST(@Cantidad AS NVARCHAR(20)),
                N' unidades y hay ', CAST(ISNULL(@Disponible, 0) AS NVARCHAR(20)),
                N' en lotes ingresados hasta el ', CONVERT(NVARCHAR(10), @FechaCorte, 103), N'.');
            THROW 50001, @Msg, 1;
        END

        ;WITH Lotes AS (
            SELECT IdLote,
                   CantidadDisponible,
                   CostoUnitario,
                   SUM(CantidadDisponible) OVER (ORDER BY FechaIngreso, IdLote
                                                 ROWS UNBOUNDED PRECEDING) AS AcumHasta
              FROM Lote
             WHERE IdMedicamento = @IdMedicamento
               AND CantidadDisponible > 0
               AND Anulado = 0
               AND FechaIngreso <= @FechaCorte
        )
        INSERT INTO ConsumoLote (IdAtencionDetalle, IdLote, Cantidad, CostoUnitario)
        SELECT @IdAtencionDetalle,
               IdLote,
               CASE WHEN AcumHasta <= @Cantidad
                    THEN CantidadDisponible                            -- lote completo
                    ELSE @Cantidad - (AcumHasta - CantidadDisponible)  -- lo que falte
               END,
               CostoUnitario
          FROM Lotes
         WHERE AcumHasta - CantidadDisponible < @Cantidad;

        SELECT @MontoTotal = SUM(Subtotal)
          FROM ConsumoLote
         WHERE IdAtencionDetalle = @IdAtencionDetalle;

        UPDATE AtencionDetalle
           SET MontoTotal    = @MontoTotal,
               CostoUnitario = @MontoTotal / NULLIF(@Cantidad, 0),  -- promedio informativo
               OrigenCosto   = 'FIFO'
         WHERE IdAtencionDetalle = @IdAtencionDetalle;

        IF @TranPropia = 1
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH

        /* Sólo se revierte lo que este procedimiento abrió. Si la transacción
           es del llamador, se le propaga el error para que decida. Una
           transacción que quedó inservible (XACT_STATE = -1) hay que revertirla
           sí o sí, venga de donde venga. */
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF @TranPropia = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH
END;
GO


/* Busca un paciente por documento o por nombre — la primera pantalla de cada
   atención. Devuelve además cuántas veces vino antes y cuándo fue la última.

   Reglas (las mismas que aplica la aplicación, ver CriterioBusqueda.cs):
     · Criterio vacío: todos los pacientes activos.
     · El texto se separa en palabras (hasta 6) y TODAS deben coincidir.
     · Una palabra coincide con el comienzo del carnet, o con el comienzo de
       cualquier palabra de los nombres o de los apellidos (el guion también
       separa palabras: «Gómez» encuentra «Pérez-Gómez»).
     · Sin distinguir mayúsculas ni tildes (colación CI_AI).
     · Un criterio con caracteres fuera del plano básico (emoji) no devuelve
       filas: SQL Server no les asigna peso y LIKE los trataría como vacíos.
     · Visitas y Última cuentan sólo entregas REGISTRADAS: una anulada no es
       una visita. */
CREATE OR ALTER PROCEDURE sp_BuscarPaciente
    @Criterio NVARCHAR(80)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Texto NVARCHAR(80) = LTRIM(RTRIM(ISNULL(@Criterio, N'')));

    DECLARE @Invalido BIT =
        CASE WHEN PATINDEX(N'%[' + NCHAR(55296) + N'-' + NCHAR(57343) + N']%',
                           @Texto COLLATE Latin1_General_BIN2) > 0
             THEN 1 ELSE 0 END;

    DECLARE @Palabras TABLE (
        Patron NVARCHAR(200) COLLATE DATABASE_DEFAULT NOT NULL
    );

    -- Cada palabra, con los comodines de LIKE escapados con '\'.
    INSERT INTO @Palabras (Patron)
    SELECT DISTINCT TOP (6)
           REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(value)),
                   N'\', N'\\'), N'%', N'\%'), N'_', N'\_'), N'[', N'\[')
      FROM STRING_SPLIT(REPLACE(@Texto, N'-', N' '), N' ')
     WHERE LTRIM(RTRIM(value)) <> N'';

    SELECT p.IdPaciente,
           p.NumeroDocumento,
           p.ComplementoDoc,
           p.ApellidoPaterno + ' ' + ISNULL(p.ApellidoMaterno,'')
             + ', ' + p.Nombres           AS NombreCompleto,
           p.FechaNacimiento,
           p.Edad,
           s.Descripcion                  AS Sexo,
           (SELECT COUNT(*) FROM Atencion a
             WHERE a.IdPaciente = p.IdPaciente
               AND a.Estado = 'REGISTRADA') AS TotalAtenciones,
           (SELECT MAX(a.FechaAtencion) FROM Atencion a
             WHERE a.IdPaciente = p.IdPaciente
               AND a.Estado = 'REGISTRADA') AS UltimaAtencion,
           pd.IdArchivo                   AS IdArchivoCarnet
      FROM Paciente p
      JOIN Sexo s ON s.IdSexo = p.IdSexo
      LEFT JOIN PacienteDocumento pd
             ON pd.IdPaciente = p.IdPaciente AND pd.Vigente = 1
     WHERE p.Activo = 1
       AND @Invalido = 0
       AND NOT EXISTS (
            SELECT 1
              FROM @Palabras w
             WHERE NOT (
                      p.NumeroDocumento LIKE w.Patron + N'%' ESCAPE N'\'
                   OR REPLACE(N' ' + p.Nombres, N'-', N' ') COLLATE Latin1_General_CI_AI
                          LIKE N'% ' + w.Patron + N'%' ESCAPE N'\'
                   OR REPLACE(N' ' + p.ApellidoPaterno, N'-', N' ') COLLATE Latin1_General_CI_AI
                          LIKE N'% ' + w.Patron + N'%' ESCAPE N'\'
                   OR REPLACE(N' ' + ISNULL(p.ApellidoMaterno, N''), N'-', N' ') COLLATE Latin1_General_CI_AI
                          LIKE N'% ' + w.Patron + N'%' ESCAPE N'\'
             )
       )
     ORDER BY p.ApellidoPaterno, p.Nombres;
END;
GO


/* ═══════════════════════════════════════════════════════════════════════════
   10. VISTAS Y CONSULTAS COMPLEJAS
   ═══════════════════════════════════════════════════════════════════════════ */

/* Kardex: el movimiento de cada medicamento como vista, no como tabla.
   Los datos ya están en Lote y ConsumoLote; duplicarlos sería redundancia. */
CREATE OR ALTER VIEW vw_KardexMedicamento
AS
    SELECT m.IdMedicamento, m.Nombre,
           'INGRESO'          AS Movimiento,
           l.FechaIngreso     AS Fecha,
           ti.Descripcion     AS Concepto,
           l.CantidadIngresada AS Cantidad,
           l.CostoUnitario,
           l.CantidadIngresada * l.CostoUnitario AS Valor
      FROM Lote l
      JOIN Medicamento m  ON m.IdMedicamento = l.IdMedicamento
      JOIN TipoIngreso ti ON ti.IdTipoIngreso = l.IdTipoIngreso
    UNION ALL
    SELECT m.IdMedicamento, m.Nombre,
           'SALIDA',
           a.FechaAtencion,
           'Entrega form. ' + a.NumeroFormulario,
           -c.Cantidad,
           c.CostoUnitario,
           -c.Subtotal
      FROM ConsumoLote c
      JOIN Lote l            ON l.IdLote = c.IdLote
      JOIN Medicamento m     ON m.IdMedicamento = l.IdMedicamento
      JOIN AtencionDetalle d ON d.IdAtencionDetalle = c.IdAtencionDetalle
      JOIN Atencion a        ON a.IdAtencion = d.IdAtencion
    UNION ALL
    /* El ingreso anulado no se esconde —ocurrió, y taparlo dejaría sin explicar
       de dónde salieron las entregas hechas con ese lote—: se agrega el asiento
       que lo revierte, por el saldo que el lote tenga en ese momento. Así las
       cantidades del kardex vuelven a cerrar contra el stock. */
    SELECT m.IdMedicamento, m.Nombre,
           'ANULACION',
           CAST(l.FechaAnulacion AS DATE),
           CONCAT(N'Ingreso anulado: ', l.MotivoAnulacion),
           -l.CantidadDisponible,
           l.CostoUnitario,
           -(l.CantidadDisponible * l.CostoUnitario)
      FROM Lote l
      JOIN Medicamento m ON m.IdMedicamento = l.IdMedicamento
     WHERE l.Anulado = 1;
GO


/* Valor actual del stock, lote por lote y a costo real de adquisición. */
CREATE OR ALTER VIEW vw_ValorStock
AS
    SELECT m.IdMedicamento,
           m.Nombre,
           SUM(l.CantidadDisponible)                        AS UnidadesEnStock,
           SUM(l.CantidadDisponible * l.CostoUnitario)      AS ValorStock,
           MIN(l.FechaVencimiento)                          AS ProximoVencimiento
      FROM Lote l
      JOIN Medicamento m ON m.IdMedicamento = l.IdMedicamento
     WHERE l.CantidadDisponible > 0
       AND l.Anulado = 0
     GROUP BY m.IdMedicamento, m.Nombre;
GO


/* Historial de entregas registradas por paciente y medicamento. */
CREATE OR ALTER VIEW vw_HistorialPaciente
AS
    SELECT p.IdPaciente,
           p.NumeroDocumento,
           p.ApellidoPaterno + ', ' + p.Nombres AS Paciente,
           a.IdAtencion,
           a.NumeroFormulario,
           a.FechaAtencion,
           dg.Descripcion  AS Diagnostico,
           co.Descripcion  AS Condicion,
           es.Nombre       AS Establecimiento,
           m.Nombre        AS Medicamento,
           d.Cantidad,
           d.MontoTotal    AS MontoDonado,
           ar.RutaAlmacenamiento AS RutaReceta
      FROM Atencion a
      JOIN Paciente p          ON p.IdPaciente = a.IdPaciente
      JOIN Diagnostico dg      ON dg.IdDiagnostico = a.IdDiagnostico
      JOIN CondicionAtencion co ON co.IdCondicion = a.IdCondicion
      LEFT JOIN Establecimiento es ON es.IdEstablecimiento = a.IdEstablecimiento
      JOIN ArchivoDigital ar   ON ar.IdArchivo = a.IdArchivoReceta
      JOIN AtencionDetalle d   ON d.IdAtencion = a.IdAtencion
      JOIN Medicamento m       ON m.IdMedicamento = d.IdMedicamento
     WHERE a.Estado = 'REGISTRADA';
GO


/* Distribución por sexo, condición y grupo etario en un período. */
CREATE OR ALTER PROCEDURE sp_ReporteEstadistico
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    WITH Base AS (
        SELECT a.IdAtencion,
               s.Descripcion AS Sexo,
               co.Descripcion AS Condicion,
               CASE WHEN p.Edad < 18 THEN 'Menor de 18'
                    WHEN p.Edad < 40 THEN '18 a 39'
                    WHEN p.Edad < 60 THEN '40 a 59'
                    ELSE '60 o más' END AS GrupoEtario,
               (SELECT SUM(d.MontoTotal) FROM AtencionDetalle d
                 WHERE d.IdAtencion = a.IdAtencion) AS Monto
          FROM Atencion a
          JOIN Paciente p           ON p.IdPaciente  = a.IdPaciente
          JOIN Sexo s               ON s.IdSexo      = p.IdSexo
          JOIN CondicionAtencion co ON co.IdCondicion = a.IdCondicion
         WHERE a.Estado = 'REGISTRADA'
           AND a.FechaAtencion BETWEEN @Desde AND @Hasta
    )
    SELECT Sexo,
           Condicion,
           GrupoEtario,
           COUNT(*)          AS Atenciones,
           SUM(Monto)        AS MontoDonado,
           AVG(Monto)        AS MontoPromedio
      FROM Base
     GROUP BY GROUPING SETS ((Sexo), (Condicion), (GrupoEtario), (Sexo, Condicion), ())
     ORDER BY GROUPING(Sexo), GROUPING(Condicion), GROUPING(GrupoEtario);
END;
GO


/* Después de este esquema, ejecutar 02-catalogo-territorial.sql para cargar
   los 9 departamentos, 112 provincias y 340 municipios. */

/* ═══════════════════════════════════════════════════════════════════════════
   11. DATOS INICIALES
   ═══════════════════════════════════════════════════════════════════════════ */

INSERT INTO Sexo (Descripcion) VALUES ('Femenino'), ('Masculino');

-- Bolivia se marca como país local. «Otro» cubre países aún no catalogados.
INSERT INTO Pais (Nombre, EsLocal)
VALUES (N'Bolivia', 1), (N'Argentina', 0), (N'Brasil', 0), (N'Chile', 0),
       (N'Colombia', 0), (N'Cuba', 0), (N'Ecuador', 0), (N'España', 0),
       (N'Estados Unidos', 0), (N'México', 0), (N'Paraguay', 0), (N'Perú', 0),
       (N'Uruguay', 0), (N'Venezuela', 0), (N'Otro', 0);

INSERT INTO CondicionAtencion (Descripcion)
VALUES ('Internado'), ('Ambulatorio'), ('Emergencia'), ('Otro');

INSERT INTO TipoIngreso (Descripcion)
VALUES ('Compra'), ('Donación recibida'), ('Devolución');

INSERT INTO UnidadMedida (Descripcion, Abreviatura)
VALUES ('Ampolla', 'amp'), ('Frasco', 'fco'), ('Caja', 'caja'),
       ('Comprimido', 'comp'), ('Vial', 'vial');

INSERT INTO Rol (Nombre, Descripcion)
VALUES ('Administrador', 'Acceso total, incluida la configuración de catálogos'),
       ('Operador',      'Registra pacientes y entregas, consulta historial');
GO

-- La aplicación compara esta versión al arrancar y avisa en el registro si la
-- base se creó con un esquema anterior.
IF EXISTS (SELECT 1 FROM sys.extended_properties
            WHERE class = 0 AND name = N'VersionEsquema')
    EXEC sp_updateextendedproperty @name = N'VersionEsquema', @value = N'2026-09-13';
ELSE
    EXEC sp_addextendedproperty @name = N'VersionEsquema', @value = N'2026-09-13';
GO


/* ═══════════════════════════════════════════════════════════════════════════
   12. VERIFICACIÓN DE LA INSTALACIÓN
   Confirma que todo se creó en la base correcta y en la cantidad esperada.
   Si algún número no coincide, algo falló antes y conviene revisarlo ahora y
   no cuando la aplicación no arranque.
   ═══════════════════════════════════════════════════════════════════════════ */

PRINT '';
PRINT '=========================================================';
PRINT CONCAT(' Base de datos activa : ', DB_NAME());
PRINT CONCAT(' Edición del motor    : ', CAST(SERVERPROPERTY('Edition') AS NVARCHAR(80)));
PRINT CONCAT(' Versión              : ', CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(40)));
PRINT '=========================================================';
PRINT '';

SELECT 'Tablas'                  AS Objeto, COUNT(*) AS Creados, 22 AS Esperados
  FROM sys.tables
UNION ALL
SELECT 'Vistas',                 COUNT(*), 3  FROM sys.views
UNION ALL
SELECT 'Procedimientos',         COUNT(*), 3  FROM sys.procedures
UNION ALL
SELECT 'Triggers',               COUNT(*), 3  FROM sys.triggers WHERE parent_class = 1
UNION ALL
SELECT 'Claves foráneas',        COUNT(*), 29 FROM sys.foreign_keys
UNION ALL
SELECT 'Restricciones CHECK',    COUNT(*), 17 FROM sys.check_constraints
UNION ALL
SELECT 'Filas en catálogos',     (SELECT COUNT(*) FROM Sexo)
                               + (SELECT COUNT(*) FROM CondicionAtencion)
                               + (SELECT COUNT(*) FROM TipoIngreso)
                               + (SELECT COUNT(*) FROM UnidadMedida)
                               + (SELECT COUNT(*) FROM Rol)
                               + (SELECT COUNT(*) FROM Pais), 31;
GO

PRINT '';
PRINT 'Esquema instalado. Próximo paso: iniciar la aplicación una vez para que';
PRINT 'cree el usuario administrador, y luego ejecutar 02-datos-prueba.sql.';
PRINT '';
GO
