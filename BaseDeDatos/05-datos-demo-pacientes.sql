/* ═══════════════════════════════════════════════════════════════════════════
   DATOS DE DEMOSTRACIÓN — PACIENTES Y ATENCIONES
   Sistema de registro de pacientes y entrega de medicamentos donados

   Carga 81 pacientes y 131 atenciones de los últimos 14 meses. Incluye origen
   distinto de residencia, ocho orígenes no informados, seis pacientes del
   exterior y 29 direcciones desglosadas. También combina entregas manuales,
   FIFO y seis atenciones anuladas.

   Con los cortes predeterminados 2 / 5 / 10, el mapa debe mostrar:

           Santa Cruz  88   rojo      (demanda muy alta, 11 o más)
           Cochabamba   8   naranja   (demanda alta, 6 a 10)
           La Paz       6   naranja
           Chuquisaca   4   amarillo  (demanda moderada, 3 a 5)
           Tarija       3   amarillo
           Beni         2   verde     (demanda baja, 1 a 2)
           Potosí       2   verde
           Pando        1   verde
           Oruro        0   gris      (sin registros)

       Además hay 7 atenciones del exterior y 4 sin ubicación; el mapa las
       informa fuera del coroplético. La verificación final consulta estos datos
       directamente de la base.

   NO ES PARA PRODUCCIÓN. Para borrar todo: 06-limpiar-datos-demo.sql

   Requiere SQL Server 2019+. El preámbulo USE no es compatible con Azure SQL
   Database; allí debe quitarse y la conexión debe apuntar a la base correcta.

   Requisitos
   ---------------------------------------------------------------------------
   01-esquema.sql → 02-catalogo-territorial.sql → 03-catalogos-operativos.sql
   → 04-datos-demo-farmacia.sql, y haber iniciado la aplicación una vez.

   Marcas usadas por 06-limpiar-datos-demo.sql: documento de siete dígitos en
   la serie 99xxxxx, NumeroFormulario con prefijo 'DEMO-' y ruta 'demo/'.
   ═══════════════════════════════════════════════════════════════════════════ */

USE DonacionMedicamentos;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @IdUsuario INT = (SELECT TOP (1) IdUsuario FROM Usuario WHERE Activo = 1 ORDER BY IdUsuario);

IF @IdUsuario IS NULL
BEGIN
    RAISERROR ('No hay usuarios activos. Inicie la aplicacion una vez para que cree el administrador.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM Municipio)
BEGIN
    RAISERROR ('Falta el catalogo territorial. Ejecute antes 02-catalogo-territorial.sql.', 16, 1);
    RETURN;
END

-- Por la marca EsLocal y no por nombre ni Id fijo, igual que la aplicación.
DECLARE @IdPaisLocal SMALLINT = (SELECT IdPais FROM Pais WHERE EsLocal = 1);

IF @IdPaisLocal IS NULL
BEGIN
    RAISERROR ('Ningun pais del catalogo esta marcado como local (Pais.EsLocal = 1). Sin el no se puede asignar el pais de origen.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM Diagnostico)
BEGIN
    RAISERROR ('Faltan los catalogos operativos. Ejecute antes 03-catalogos-operativos.sql.', 16, 1);
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM Lote WHERE NumeroLote LIKE 'DEMO-%')
BEGIN
    RAISERROR ('Falta el inventario de demostracion. Ejecute antes 04-datos-demo-farmacia.sql.', 16, 1);
    RETURN;
END

/* La marca exige exactamente siete dígitos: usar sólo LIKE '99%' podría
   confundir un documento real con datos de demostración. */
IF EXISTS (SELECT 1 FROM Paciente
            WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]'
              AND LEN(NumeroDocumento) = 7)
BEGIN
    RAISERROR ('Ya hay pacientes de demostracion cargados. Ejecute 06-limpiar-datos-demo.sql antes de sembrar de nuevo.', 16, 1);
    RETURN;
END

DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

DECLARE @Femenino  TINYINT = (SELECT IdSexo FROM Sexo WHERE Descripcion = N'Femenino');
DECLARE @Masculino TINYINT = (SELECT IdSexo FROM Sexo WHERE Descripcion = N'Masculino');

/* ───────────────────────────────────────────────────────────────────────────
   1. LOS PACIENTES
   IneRes  = municipio donde vive hoy
   IneOri  = municipio del que ES (NULL = sin cargar, o paciente del exterior)
   Pais    = sólo para pacientes del exterior; excluye el municipio de origen.
             Con IneOri cargado, el alta asigna el país local.
   Visitas = cuántas atenciones se le generan más abajo
   ─────────────────────────────────────────────────────────────────────────── */

DECLARE @Pac TABLE (
    Rn         INT IDENTITY(1,1),
    Doc        VARCHAR(20),
    Nombres    NVARCHAR(80),
    ApPat      NVARCHAR(60),
    ApMat      NVARCHAR(60),
    Nacimiento DATE,
    Sexo       CHAR(1),
    Telefono   VARCHAR(20),
    IneRes     VARCHAR(6),
    IneOri     VARCHAR(6),
    Pais       NVARCHAR(60),
    Zona       NVARCHAR(120),
    Calle      NVARCHAR(120),
    Nro        NVARCHAR(20),
    Direccion  NVARCHAR(250),
    Visitas    INT,
    IdPaciente INT NULL
);

INSERT INTO @Pac (Doc, Nombres, ApPat, ApMat, Nacimiento, Sexo, Telefono,
                  IneRes, IneOri, Pais, Zona, Calle, Nro, Direccion, Visitas)
VALUES
    ('9900001', N'Elmer', N'Mamani', N'Jiménez', '1950-11-10', 'M', NULL, '070102', '070105', NULL, NULL, NULL, NULL, N'Villa Rosario, Av. Paraguá', 4),
    ('9900002', N'Lourdes Fabiola', N'Saucedo', N'Parada', '1994-04-18', 'F', '73123018', '071001', '070101', NULL, NULL, NULL, NULL, N'Barrio Lindo, Calle Warnes', 3),
    ('9900003', N'Erika', N'Zabala', N'Colque', '1986-02-09', 'F', '72093864', '070101', '070102', NULL, NULL, NULL, NULL, N'Plan Tres Mil, Av. Cristo Redentor', 5),
    ('9900004', N'Fernando Abel', N'Aguilera', N'Zabala', '1988-03-21', 'M', NULL, '070101', '070101', NULL, NULL, NULL, NULL, N'Las Palmas, Av. Alemana', 2),
    ('9900005', N'Roberto', N'Guzmán', N'Céspedes', '2023-02-23', 'M', '71748053', '070102', '070102', NULL, N'Villa Fátima', N'Av. Virgen de Cotoca', N'1605', NULL, 6),
    ('9900006', N'Betty Juana', N'Guzmán', N'Roca', '2016-09-02', 'F', '79747129', '070105', '070104', NULL, NULL, NULL, NULL, N'San Aurelio, Calle Bolívar', 1),
    ('9900007', N'Roxana Mariela', N'Cuéllar', N'Moreno', '1961-02-23', 'F', '73440449', '070104', '070201', NULL, N'Nuevo Palmar', N'Calle Ballivián', N'667', N'esquina, tienda de barrio', 3),
    ('9900008', N'Ximena', N'Pérez', N'Gutiérrez', '2017-06-07', 'F', '77214535', '070101', '070101', NULL, N'Barrio Obrero', N'Calle 21 de Mayo', N'4465', N'portón azul, entrada por el pasillo', 2),
    ('9900009', N'Mauricio', N'Zabala', N'Montaño', '2022-03-19', 'M', NULL, '070102', '070101', NULL, NULL, NULL, NULL, N'San Aurelio, Av. Paraguá', 4),
    ('9900010', N'Willy Óscar', N'Arce', N'Ribera', '2024-03-15', 'M', '78868723', '070105', '070201', NULL, N'El Carmen', N'Calle 21 de Mayo', N'2984', N'frente a la escuela', 3),
    ('9900011', N'Teresa', N'Flores', N'Salazar', '1996-08-28', 'F', NULL, '070105', '070201', NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Beni', 2),
    ('9900012', N'Douglas', N'Moreno', N'Tordoya', '1998-07-23', 'M', '75735654', '070105', '071001', NULL, N'Las Palmas', N'Calle Warnes', N'122', N'esquina, tienda de barrio', 1),
    ('9900013', N'Norma', N'Montaño', N'Guzmán', '1998-01-17', 'F', '75214739', '071001', '070201', NULL, NULL, NULL, NULL, N'Las Palmas, Av. Santos Dumont', 3),
    ('9900014', N'Ana Vania', N'Quispe', N'Áñez', '1970-05-15', 'F', '76925740', '070105', '071001', NULL, N'El Bajío', N'Calle Warnes', N'328', NULL, 2),
    ('9900015', N'Daniela', N'Gutiérrez', N'Colque', '1991-05-20', 'F', '77813643', '070101', '070201', NULL, N'San Aurelio', N'Calle 21 de Mayo', N'3265', N'casa con reja blanca', 4),
    ('9900016', N'Noelia', N'Saucedo', N'Jiménez', '1958-05-13', 'F', '79374834', '070201', '071001', NULL, NULL, NULL, NULL, N'Guapilo, Av. Banzer', 2),
    ('9900017', N'Ana', N'Dorado', N'Roca', '1948-02-26', 'F', '70554491', '071001', '070105', NULL, NULL, NULL, NULL, N'Guapilo, Av. Banzer', 3),
    ('9900018', N'Abel Douglas', N'Áñez', N'Parada', '1947-11-12', 'M', '79829033', '070105', '070101', NULL, N'El Carmen', N'Av. Cristo Redentor', N'665', N'portón azul, entrada por el pasillo', 1),
    ('9900019', N'Juan Carlos', N'Ferrufino', N'Terceros', '1979-07-08', 'M', '79851728', '070201', '071001', NULL, N'Las Palmas', N'Calle Quijarro', N'3660', N'frente a la escuela', 2),
    ('9900020', N'Ana', N'Condori', N'Sosa', '2008-12-17', 'F', '74035317', '070101', '070101', NULL, N'La Morita', N'Av. Virgen de Cotoca', N'4553', N'a media cuadra del mercado', 5),
    ('9900021', N'Abel', N'Ledezma', N'Vaca', '2016-01-23', 'M', '72365205', '070201', '070101', NULL, NULL, NULL, NULL, N'Nuevo Palmar, Calle Warnes', 1),
    ('9900022', N'Yola', N'Barba', N'Gil', '1963-04-27', 'F', '75865164', '070101', '070101', NULL, NULL, NULL, NULL, N'San Aurelio, Av. Paraguá', 2),
    ('9900023', N'Ramiro', N'Peña', N'Vargas', '1972-08-17', 'M', '76912858', '070201', '070104', NULL, NULL, NULL, NULL, N'Equipetrol, Calle Sucre', 3),
    ('9900024', N'Freddy Cristian', N'Choque', N'Melgar', '2013-05-23', 'M', '76549668', '070201', '070101', NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Virgen de Cotoca', 1),
    ('9900025', N'Rolando', N'Moreno', N'Choque', '1984-10-13', 'M', '78062950', '070101', '070101', NULL, N'Barrio Obrero', N'Calle Warnes', N'3024', N'detrás de la posta de salud', 4),
    ('9900026', N'Carla Rina', N'Colque', N'Quispe', '1980-05-11', 'F', '74501145', '070201', '070104', NULL, NULL, NULL, NULL, N'Barrio Central, Av. Grigotá', 2),
    ('9900027', N'Dennis', N'Céspedes', N'Justiniano', '1965-01-06', 'M', NULL, '070101', '070101', NULL, N'Equipetrol', N'Calle Junín', N'2318', NULL, 1),
    ('9900028', N'Rina', N'Montaño', N'Gil', '2015-07-10', 'F', '70830431', '070101', '071001', NULL, N'Las Palmas', N'Calle Quijarro', N'78', NULL, 3),
    ('9900029', N'Iván', N'Ferrufino', N'Montaño', '2023-02-05', 'M', '78728498', '070104', '070201', NULL, NULL, NULL, NULL, N'Las Palmas, Calle Warnes', 2),
    ('9900030', N'Paola', N'Ribera', N'Dorado', '2017-03-28', 'F', '74219789', '070201', '070101', NULL, N'Los Lotes', N'Calle 21 de Mayo', N'4607', NULL, 1),
    ('9900031', N'Lucía', N'Fernández', N'Roca', '2009-09-01', 'F', '71926510', '070101', '070201', NULL, NULL, NULL, NULL, N'Guapilo, Av. Santos Dumont', 0),
    ('9900032', N'Teresa Mónica', N'Quispe', N'Cuéllar', '2011-07-15', 'F', '70852931', '070101', '070105', NULL, NULL, NULL, NULL, N'Equipetrol, Av. Virgen de Cotoca', 0),
    ('9900033', N'Elena', N'Peña', N'Arce', '2020-02-06', 'F', '70483700', '071001', '071001', NULL, N'San Aurelio', N'Calle Warnes', N'4156', N'casa de dos pisos, portón verde', 0),
    ('9900034', N'Mauricio', N'Saucedo', N'Rojas', '1983-04-12', 'M', '73272222', '070102', '070102', NULL, NULL, NULL, NULL, N'Barrio Central, Calle Ballivián', 0),
    ('9900035', N'Elmer', N'Jiménez', N'Ribera', '1983-07-27', 'M', '70069595', '070101', '070201', NULL, N'Los Lotes', N'Av. Beni', N'1420', NULL, 0),
    ('9900036', N'Miriam Rosa', N'Banegas', N'Zabala', '2004-02-07', 'F', '78570676', '070102', '070101', NULL, NULL, NULL, NULL, N'Equipetrol, Calle Ingavi', 0),
    ('9900037', N'Teresa', N'Guzmán', N'Rojas', '1987-02-16', 'F', '79677921', '070104', '070105', NULL, N'Pampa de la Isla', N'Calle 21 de Mayo', N'368', N'detrás de la posta de salud', 0),
    ('9900038', N'Erika', N'Villarroel', N'Áñez', '1963-12-22', 'F', '73781959', '071001', '070105', NULL, NULL, NULL, NULL, N'Guapilo, Av. Santos Dumont', 0),
    ('9900039', N'Mariela Verónica', N'Condori', N'Salazar', '2023-04-28', 'F', '72521757', '070102', '070101', NULL, NULL, NULL, NULL, N'El Carmen, Calle Warnes', 0),
    ('9900040', N'Mario', N'Aguilera', N'Camacho', '1960-03-15', 'M', '70558878', '070101', '070201', NULL, N'Villa Rosario', N'Calle Sucre', N'104', N'a media cuadra del mercado', 0),
    ('9900041', N'Rosa', N'Ferrufino', N'Villarroel', '2002-06-13', 'F', '73918607', '070105', '070101', NULL, NULL, NULL, NULL, N'Equipetrol, Calle 21 de Mayo', 0),
    ('9900042', N'Ana', N'Villarroel', N'Parada', '1967-11-18', 'F', '72997387', '071001', '071001', NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Alemana', 0),
    ('9900043', N'Gabriela', N'Zabala', N'Peña', '2019-12-24', 'F', NULL, '070104', NULL, NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Grigotá', 2),
    ('9900044', N'Gonzalo Douglas', N'Chávez', N'Vaca', '1955-10-10', 'M', '74859808', '070101', NULL, NULL, NULL, NULL, NULL, N'El Bajío, Av. Grigotá', 1),
    ('9900045', N'Lidia', N'Rojas', N'Parada', '2023-12-19', 'F', '73795639', '070101', NULL, NULL, NULL, NULL, NULL, N'Villa Primero de Mayo, Calle 21 de Mayo', 3),
    ('9900046', N'Mario', N'Condori', N'Tordoya', '1998-03-12', 'M', '73161059', '070104', NULL, NULL, NULL, NULL, NULL, N'Equipetrol, Av. Paraguá', 1),
    ('9900047', N'Abel Javier', N'Roca', N'Guzmán', '2016-08-27', 'M', '74955833', '070105', NULL, NULL, NULL, NULL, NULL, N'Villa Primero de Mayo, Av. Grigotá', 2),
    ('9900048', N'Gustavo', N'Hurtado', N'Guzmán', '1944-05-18', 'M', '74787270', '070101', NULL, NULL, NULL, NULL, NULL, N'Santa Rosita, Calle Ballivián', 1),
    ('9900049', N'Norma Carla', N'Cuéllar', N'Saucedo', '2017-01-14', 'F', '75507391', '070104', NULL, NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Beni', 1),
    ('9900050', N'Gustavo', N'Cuéllar', N'Ribera', '1948-06-11', 'M', '70349677', '070104', NULL, NULL, N'Pampa de la Isla', N'Av. Virgen de Cotoca', N'2049', N'casa con reja blanca', 2),
    ('9900051', N'Carlos', N'Salazar', N'Choque', '1963-11-15', 'M', '77552187', '030101', '030101', NULL, NULL, NULL, NULL, N'El Carmen, Calle 21 de Mayo', 3),
    ('9900052', N'Fernando Iván', N'Mamani', N'Salazar', '1989-02-15', 'M', NULL, '030901', '030901', NULL, NULL, NULL, NULL, N'El Bajío, Calle Sucre', 2),
    ('9900053', N'Limbert Ronald', N'Ferrufino', N'Tordoya', '1952-06-14', 'M', '71967683', '070101', '031001', NULL, NULL, NULL, NULL, N'Las Palmas, Calle Bolívar', 3),
    ('9900054', N'Ronald', N'Villarroel', N'Coímbra', '1995-10-02', 'M', '71143694', '020101', '020101', NULL, N'Villa Fátima', N'Calle Quijarro', N'1560', N'frente a la escuela', 4),
    ('9900055', N'Roberto', N'Jiménez', N'Sosa', '1940-02-13', 'M', '73196930', '020105', '020105', NULL, NULL, NULL, NULL, N'Santa Rosita, Calle 21 de Mayo', 2),
    ('9900056', N'Claudia Carmen', N'Terceros', N'Guzmán', '1969-11-01', 'F', '71401590', '071001', '020801', NULL, NULL, NULL, NULL, N'Guapilo, Av. Cristo Redentor', 1),
    ('9900057', N'Juan', N'Ledezma', N'Zabala', '2000-08-26', 'M', '79025878', '070101', '010101', NULL, NULL, NULL, NULL, N'Villa Primero de Mayo, Calle Ballivián', 3),
    ('9900058', N'Nelson', N'Gutiérrez', N'Dorado', '1977-10-19', 'M', '73677557', '010101', '010101', NULL, NULL, NULL, NULL, N'Nuevo Palmar, Calle Ingavi', 1),
    ('9900059', N'Rubén', N'Terceros', N'Coímbra', '2016-01-27', 'M', '77807808', '070101', '060101', NULL, NULL, NULL, NULL, N'El Carmen, Av. Santos Dumont', 2),
    ('9900060', N'Wilson', N'Zabala', N'Ribera', '1991-04-11', 'M', '70424321', '060101', '060301', NULL, N'Equipetrol', N'Av. Alemana', N'4691', NULL, 1),
    ('9900061', N'Mario', N'Rojas', N'Aguilera', '1971-03-12', 'M', '77566307', '071001', '080101', NULL, NULL, NULL, NULL, N'Barrio Obrero, Av. Paraguá', 2),
    ('9900062', N'Nelson', N'Justiniano', N'Ribera', '1947-12-16', 'M', '77534646', '070101', '050101', NULL, N'Pampa de la Isla', N'Calle Warnes', N'1437', NULL, 1),
    ('9900063', N'Marisol', N'Quispe', N'Terceros', '1941-11-22', 'F', '72375995', '050101', '050801', NULL, N'Los Lotes', N'Calle Ingavi', N'3026', NULL, 1),
    ('9900064', N'Douglas', N'Choque', N'Méndez', '1940-09-28', 'M', '74505887', '070101', '090101', NULL, NULL, NULL, NULL, N'El Carmen, Av. Cristo Redentor', 1),
    ('9900065', N'Fabiola Silvia', N'Egüez', N'Guzmán', '2024-11-04', 'F', '71356870', '040101', '040101', NULL, NULL, NULL, NULL, N'Villa Rosario, Av. Grigotá', 0),
    ('9900066', N'Nancy', N'Dorado', N'Egüez', '2019-06-02', 'F', '78096549', '030101', '030101', NULL, NULL, NULL, NULL, N'Equipetrol, Av. Santos Dumont', 0),
    ('9900067', N'Pedro Cristian', N'Flores', N'Montaño', '1977-08-11', 'M', '78776477', '020101', '020101', NULL, N'Pampa de la Isla', N'Av. Paraguá', N'2468', N'detrás de la posta de salud', 0),
    ('9900068', N'Abel', N'Suárez', N'Pérez', '1998-10-02', 'M', '77338682', '010101', '010101', NULL, NULL, NULL, NULL, N'Equipetrol, Calle Ingavi', 0),
    ('9900069', N'Israel', N'Hurtado', N'Salazar', '2021-09-14', 'M', '79661801', '060101', '060101', NULL, NULL, NULL, NULL, N'Las Palmas, Calle 21 de Mayo', 0),
    ('9900070', N'Jorge', N'Choque', N'Apaza', '2022-08-25', 'M', '73181219', '080101', '080201', NULL, N'Equipetrol', N'Calle Ballivián', N'1289', NULL, 0),
    ('9900071', N'Rocío Isabel', N'Hurtado', N'Flores', '1994-07-21', 'F', '79645545', '050101', '050101', NULL, N'Barrio Lindo', N'Av. Grigotá', N'4063', N'frente a la escuela', 0),
    ('9900072', N'Noelia', N'Moreno', N'Saucedo', '2007-07-17', 'F', '78900849', '070101', NULL, N'Venezuela', N'Barrio Lindo', N'Calle Bolívar', N'2963', N'frente a la escuela', 3),
    ('9900073', N'Miriam', N'Parada', N'Ferrufino', '1971-08-23', 'F', '73994867', '070101', NULL, N'Cuba', N'Santa Rosita', N'Av. Alemana', N'3820', NULL, 2),
    ('9900074', N'Fernando Cristian', N'Zabala', N'Saucedo', '1941-10-01', 'M', '70117990', '071001', NULL, N'Brasil', NULL, NULL, NULL, N'Pampa de la Isla, Av. Grigotá', 1),
    ('9900075', N'Mauricio', N'Arce', N'Pérez', '2020-06-19', 'M', '70634852', '060101', NULL, N'Argentina', NULL, NULL, NULL, N'Santa Rosita, Calle Quijarro', 1),
    ('9900076', N'Norma', N'Montaño', N'Dorado', '1960-01-11', 'F', '76192416', '020101', NULL, N'Perú', NULL, NULL, NULL, N'Barrio Central, Calle 21 de Mayo', 1),
    ('9900077', N'Miriam', N'Villarroel', N'Zabala', '2008-08-11', 'F', '79884028', '070101', NULL, N'Colombia', N'Barrio Central', N'Calle Warnes', N'1420', N'frente a la escuela', 0),
    ('9900078', N'Carla Verónica', N'Ferrufino', N'Tordoya', '1992-11-18', 'F', '71285974', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2),
    ('9900079', N'Norma Mariela', N'Suárez', N'Justiniano', '1952-02-13', 'F', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1),
    ('9900080', N'Dennis', N'Gutiérrez', N'Banegas', '2005-06-07', 'M', '71236256', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1),
    ('9900081', N'Mario', N'Landívar', N'Peña', '2018-07-12', 'M', '70187748', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0);

BEGIN TRANSACTION;
BEGIN TRY

/* ───────────────────────────────────────────────────────────────────────────
   2. ALTA DE PACIENTES
   Los municipios se resuelven por CodigoINE contra el catálogo territorial, no
   por nombre: hay municipios homónimos en departamentos distintos.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO Paciente (NumeroDocumento, ExtensionDoc, Nombres, ApellidoPaterno,
                      ApellidoMaterno, FechaNacimiento, IdSexo, Telefono,
                      IdMunicipio, Zona, Calle, NumeroDomicilio, Direccion,
                      IdMunicipioOrigen, IdPaisOrigen, Observaciones, IdUsuarioRegistro)
SELECT p.Doc,
       CASE WHEN p.IneRes IS NULL THEN NULL ELSE
            CASE LEFT(p.IneRes, 2)
                 WHEN '01' THEN 'CH' WHEN '02' THEN 'LP' WHEN '03' THEN 'CB'
                 WHEN '04' THEN 'OR' WHEN '05' THEN 'PT' WHEN '06' THEN 'TJ'
                 WHEN '07' THEN 'SC' WHEN '08' THEN 'BE' ELSE 'PD' END END,
       p.Nombres, p.ApPat, p.ApMat, p.Nacimiento,
       CASE WHEN p.Sexo = 'F' THEN @Femenino ELSE @Masculino END,
       p.Telefono,
       mr.IdMunicipio, p.Zona, p.Calle, p.Nro, p.Direccion,
       mo.IdMunicipio,
       /* Un municipio de origen implica el país local, como al guardar desde
          la aplicación: con el país en NULL la ficha queda fuera del filtro
          «Bolivia» de las estadísticas. */
       COALESCE(pa.IdPais, CASE WHEN mo.IdMunicipio IS NOT NULL THEN @IdPaisLocal END),
       N'Dato de demostración.',
       @IdUsuario
  FROM @Pac p
  LEFT JOIN Municipio mr ON mr.CodigoINE = p.IneRes
  LEFT JOIN Municipio mo ON mo.CodigoINE = p.IneOri
  LEFT JOIN Pais      pa ON pa.Nombre    = p.Pais;

UPDATE p
   SET p.IdPaciente = pa.IdPaciente
  FROM @Pac p
  JOIN Paciente pa ON pa.NumeroDocumento = p.Doc;

/* Se comprueban los códigos, no el resultado del INSERT: como IdMunicipio
   admite NULL y el JOIN es LEFT, un catálogo territorial incompleto insertaría
   igual a los 81 pacientes, con el municipio en blanco y un mapa callado y
   equivocado. Mirar el INSERT no detectaría nada. */
IF EXISTS (SELECT 1 FROM @Pac p
            WHERE (p.IneRes IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM Municipio m WHERE m.CodigoINE = p.IneRes))
               OR (p.IneOri IS NOT NULL
                   AND NOT EXISTS (SELECT 1 FROM Municipio m WHERE m.CodigoINE = p.IneOri)))
    THROW 50020, N'El catálogo territorial está incompleto: falta algún municipio que usan los datos de demostración. Ejecute 02-catalogo-territorial.sql.', 1;

IF EXISTS (SELECT 1 FROM @Pac WHERE IdPaciente IS NULL)
    THROW 50024, N'Algún paciente no se insertó.', 1;

/* Un paciente del exterior no puede tener municipio de origen: el catálogo
   territorial es boliviano. La aplicación mantiene esa coherencia al guardar;
   acá se verifica que los datos sembrados la respeten. Los pacientes de acá
   también llevan país, así que se mira EsLocal y no sólo si hay uno cargado. */
IF EXISTS (SELECT 1 FROM Paciente p
             JOIN Pais pa ON pa.IdPais = p.IdPaisOrigen
            WHERE p.NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(p.NumeroDocumento) = 7
              AND pa.EsLocal = 0
              AND p.IdMunicipioOrigen IS NOT NULL)
    THROW 50021, N'Hay un paciente del exterior con municipio de origen.', 1;

/* ───────────────────────────────────────────────────────────────────────────
   3. CARNETS ESCANEADOS
   Las filas de ArchivoDigital existen pero no hay imágenes detrás: al intentar
   verlas la aplicación avisa que el archivo no está en disco, y es lo esperado
   en datos de demostración.
   ─────────────────────────────────────────────────────────────────────────── */

INSERT INTO ArchivoDigital (NombreOriginal, RutaAlmacenamiento, TipoMime,
                            TamanoBytes, HashSha256, IdUsuarioCarga)
SELECT CONCAT('carnet-', p.Doc, '.jpg'),
       CONCAT('demo/carnets/', p.Doc, '.jpg'),
       'image/jpeg',
       150000 + (p.Rn * 137) % 90000,
       HASHBYTES('SHA2_256', CONCAT('demo-carnet-', p.Doc)),
       @IdUsuario
  FROM @Pac p
 WHERE p.Rn % 4 <> 0;          -- tres de cada cuatro tienen carnet cargado

/* El vínculo con el paciente se arma por la ruta del archivo, que lleva su
   número de documento: en un INSERT, OUTPUT sólo puede leer columnas de
   INSERTED y no las de la tabla de origen. */
INSERT INTO PacienteDocumento (IdPaciente, IdArchivo, Vigente)
SELECT p.IdPaciente, a.IdArchivo, 1
  FROM ArchivoDigital a
  JOIN @Pac p ON a.RutaAlmacenamiento = CONCAT('demo/carnets/', p.Doc, '.jpg')
 WHERE a.RutaAlmacenamiento LIKE 'demo/carnets/%';

/* ───────────────────────────────────────────────────────────────────────────
   4. ATENCIONES Y ENTREGAS
   Se recorre paciente por paciente creando sus visitas. Las fechas se reparten
   en los últimos 420 días con aritmética modular: el resultado es siempre el
   mismo, así que dos instalaciones distintas muestran exactamente los mismos
   números y se pueden comparar.
   ─────────────────────────────────────────────────────────────────────────── */

DECLARE @Diag TABLE (Rn INT IDENTITY(1,1), Id INT);
INSERT INTO @Diag (Id) SELECT IdDiagnostico FROM Diagnostico WHERE Activo = 1 ORDER BY IdDiagnostico;
DECLARE @NDiag INT = (SELECT COUNT(*) FROM @Diag);

DECLARE @Cond TABLE (Rn INT IDENTITY(1,1), Id INT);
INSERT INTO @Cond (Id) SELECT IdCondicion FROM CondicionAtencion ORDER BY IdCondicion;
DECLARE @NCond INT = (SELECT COUNT(*) FROM @Cond);

DECLARE @Est TABLE (Rn INT IDENTITY(1,1), Id INT);
INSERT INTO @Est (Id) SELECT IdEstablecimiento FROM Establecimiento ORDER BY IdEstablecimiento;
DECLARE @NEst INT = (SELECT COUNT(*) FROM @Est);

/* Medicamentos que pueden salir del inventario. Filgrastim queda fuera a
   propósito: se reserva para la demostración del costeo FIFO del final, para
   que el reparto 1×70 + 5×150 se vea con el stock intacto. */
DECLARE @Med TABLE (Rn INT IDENTITY(1,1), Id INT, Costo DECIMAL(12,2));
INSERT INTO @Med (Id, Costo)
SELECT m.IdMedicamento, MAX(l.CostoUnitario)
  FROM Medicamento m
  JOIN Lote l ON l.IdMedicamento = m.IdMedicamento AND l.Anulado = 0
 WHERE m.Nombre <> N'Filgrastim'
 GROUP BY m.IdMedicamento
 ORDER BY m.IdMedicamento;   -- sin ORDER BY el Rn dependeria del plan y dos
                             -- instalaciones darian numeros distintos
DECLARE @NMed INT = (SELECT COUNT(*) FROM @Med);

/* Un catálogo presente pero con todo desactivado daria @NDiag = 0 y el primer
   «% @NDiag» del bucle cortaria con division por cero. */
IF @NDiag = 0 OR @NCond = 0 OR @NEst = 0 OR @NMed = 0
    THROW 50023, N'Faltan catálogos operativos activos (diagnósticos, condiciones, establecimientos o medicamentos).', 1;

DECLARE @p INT = 1;
DECLARE @maxP INT = (SELECT MAX(Rn) FROM @Pac);
DECLARE @n INT = 0;

DECLARE @IdPac INT, @Visitas INT, @v INT;
DECLARE @IdArch INT, @IdAt INT, @IdDet INT;
DECLARE @Fecha DATE, @Form VARCHAR(20);
DECLARE @IdMed INT, @Cant DECIMAL(10,2), @CostoU DECIMAL(12,2);
DECLARE @Disp DECIMAL(14,2), @Monto DECIMAL(14,2);
DECLARE @IdMed2 INT, @CostoU2 DECIMAL(12,2);
DECLARE @MsgFifo NVARCHAR(200);

WHILE @p <= @maxP
BEGIN
    SELECT @IdPac = IdPaciente, @Visitas = Visitas FROM @Pac WHERE Rn = @p;

    SET @v = 1;
    WHILE @v <= @Visitas
    BEGIN
        SET @n = @n + 1;
        SET @Form = CONCAT('DEMO-', RIGHT(CONCAT('000', @n), 4));
        SET @Fecha = DATEADD(DAY, -(((@n * 37) + (@v * 11)) % 420), @Hoy);

        INSERT INTO ArchivoDigital (NombreOriginal, RutaAlmacenamiento, TipoMime,
                                    TamanoBytes, HashSha256, IdUsuarioCarga)
        VALUES (CONCAT('receta-', @Form, '.jpg'),
                CONCAT('demo/recetas/', @Form, '.jpg'),
                'image/jpeg',
                120000 + (@n * 211) % 80000,
                HASHBYTES('SHA2_256', CONCAT('demo-receta-', @Form)),
                @IdUsuario);

        SET @IdArch = SCOPE_IDENTITY();

        INSERT INTO Atencion (NumeroFormulario, IdPaciente, FechaAtencion, IdDiagnostico,
                              IdCondicion, IdEstablecimiento, IdArchivoReceta,
                              Observaciones, Estado, MotivoAnulacion, IdUsuarioRegistro)
        VALUES (@Form,
                @IdPac,
                @Fecha,
                (SELECT Id FROM @Diag WHERE Rn = (@n % @NDiag) + 1),
                (SELECT Id FROM @Cond WHERE Rn = (@n % @NCond) + 1),
                CASE WHEN @n % 5 = 0 THEN NULL
                     ELSE (SELECT Id FROM @Est WHERE Rn = (@n % @NEst) + 1) END,
                @IdArch,
                N'Dato de demostración.',
                /* Una de cada veinte queda anulada: hace falta para ver que los
                   reportes y el mapa las excluyen. */
                CASE WHEN @n % 20 = 0 THEN 'ANULADA' ELSE 'REGISTRADA' END,
                CASE WHEN @n % 20 = 0
                     THEN N'Anulada durante la demostración: el formulario se cargó dos veces.'
                     ELSE NULL END,
                @IdUsuario);

        SET @IdAt = SCOPE_IDENTITY();

        SELECT @IdMed = Id, @CostoU = Costo FROM @Med WHERE Rn = (@n % @NMed) + 1;
        SET @Cant = 1 + (@n % 4);

        /* Se descuenta del inventario sólo si a la fecha de la atención había
           stock suficiente. Preguntarlo antes evita que el procedimiento corte
           el script entero por un lote que ya se agotó. */
        SELECT @Disp = SUM(CantidadDisponible)
          FROM Lote
         WHERE IdMedicamento = @IdMed AND CantidadDisponible > 0
           AND Anulado = 0 AND FechaIngreso <= @Fecha;

        IF @n % 3 = 0 AND @n % 20 <> 0 AND ISNULL(@Disp, 0) >= @Cant
        BEGIN
            INSERT INTO AtencionDetalle (IdAtencion, IdMedicamento, Cantidad, MontoTotal, OrigenCosto)
            VALUES (@IdAt, @IdMed, @Cant, 0, 'MANUAL');

            SET @IdDet = SCOPE_IDENTITY();

            EXEC sp_ConsumirLotesFifo
                 @IdAtencionDetalle = @IdDet,
                 @IdMedicamento     = @IdMed,
                 @Cantidad          = @Cant,
                 @MontoTotal        = @Monto OUTPUT;
        END
        ELSE
        BEGIN
            INSERT INTO AtencionDetalle (IdAtencion, IdMedicamento, Cantidad,
                                         CostoUnitario, MontoTotal, OrigenCosto)
            VALUES (@IdAt, @IdMed, @Cant, @CostoU, @Cant * @CostoU, 'MANUAL');
        END

        /* La segunda línea debe usar otro medicamento por
           UQ_Detalle_AtencionMed. */
        IF @n % 3 = 1
        BEGIN
            SELECT @IdMed2 = Id, @CostoU2 = Costo FROM @Med WHERE Rn = ((@n + 7) % @NMed) + 1;

            IF @IdMed2 <> @IdMed
                INSERT INTO AtencionDetalle (IdAtencion, IdMedicamento, Cantidad,
                                             CostoUnitario, MontoTotal, OrigenCosto)
                VALUES (@IdAt, @IdMed2, 1 + (@n % 3), @CostoU2,
                        (1 + (@n % 3)) * @CostoU2, 'MANUAL');
        END

        SET @v = @v + 1;
    END

    SET @p = @p + 1;
END

/* ───────────────────────────────────────────────────────────────────────────
   5. VERIFICACIÓN FIFO CON DOS COSTOS
   Seis unidades de Filgrastim: hay 1 en el lote de hace dos años a 70 Bs y 20
   en el lote donado hace cuatro meses a 150 Bs. El reparto debe ser 1 + 5 y el
   monto 1×70 + 5×150 = 820 Bs, no 6×110 = 660, que es lo que daría promediar.
   ─────────────────────────────────────────────────────────────────────────── */

DECLARE @Filgrastim INT = (SELECT IdMedicamento FROM Medicamento WHERE Nombre = N'Filgrastim');
DECLARE @PacFifo INT = (SELECT TOP (1) IdPaciente FROM @Pac WHERE Visitas > 0 ORDER BY Rn);

INSERT INTO ArchivoDigital (NombreOriginal, RutaAlmacenamiento, TipoMime,
                            TamanoBytes, HashSha256, IdUsuarioCarga)
VALUES ('receta-DEMO-FIFO.jpg', 'demo/recetas/DEMO-FIFO.jpg', 'image/jpeg',
        204800, HASHBYTES('SHA2_256', 'demo-receta-DEMO-FIFO'), @IdUsuario);

SET @IdArch = SCOPE_IDENTITY();

INSERT INTO Atencion (NumeroFormulario, IdPaciente, FechaAtencion, IdDiagnostico,
                      IdCondicion, IdEstablecimiento, IdArchivoReceta,
                      Observaciones, IdUsuarioRegistro)
VALUES ('DEMO-FIFO', @PacFifo, @Hoy,
        (SELECT Id FROM @Diag WHERE Rn = 1),
        (SELECT Id FROM @Cond WHERE Rn = 1),
        (SELECT Id FROM @Est  WHERE Rn = 1),
        @IdArch,
        N'Entrega costeada por inventario: demuestra el reparto FIFO entre dos lotes a precios distintos.',
        @IdUsuario);

SET @IdAt = SCOPE_IDENTITY();

INSERT INTO AtencionDetalle (IdAtencion, IdMedicamento, Cantidad, MontoTotal, OrigenCosto)
VALUES (@IdAt, @Filgrastim, 6, 0, 'MANUAL');

SET @IdDet = SCOPE_IDENTITY();

EXEC sp_ConsumirLotesFifo
     @IdAtencionDetalle = @IdDet,
     @IdMedicamento     = @Filgrastim,
     @Cantidad          = 6,
     @MontoTotal        = @Monto OUTPUT;

/* ── El reparto entre TRES lotes ────────────────────────────────────────────
   Ondansetrón tiene tres ingresos a 10,00 · 12,50 · 15,80 Bs. Se pide una
   cantidad calculada para que no alcance con los dos más viejos y el FIFO
   tenga que bajar hasta el tercero: así se ve que el costo de una entrega no
   es «cantidad × precio» sino la suma de tramos a precios distintos.
   La cantidad se calcula contra el stock real del momento y no se escribe a
   mano, porque el bucle de arriba ya consumió parte de esos lotes. */

DECLARE @Ondansetron INT = (SELECT IdMedicamento FROM Medicamento WHERE Nombre = N'Ondansetrón');
DECLARE @CantOnd DECIMAL(10,2);

SELECT @CantOnd = SUM(CantidadDisponible) + 5
  FROM (SELECT TOP (2) CantidadDisponible
          FROM Lote
         WHERE IdMedicamento = @Ondansetron AND Anulado = 0
           AND CantidadDisponible > 0 AND FechaIngreso <= @Hoy
         ORDER BY FechaIngreso, IdLote) AS DosMasViejos;

INSERT INTO AtencionDetalle (IdAtencion, IdMedicamento, Cantidad, MontoTotal, OrigenCosto)
VALUES (@IdAt, @Ondansetron, @CantOnd, 0, 'MANUAL');

DECLARE @IdDetOnd INT = SCOPE_IDENTITY();
DECLARE @MontoOnd DECIMAL(14,2);

EXEC sp_ConsumirLotesFifo
     @IdAtencionDetalle = @IdDetOnd,
     @IdMedicamento     = @Ondansetron,
     @Cantidad          = @CantOnd,
     @MontoTotal        = @MontoOnd OUTPUT;

IF (SELECT COUNT(*) FROM ConsumoLote WHERE IdAtencionDetalle = @IdDetOnd) < 3
    THROW 50025, N'La entrega de ondansetrón no se repartió entre tres lotes. Revise los lotes DEMO-OND-A, DEMO-OND-B y DEMO-OND-C.', 1;

IF @Monto <> 820.00
BEGIN
    SET @MsgFifo = CONCAT(
        N'El costeo FIFO devolvió ', CAST(@Monto AS NVARCHAR(20)),
        N' Bs y se esperaban 820.00. Revise los lotes DEMO-FIL-A y DEMO-FIL-B.');
    THROW 50022, @MsgFifo, 1;
END

COMMIT TRANSACTION;

PRINT CONCAT('Atenciones creadas: ', @n + 1,
             '. Costeo FIFO verificado: Filgrastim 820.00 Bs en dos lotes, ',
             'ondansetrón ', CAST(@MontoOnd AS NVARCHAR(20)), ' Bs en tres.');

/* ───────────────────────────────────────────────────────────────────────────
   6. VERIFICACIÓN
   Permanece en el mismo lote para que los RETURN de las precondiciones también
   omitan el mensaje de éxito.
   ─────────────────────────────────────────────────────────────────────────── */

PRINT '';
PRINT '--- Resumen ---';

SELECT 'Pacientes de demostracion'      AS Concepto, COUNT(*) AS Cantidad
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7
UNION ALL SELECT 'Con origen distinto de residencia', COUNT(*)
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7
   AND IdMunicipioOrigen IS NOT NULL AND IdMunicipio IS NOT NULL
   AND IdMunicipioOrigen <> IdMunicipio
UNION ALL SELECT 'Con origen sin cargar', COUNT(*)
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7
   AND IdMunicipioOrigen IS NULL AND IdPaisOrigen IS NULL AND IdMunicipio IS NOT NULL
UNION ALL SELECT 'Del exterior', COUNT(*)
  FROM Paciente p JOIN Pais pa ON pa.IdPais = p.IdPaisOrigen
 WHERE p.NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(p.NumeroDocumento) = 7 AND pa.EsLocal = 0
UNION ALL SELECT 'Sin ninguna ubicacion', COUNT(*)
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7
   AND IdMunicipio IS NULL AND IdMunicipioOrigen IS NULL AND IdPaisOrigen IS NULL
UNION ALL SELECT 'Con direccion desglosada', COUNT(*)
  FROM Paciente WHERE NumeroDocumento LIKE '99[0-9][0-9][0-9][0-9][0-9]' AND LEN(NumeroDocumento) = 7 AND Zona IS NOT NULL
UNION ALL SELECT 'Atenciones', COUNT(*)
  FROM Atencion WHERE NumeroFormulario LIKE 'DEMO-%'
UNION ALL SELECT 'Atenciones anuladas', COUNT(*)
  FROM Atencion WHERE NumeroFormulario LIKE 'DEMO-%' AND Estado = 'ANULADA'
UNION ALL SELECT 'Entregas costeadas por FIFO', COUNT(*)
  FROM AtencionDetalle d
  JOIN Atencion a ON a.IdAtencion = d.IdAtencion
 WHERE d.OrigenCosto = 'FIFO' AND a.NumeroFormulario LIKE 'DEMO-%';

PRINT '';
PRINT '--- Lo que deberia pintar el mapa (por departamento de ORIGEN) ---';

SELECT d.Nombre AS Departamento, COUNT(*) AS Atenciones
  FROM Atencion a
  JOIN Paciente p ON p.IdPaciente = a.IdPaciente
  JOIN Municipio m ON m.IdMunicipio = ISNULL(p.IdMunicipioOrigen, p.IdMunicipio)
  JOIN Provincia v ON v.IdProvincia = m.IdProvincia
  JOIN Departamento d ON d.IdDepartamento = v.IdDepartamento
 WHERE a.NumeroFormulario LIKE 'DEMO-%'
   AND a.Estado <> 'ANULADA'
   AND (p.IdPaisOrigen IS NULL OR EXISTS (SELECT 1 FROM Pais pa
        WHERE pa.IdPais = p.IdPaisOrigen AND pa.EsLocal = 1))
 GROUP BY d.Nombre
 ORDER BY Atenciones DESC;

PRINT '';
PRINT '--- Reparto FIFO de la entrega de Filgrastim ---';

SELECT l.NumeroLote, l.FechaIngreso, c.Cantidad, c.CostoUnitario, c.Subtotal
  FROM ConsumoLote c
  JOIN Lote l ON l.IdLote = c.IdLote
  JOIN AtencionDetalle d ON d.IdAtencionDetalle = c.IdAtencionDetalle
  JOIN Atencion a ON a.IdAtencion = d.IdAtencion
 WHERE a.NumeroFormulario = 'DEMO-FIFO'
 ORDER BY l.FechaIngreso;

PRINT '';
PRINT 'Datos de demostracion cargados.';
PRINT '';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
