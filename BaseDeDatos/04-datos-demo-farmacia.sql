/* ═══════════════════════════════════════════════════════════════════════════
   DATOS DE DEMOSTRACIÓN — FARMACIA E INVENTARIO
   Sistema de registro de pacientes y entrega de medicamentos donados

   Carga medicamentos y lotes que ejercitan FIFO con dos y tres costos, lotes
   agotados, vencidos, próximos a vencer y un ingreso anulado. Los lotes
   anulados deben quedar fuera del stock, la valuación y el FIFO sin desaparecer
   del historial.

   NO ES PARA PRODUCCIÓN. Los medicamentos reales de la institución se cargan
   desde la aplicación. Para borrar todo esto: 06-limpiar-datos-demo.sql

   Requiere SQL Server 2019+. El preámbulo USE no es compatible con Azure SQL
   Database; allí debe quitarse y la conexión debe apuntar a la base correcta.

   Requisitos
   ---------------------------------------------------------------------------
   1. 01-esquema.sql, 02-catalogo-territorial.sql y 03-catalogos-operativos.sql
   2. Haber iniciado la aplicación una vez, para que cree el usuario
      administrador. La contraseña se deriva con PBKDF2 desde la aplicación,
      por eso el usuario no se siembra desde SQL.

   Cómo se reconocen los datos de demostración
   ---------------------------------------------------------------------------
   Todo lote de demostración usa un NumeroLote con prefijo 'DEMO-';
   06-limpiar-datos-demo.sql depende de esa marca.

   Las fechas son relativas al día de ejecución para conservar los escenarios
   de vencimiento y respetar CK_Lote_FechaIngreso.
   ═══════════════════════════════════════════════════════════════════════════ */

USE DonacionMedicamentos;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @IdUsuario INT = (SELECT TOP (1) IdUsuario FROM Usuario WHERE Activo = 1 ORDER BY IdUsuario);

IF @IdUsuario IS NULL
BEGIN
    RAISERROR ('No hay usuarios activos. Inicie la aplicacion una vez para que cree el administrador y vuelva a ejecutar este script.', 16, 1);
    RETURN;
END

IF EXISTS (SELECT 1 FROM Lote WHERE NumeroLote LIKE 'DEMO-%')
BEGIN
    RAISERROR ('Ya hay lotes de demostracion cargados. Ejecute 06-limpiar-datos-demo.sql antes de sembrar de nuevo.', 16, 1);
    RETURN;
END

/* «Bolsa» y Diagnostico prueban que se ejecutó 03-catalogos-operativos.sql.
   Sin «Bolsa», algunos medicamentos se insertarían silenciosamente sin unidad;
   sin diagnósticos, el script 05 no podría crear atenciones. */
IF NOT EXISTS (SELECT 1 FROM UnidadMedida WHERE Descripcion = N'Bolsa')
   OR NOT EXISTS (SELECT 1 FROM Diagnostico)
BEGIN
    RAISERROR ('Faltan los catalogos operativos. Ejecute antes 03-catalogos-operativos.sql.', 16, 1);
    RETURN;
END

DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

DECLARE @Compra    TINYINT = (SELECT IdTipoIngreso FROM TipoIngreso WHERE Descripcion = N'Compra');
DECLARE @Donacion  TINYINT = (SELECT IdTipoIngreso FROM TipoIngreso WHERE Descripcion = N'Donación recibida');
DECLARE @Devolucion TINYINT = (SELECT IdTipoIngreso FROM TipoIngreso WHERE Descripcion = N'Devolución');

DECLARE @Ampolla    TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Ampolla');
DECLARE @Frasco     TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Frasco');
DECLARE @Caja       TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Caja');
DECLARE @Comprimido TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Comprimido');
DECLARE @Vial       TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Vial');
DECLARE @Bolsa      TINYINT = (SELECT IdUnidadMedida FROM UnidadMedida WHERE Descripcion = N'Bolsa');

BEGIN TRANSACTION;
BEGIN TRY

/* ───────────────────────────────────────────────────────────────────────────
   1. MEDICAMENTOS
   Citostáticos, soporte hematológico y medicación de apoyo.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO Medicamento (Nombre, NombreGenerico, Concentracion, IdUnidadMedida)
SELECT v.Nombre, v.Generico, v.Concentracion, v.Unidad
  FROM (VALUES
        (N'L-asparaginasa',   N'Asparaginasa',      N'10.000 UI', @Frasco),
        (N'Filgrastim',       N'Filgrastim',        N'300 mcg',   @Ampolla),
        (N'Ondansetrón',      N'Ondansetrón',       N'8 mg',      @Ampolla),
        (N'Doxorrubicina',    N'Doxorrubicina',     N'50 mg',     @Frasco),
        (N'Metotrexato',      N'Metotrexato',       N'500 mg',    @Frasco),
        (N'Ciclofosfamida',   N'Ciclofosfamida',    N'1 g',       @Frasco),
        (N'Cisplatino',       N'Cisplatino',        N'50 mg',     @Vial),
        (N'Carboplatino',     N'Carboplatino',      N'450 mg',    @Vial),
        (N'Paclitaxel',       N'Paclitaxel',        N'300 mg',    @Vial),
        (N'Vincristina',      N'Vincristina',       N'1 mg',      @Vial),
        (N'Citarabina',       N'Citarabina',        N'500 mg',    @Frasco),
        (N'Rituximab',        N'Rituximab',         N'500 mg',    @Vial),
        (N'Trastuzumab',      N'Trastuzumab',       N'440 mg',    @Vial),
        (N'Imatinib',         N'Imatinib',          N'400 mg',    @Comprimido),
        (N'Tamoxifeno',       N'Tamoxifeno',        N'20 mg',     @Comprimido),
        (N'Dexametasona',     N'Dexametasona',      N'4 mg',      @Ampolla),
        (N'Morfina',          N'Sulfato de morfina',N'10 mg',     @Ampolla),
        (N'Tramadol',         N'Tramadol',          N'100 mg',    @Ampolla),
        (N'Omeprazol',        N'Omeprazol',         N'40 mg',     @Frasco),
        (N'Ceftriaxona',      N'Ceftriaxona',       N'1 g',       @Frasco),
        (N'Meropenem',        N'Meropenem',         N'500 mg',    @Frasco),
        (N'Fluconazol',       N'Fluconazol',        N'200 mg',    @Bolsa),
        (N'Enoxaparina',      N'Enoxaparina',       N'40 mg',     @Ampolla),
        (N'Suero fisiológico',N'Cloruro de sodio',  N'0,9% 500 ml', @Bolsa)
       ) AS v(Nombre, Generico, Concentracion, Unidad)
 WHERE NOT EXISTS (SELECT 1 FROM Medicamento m WHERE m.Nombre = v.Nombre);

/* ───────────────────────────────────────────────────────────────────────────
   2. LOTES
   La columna CantidadDisponible se escribe a mano acá porque estos lotes
   representan un histórico ya consumido en parte. En la aplicación real la
   mantiene el trigger TR_ConsumoLote_ActualizarStock.
   ─────────────────────────────────────────────────────────────────────────── */

DECLARE @L TABLE (
    Medicamento   NVARCHAR(120),
    Tipo          TINYINT,
    Numero        NVARCHAR(40),
    DiasIngreso   INT,           -- hace cuántos días entró (siempre positivo)
    DiasVence     INT,           -- en cuántos días vence (negativo = ya vencido)
    Ingresada     DECIMAL(10,2),
    Disponible    DECIMAL(10,2),
    Costo         DECIMAL(12,2),
    Origen        NVARCHAR(120),
    Factura       NVARCHAR(40)
);

INSERT INTO @L VALUES
    /* Filgrastim verifica FIFO con dos costos: 6 unidades deben valer
       1×70 + 5×150 = 820 Bs. */
    (N'Filgrastim',    @Compra,    N'DEMO-FIL-A',  760,  520,   5,   1,   70.00, N'Farmacia Central',       N'F-00123'),
    (N'Filgrastim',    @Donacion,  N'DEMO-FIL-B',  130,  540,  20,  20,  150.00, N'Empresa donante',        NULL),

    /* ── Tres precios para un mismo medicamento ────────────────────────────
       Una entrega grande de ondansetrón se reparte entre los tres lotes. */
    (N'Ondansetrón',   @Compra,    N'DEMO-OND-A',  600,  420,  40,   8,   10.00, N'Distribuidora Andina',   N'F-00654'),
    (N'Ondansetrón',   @Donacion,  N'DEMO-OND-B',  300,  500,  60,  60,   12.50, N'Colecta de farmacias',   NULL),
    (N'Ondansetrón',   @Compra,    N'DEMO-OND-C',   45,  700,  50,  50,   15.80, N'Distribuidora Andina',   N'F-00981'),

    /* ── Lote agotado: fuera del FIFO, presente en el kardex ───────────── */
    (N'Metotrexato',   @Donacion,  N'DEMO-MTX-A',  480,  365,  10,   0,  210.00, N'Fundación de apoyo',     NULL),
    (N'Metotrexato',   @Donacion,  N'DEMO-MTX-B',   90,  600,  15,  15,  240.00, N'Fundación de apoyo',     NULL),

    /* ── Vencidos: el tablero los separa del stock utilizable ──────────── */
    (N'Vincristina',   @Compra,    N'DEMO-VCR-X',  900,  -60,  12,   7,   95.00, N'Farmacia Central',       N'F-00301'),
    (N'Dexametasona',  @Donacion,  N'DEMO-DEX-X',  700, -140,  50,  22,    6.50, N'Donante particular',     NULL),

    /* ── Por vencer dentro de 60 días: el aviso del tablero ────────────── */
    (N'Citarabina',    @Donacion,  N'DEMO-CIT-A',  400,   25,  18,  18,  180.00, N'Fundación de apoyo',     NULL),
    (N'Ceftriaxona',   @Compra,    N'DEMO-CFT-A',  200,   40,  80,  64,   18.00, N'Distribuidora Andina',   N'F-00742'),
    (N'Omeprazol',     @Donacion,  N'DEMO-OMP-A',  150,   55, 100,  91,    9.00, N'Colecta de farmacias',   NULL),

    /* ── Inventario corriente ──────────────────────────────────────────── */
    (N'L-asparaginasa',@Donacion,  N'DEMO-ASP-A',  180,  380,  12,  12,  480.00, N'Fundación de apoyo',     NULL),
    (N'Doxorrubicina', @Compra,    N'DEMO-DOX-A',  355,  500,   8,   5,  320.00, N'Farmacia Central',       N'F-00456'),
    (N'Doxorrubicina', @Donacion,  N'DEMO-DOX-B',   60,  640,  10,  10,  365.00, N'Empresa donante',        NULL),
    (N'Ciclofosfamida',@Compra,    N'DEMO-CIC-A',  240,  450,  25,  19,  145.00, N'Distribuidora Andina',   N'F-00588'),
    (N'Cisplatino',    @Donacion,  N'DEMO-CIS-A',  120,  520,  16,  16,  260.00, N'Empresa donante',        NULL),
    (N'Carboplatino',  @Compra,    N'DEMO-CAR-A',   95,  610,  14,  14,  410.00, N'Farmacia Central',       N'F-00810'),
    (N'Paclitaxel',    @Donacion,  N'DEMO-PAC-A',  210,  430,   9,   9,  520.00, N'Fundación de apoyo',     NULL),
    (N'Rituximab',     @Donacion,  N'DEMO-RIT-A',   75,  580,   4,   4, 3200.00, N'Empresa donante',        NULL),
    (N'Trastuzumab',   @Donacion,  N'DEMO-TRA-A',   50,  600,   3,   3, 4100.00, N'Empresa donante',        NULL),
    (N'Imatinib',      @Compra,    N'DEMO-IMA-A',  160,  700, 120, 104,   38.00, N'Distribuidora Andina',   N'F-00669'),
    (N'Tamoxifeno',    @Donacion,  N'DEMO-TAM-A',  330,  480, 200, 176,    4.20, N'Colecta de farmacias',   NULL),
    (N'Morfina',       @Compra,    N'DEMO-MOR-A',  110,  540,  60,  47,   22.00, N'Farmacia Central',       N'F-00777'),
    (N'Tramadol',      @Donacion,  N'DEMO-TRM-A',  140,  500,  90,  78,   11.00, N'Donante particular',     NULL),
    (N'Meropenem',     @Compra,    N'DEMO-MER-A',   70,  660,  20,  20,   88.00, N'Distribuidora Andina',   N'F-00902'),
    (N'Fluconazol',    @Donacion,  N'DEMO-FLU-A',  190,  470,  30,  26,   34.00, N'Colecta de farmacias',   NULL),
    (N'Enoxaparina',   @Compra,    N'DEMO-ENO-A',   85,  590,  40,  33,   47.00, N'Farmacia Central',       N'F-00845'),
    (N'Suero fisiológico', @Donacion, N'DEMO-SUE-A', 35, 720, 300, 288,    6.00, N'Empresa donante',        NULL),
    (N'Citarabina',    @Compra,    N'DEMO-CIT-B',   20,  680,  10,  10,  195.00, N'Distribuidora Andina',   N'F-00995');

INSERT INTO Lote (IdMedicamento, IdTipoIngreso, NumeroLote, FechaIngreso, FechaVencimiento,
                  CantidadIngresada, CantidadDisponible, CostoUnitario, Origen,
                  NumeroFactura, IdUsuarioRegistro)
SELECT m.IdMedicamento,
       l.Tipo,
       l.Numero,
       DATEADD(DAY, -l.DiasIngreso, @Hoy),
       DATEADD(DAY,  l.DiasVence,   @Hoy),
       l.Ingresada,
       l.Disponible,
       l.Costo,
       l.Origen,
       l.Factura,
       @IdUsuario
  FROM @L l
  JOIN Medicamento m ON m.Nombre = l.Medicamento;

/* ───────────────────────────────────────────────────────────────────────────
   3. LOTE ANULADO
   Se carga un ingreso erróneo y su corrección. CK_Lote_Anulacion exige que
   estado, motivo, fecha y autor sean coherentes.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO Lote (IdMedicamento, IdTipoIngreso, NumeroLote, FechaIngreso, FechaVencimiento,
                  CantidadIngresada, CantidadDisponible, CostoUnitario, Origen,
                  NumeroFactura, IdUsuarioRegistro,
                  Anulado, MotivoAnulacion, FechaAnulacion, IdUsuarioAnulacion)
SELECT m.IdMedicamento, @Donacion, N'DEMO-CIC-ERR',
       DATEADD(DAY, -30, @Hoy), DATEADD(DAY, 400, @Hoy),
       500, 500, 145.00, N'Empresa donante', NULL, @IdUsuario,
       1,
       N'Cargado por error: la donación era de 50 frascos, no de 500. Se anula el ingreso completo y se vuelve a cargar con la cantidad correcta.',
       DATEADD(DAY, -29, SYSDATETIME()),
       @IdUsuario
  FROM Medicamento m
 WHERE m.Nombre = N'Ciclofosfamida';

/* El reingreso correcto, al día siguiente. */
INSERT INTO Lote (IdMedicamento, IdTipoIngreso, NumeroLote, FechaIngreso, FechaVencimiento,
                  CantidadIngresada, CantidadDisponible, CostoUnitario, Origen,
                  NumeroFactura, IdUsuarioRegistro)
SELECT m.IdMedicamento, @Donacion, N'DEMO-CIC-B',
       DATEADD(DAY, -29, @Hoy), DATEADD(DAY, 400, @Hoy),
       50, 50, 145.00, N'Empresa donante', NULL, @IdUsuario
  FROM Medicamento m
 WHERE m.Nombre = N'Ciclofosfamida';

COMMIT TRANSACTION;

/* ───────────────────────────────────────────────────────────────────────────
   VERIFICACIÓN
   Permanece en el mismo lote para que los RETURN de las precondiciones también
   omitan el mensaje de éxito.
   ─────────────────────────────────────────────────────────────────────────── */

PRINT '';
PRINT '--- Inventario de demostracion ---';

SELECT 'Medicamentos'                   AS Concepto, COUNT(*) AS Cantidad FROM Medicamento
UNION ALL
SELECT 'Lotes de demostracion',         COUNT(*) FROM Lote WHERE NumeroLote LIKE 'DEMO-%'
UNION ALL
SELECT 'Lotes anulados',                COUNT(*) FROM Lote WHERE NumeroLote LIKE 'DEMO-%' AND Anulado = 1
UNION ALL
SELECT 'Lotes agotados',                COUNT(*) FROM Lote WHERE NumeroLote LIKE 'DEMO-%' AND CantidadDisponible = 0
UNION ALL
SELECT 'Lotes vencidos',                COUNT(*) FROM Lote
 WHERE NumeroLote LIKE 'DEMO-%' AND FechaVencimiento < CAST(GETDATE() AS DATE)
UNION ALL
SELECT 'Lotes por vencer (60 dias)',    COUNT(*) FROM Lote
 WHERE NumeroLote LIKE 'DEMO-%' AND Anulado = 0 AND CantidadDisponible > 0
   AND FechaVencimiento BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 60, CAST(GETDATE() AS DATE));

PRINT '';
PRINT '--- El caso de la cliente: Filgrastim a dos precios ---';

SELECT NumeroLote, FechaIngreso, CantidadDisponible, CostoUnitario
  FROM Lote
 WHERE NumeroLote LIKE 'DEMO-FIL-%'
 ORDER BY FechaIngreso;

PRINT '';
PRINT 'Inventario de demostracion cargado.';
PRINT 'Proximo paso: 05-datos-demo-pacientes.sql';
PRINT '';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
