/* ═══════════════════════════════════════════════════════════════════════════
   CATÁLOGOS OPERATIVOS
   Sistema de registro de pacientes y entrega de medicamentos donados

   Ejecutar en toda instalación después de 01-esquema.sql y
   02-catalogo-territorial.sql. Diagnostico es obligatorio en Atencion, por lo
   que la base no puede registrar entregas hasta cargar este catálogo.

   Requiere SQL Server 2019+. El preámbulo USE no es compatible con Azure SQL
   Database; allí debe quitarse y la conexión debe apuntar previamente a la
   base correcta.

   Es idempotente: agrega sólo valores ausentes y no modifica ni desactiva los
   valores existentes. No carga pacientes, atenciones ni inventario de prueba.

   Los códigos CIE-10 son un punto de partida y deben validarse antes de usarlos
   en informes oficiales. El catálogo puede corregirse desde Administración.
   ═══════════════════════════════════════════════════════════════════════════ */

USE DonacionMedicamentos;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY

/* ───────────────────────────────────────────────────────────────────────────
   1. ESTABLECIMIENTOS DE SALUD
   El establecimiento es opcional en Atencion. Los nombres sembrados son
   genéricos y pueden ampliarse o reemplazarse desde la aplicación.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO Establecimiento (Nombre)
SELECT v.Nombre
  FROM (VALUES
        (N'Instituto Oncológico'),
        (N'Hospital General'),
        (N'Hospital de Clínicas'),
        (N'Clínica Materno Infantil'),
        (N'Centro de Salud de referencia'),
        (N'Consulta privada'),
        (N'Sin derivación (viene por cuenta propia)')
       ) AS v(Nombre)
 WHERE NOT EXISTS (SELECT 1 FROM Establecimiento e WHERE e.Nombre = v.Nombre);

/* ───────────────────────────────────────────────────────────────────────────
   2. DIAGNÓSTICOS
   Lista inicial de tumores, complicaciones del tratamiento y otros motivos de
   consulta. Se amplía desde Administración.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO Diagnostico (Descripcion, CodigoCie10)
SELECT v.Descripcion, v.CodigoCie10
  FROM (VALUES
        -- Tumores sólidos
        (N'Tumor maligno de la mama',                      'C50.9'),
        (N'Tumor maligno del cuello del útero',            'C53.9'),
        (N'Tumor maligno del cuerpo del útero',            'C54.1'),
        (N'Tumor maligno del ovario',                      'C56'),
        (N'Tumor maligno de la próstata',                  'C61'),
        (N'Tumor maligno del estómago',                    'C16.9'),
        (N'Tumor maligno del colon',                       'C18.9'),
        (N'Tumor maligno del recto',                       'C20'),
        (N'Tumor maligno del hígado',                      'C22.0'),
        (N'Tumor maligno del páncreas',                    'C25.9'),
        (N'Tumor maligno de bronquios y pulmón',           'C34.9'),
        (N'Tumor maligno del esófago',                     'C15.9'),
        (N'Tumor maligno de la vesícula biliar',           'C23'),
        (N'Tumor maligno del riñón',                       'C64'),
        (N'Tumor maligno de la vejiga urinaria',           'C67.9'),
        (N'Tumor maligno del testículo',                   'C62.9'),
        (N'Tumor maligno del encéfalo',                    'C71.9'),
        (N'Tumor maligno de la glándula tiroides',         'C73'),
        (N'Tumor maligno de la piel (melanoma)',           'C43.9'),
        (N'Tumor maligno de hueso y cartílago articular',  'C41.9'),

        -- Hematológicos
        (N'Leucemia linfoblástica aguda',                  'C91.0'),
        (N'Leucemia mieloide aguda',                       'C92.0'),
        (N'Leucemia mieloide crónica',                     'C92.1'),
        (N'Leucemia linfocítica crónica',                  'C91.1'),
        (N'Linfoma de Hodgkin',                            'C81.9'),
        (N'Linfoma no Hodgkin',                            'C85.9'),
        (N'Mieloma múltiple',                              'C90.0'),

        -- Complicaciones del tratamiento
        (N'Neutropenia febril',                            'D70'),
        (N'Anemia secundaria a quimioterapia',             'D64.9'),
        (N'Trombocitopenia',                               'D69.6'),
        (N'Náusea y vómito inducidos por quimioterapia',   'R11'),
        (N'Mucositis oral',                                'K12.3'),
        (N'Dolor crónico oncológico',                      'R52.2'),
        (N'Infección sin foco definido',                   'A49.9'),
        (N'Deshidratación',                                'E86'),
        (N'Desnutrición asociada a enfermedad',            'E46'),

        -- Motivos de consulta que no son un tumor
        (N'Sesión de quimioterapia',                       'Z51.1'),
        (N'Sesión de radioterapia',                        'Z51.0'),
        (N'Control posterior al tratamiento',              'Z08'),
        (N'Cuidados paliativos',                           'Z51.5'),
        (N'Otro diagnóstico',                              NULL)
       ) AS v(Descripcion, CodigoCie10)
 WHERE NOT EXISTS (SELECT 1 FROM Diagnostico d WHERE d.Descripcion = v.Descripcion);

/* ───────────────────────────────────────────────────────────────────────────
   3. UNIDADES DE MEDIDA ADICIONALES
   Complementan las unidades base sembradas por 01-esquema.sql.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO UnidadMedida (Descripcion, Abreviatura)
SELECT v.Descripcion, v.Abreviatura
  FROM (VALUES
        (N'Bolsa',     N'bolsa'),
        (N'Jeringa',   N'jer'),
        (N'Sobre',     N'sobre'),
        (N'Tableta',   N'tab'),
        (N'Unidad',    N'unid')
       ) AS v(Descripcion, Abreviatura)
 WHERE NOT EXISTS (SELECT 1 FROM UnidadMedida u WHERE u.Descripcion = v.Descripcion);

COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/* ───────────────────────────────────────────────────────────────────────────
   VERIFICACIÓN
   ─────────────────────────────────────────────────────────────────────────── */

PRINT '';
PRINT '--- Catálogos operativos ---';

SELECT 'Establecimientos' AS Catalogo, COUNT(*) AS Filas FROM Establecimiento
UNION ALL
SELECT 'Diagnósticos',                 COUNT(*) FROM Diagnostico
UNION ALL
SELECT 'Diagnósticos con CIE-10',      COUNT(*) FROM Diagnostico WHERE CodigoCie10 IS NOT NULL
UNION ALL
SELECT 'Unidades de medida',           COUNT(*) FROM UnidadMedida;

PRINT '';
PRINT 'Catálogos operativos cargados. La base ya permite registrar atenciones.';
PRINT 'Próximo paso (sólo para demostración): 04-datos-demo-farmacia.sql';
PRINT '';
GO
