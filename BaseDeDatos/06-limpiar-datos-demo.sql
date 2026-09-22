/* ═══════════════════════════════════════════════════════════════════════════
   LIMPIEZA DE LOS DATOS DE DEMOSTRACIÓN

   Selecciona lo sembrado por 04-datos-demo-farmacia.sql y
   05-datos-demo-pacientes.sql mediante estas marcas reservadas:

       · pacientes con NumeroDocumento de exactamente siete dígitos en la serie
         99xxxxx
       · atenciones con NumeroFormulario 'DEMO-…'
       · lotes con NumeroLote 'DEMO-…'
       · archivos con ruta 'demo/…'
   Los medicamentos no se borran porque no existe una marca fiable que distinga
   los creados por la demostración de los creados desde la aplicación.

   No selecciona deliberadamente nada de esto:

       · el catálogo territorial (departamentos, provincias, municipios)
       · los catálogos operativos: diagnósticos, establecimientos, unidades
       · sexos, países, condiciones, tipos de ingreso, roles
       · los usuarios
       · filas que no coincidan con las marcas anteriores

   Una ficha real que use por coincidencia un documento reservado 99xxxxx sí
   entraría en la selección. Revisar los conteos antes de confirmar el script.

   Requiere SQL Server 2019+. El preámbulo USE no es compatible con Azure SQL
   Database; allí debe quitarse y la conexión debe apuntar a la base correcta.

   Es un borrado físico: revisar los conteos impresos y disponer de un respaldo
   antes de ejecutarlo sobre una base compartida.
   ═══════════════════════════════════════════════════════════════════════════ */

USE DonacionMedicamentos;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Los identificadores se capturan antes de borrar para reconocer todas las
   dependencias y sus filas de bitácora durante la transacción. */

DECLARE @Atenciones TABLE (Id INT PRIMARY KEY);
DECLARE @Pacientes  TABLE (Id INT PRIMARY KEY);
DECLARE @Lotes      TABLE (Id INT PRIMARY KEY);
DECLARE @Archivos   TABLE (Id INT PRIMARY KEY);

INSERT INTO @Atenciones SELECT IdAtencion  FROM Atencion  WHERE NumeroFormulario LIKE 'DEMO-%';
INSERT INTO @Pacientes  SELECT IdPaciente  FROM Paciente
 WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7;
INSERT INTO @Lotes      SELECT IdLote      FROM Lote      WHERE NumeroLote       LIKE 'DEMO-%';
INSERT INTO @Archivos   SELECT IdArchivo   FROM ArchivoDigital WHERE RutaAlmacenamiento LIKE 'demo/%';


-- PRINT no admite subconsultas: los conteos pasan antes por variables.
DECLARE @NPacientes  INT = (SELECT COUNT(*) FROM @Pacientes);
DECLARE @NAtenciones INT = (SELECT COUNT(*) FROM @Atenciones);
DECLARE @NLotes      INT = (SELECT COUNT(*) FROM @Lotes);
DECLARE @NArchivos   INT = (SELECT COUNT(*) FROM @Archivos);

PRINT CONCAT('A borrar: ', @NPacientes,  ' pacientes, ',
                           @NAtenciones, ' atenciones, ',
                           @NLotes,      ' lotes, ',
                           @NArchivos,   ' archivos.');

/* Una atención no marcada puede haber consumido un lote de demostración. En ese
   caso se aborta antes de borrar para preservar la entrega y su costo histórico. */
IF EXISTS (SELECT 1
             FROM ConsumoLote c
            WHERE c.IdLote IN (SELECT Id FROM @Lotes)
              AND c.IdAtencionDetalle NOT IN (SELECT d.IdAtencionDetalle
                                                FROM AtencionDetalle d
                                               WHERE d.IdAtencion IN (SELECT Id FROM @Atenciones)))
BEGIN
    RAISERROR ('Hay entregas reales que consumieron lotes de demostracion. Anule o revise esas entregas antes de limpiar: el script no puede borrar el inventario del que salieron.', 16, 1);
    RETURN;
END

BEGIN TRANSACTION;
BEGIN TRY

    /* Se borra desde lo que depende hacia lo que es dependido, para no chocar
       contra las claves foráneas. */

    /* Devolver el stock de los consumos antes de borrar los lotes: el trigger
       TR_ConsumoLote_ActualizarStock lo hace solo al eliminar cada consumo. */
    DELETE c
      FROM ConsumoLote c
      JOIN AtencionDetalle d ON d.IdAtencionDetalle = c.IdAtencionDetalle
     WHERE d.IdAtencion IN (SELECT Id FROM @Atenciones);

    DELETE FROM AtencionDetalle WHERE IdAtencion IN (SELECT Id FROM @Atenciones);

    /* TR_Atencion_ImpedirBorrado es INSTEAD OF DELETE: sin desactivarlo, el
       DELETE se convierte en una anulación y no borra nada. El trigger existe
       justamente para que nadie borre atenciones reales por descuido, así que
       se reactiva enseguida, y también si algo falla (ver el CATCH). */
    DISABLE TRIGGER TR_Atencion_ImpedirBorrado ON Atencion;

    DELETE FROM Atencion WHERE IdAtencion IN (SELECT Id FROM @Atenciones);

    ENABLE TRIGGER TR_Atencion_ImpedirBorrado ON Atencion;

    DELETE FROM PacienteDocumento WHERE IdPaciente IN (SELECT Id FROM @Pacientes);
    DELETE FROM Paciente          WHERE IdPaciente IN (SELECT Id FROM @Pacientes);
    DELETE FROM Lote              WHERE IdLote     IN (SELECT Id FROM @Lotes);

    /* Un respaldo exportado por la usuaria puede apuntar a un archivo de
       demostración. El registro del respaldo es trazabilidad y no se borra:
       se le suelta la referencia, que admite NULL. */
    UPDATE RespaldoExportacion
       SET IdArchivoGenerado = NULL
     WHERE IdArchivoGenerado IN (SELECT Id FROM @Archivos);

    DELETE FROM ArchivoDigital WHERE IdArchivo IN (SELECT Id FROM @Archivos);

    /* Los medicamentos permanecen porque no tienen una marca de demostración
       fiable. Los que queden sin referencias no afectan stock ni reportes y se
       pueden desactivar desde Administración. */

    /* Borra sólo la auditoría asociada a las filas identificadas como demo. */
    DELETE FROM Bitacora
     WHERE (TablaAfectada = 'Atencion' AND IdRegistroAfectado IN (SELECT Id FROM @Atenciones))
        OR (TablaAfectada = 'Paciente' AND IdRegistroAfectado IN (SELECT Id FROM @Pacientes))
        OR (TablaAfectada = 'Lote'     AND IdRegistroAfectado IN (SELECT Id FROM @Lotes));

    /* Reiniciar contadores SÓLO si la tabla quedó vacía. Reiniciarlos con
       datos reales adentro haría que el próximo registro chocara contra una
       clave ya usada. */
    IF NOT EXISTS (SELECT 1 FROM Atencion)          DBCC CHECKIDENT ('Atencion',          RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM AtencionDetalle)   DBCC CHECKIDENT ('AtencionDetalle',   RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM ConsumoLote)       DBCC CHECKIDENT ('ConsumoLote',       RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM Paciente)          DBCC CHECKIDENT ('Paciente',          RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM PacienteDocumento) DBCC CHECKIDENT ('PacienteDocumento', RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM ArchivoDigital)    DBCC CHECKIDENT ('ArchivoDigital',    RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM Lote)              DBCC CHECKIDENT ('Lote',              RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM Medicamento)       DBCC CHECKIDENT ('Medicamento',       RESEED, 0) WITH NO_INFOMSGS;
    IF NOT EXISTS (SELECT 1 FROM Bitacora)          DBCC CHECKIDENT ('Bitacora',          RESEED, 0) WITH NO_INFOMSGS;

    COMMIT TRANSACTION;

    PRINT 'Datos de demostracion eliminados. Catalogos, territorio y usuarios intactos.';

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    /* Reactivar el trigger aunque la limpieza haya fallado: dejarlo
       desactivado es mucho peor que no haber borrado nada, porque a partir de
       ahí cualquiera podría borrar atenciones reales sin que nada lo impida. */
    IF EXISTS (SELECT 1 FROM sys.triggers
                WHERE name = 'TR_Atencion_ImpedirBorrado' AND is_disabled = 1)
        ENABLE TRIGGER TR_Atencion_ImpedirBorrado ON Atencion;

    THROW;

END CATCH
GO

/* ───────────────────────────────────────────────────────────────────────────
   VERIFICACIÓN
   ─────────────────────────────────────────────────────────────────────────── */

PRINT '';
PRINT '--- Lo que quedo ---';

SELECT 'Pacientes de demostracion'  AS Concepto, COUNT(*) AS Quedan, 0 AS Esperado
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7
UNION ALL SELECT 'Atenciones de demostracion', COUNT(*), 0
  FROM Atencion WHERE NumeroFormulario LIKE 'DEMO-%'
UNION ALL SELECT 'Lotes de demostracion', COUNT(*), 0
  FROM Lote WHERE NumeroLote LIKE 'DEMO-%'
UNION ALL SELECT 'Archivos de demostracion', COUNT(*), 0
  FROM ArchivoDigital WHERE RutaAlmacenamiento LIKE 'demo/%'
UNION ALL SELECT 'Consumos de lote huerfanos', COUNT(*), 0
  FROM ConsumoLote c WHERE NOT EXISTS (SELECT 1 FROM Lote l WHERE l.IdLote = c.IdLote);

SELECT 'Municipios (catalogo territorial)' AS Concepto, COUNT(*) AS Conservados FROM Municipio
UNION ALL SELECT 'Diagnosticos',      COUNT(*) FROM Diagnostico
UNION ALL SELECT 'Establecimientos',  COUNT(*) FROM Establecimiento
UNION ALL SELECT 'Usuarios',          COUNT(*) FROM Usuario
UNION ALL SELECT 'Paises',            COUNT(*) FROM Pais;

SELECT 'Trigger de proteccion activo' AS Concepto,
       CASE WHEN is_disabled = 0 THEN 'SI' ELSE 'NO (revisar de inmediato)' END AS Estado
  FROM sys.triggers WHERE name = 'TR_Atencion_ImpedirBorrado';

PRINT '';
GO
