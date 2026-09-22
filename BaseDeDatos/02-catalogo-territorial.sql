-- ================================================================
-- CATÁLOGO TERRITORIAL DE BOLIVIA PARA SQL SERVER
-- Fuente: catálogo CPV-2024 con códigos INE.
-- Carga esperada: 9 departamentos, 112 provincias y 340 municipios.
-- Se excluyen tres unidades TIOC separadas para conservar el modelo
-- Departamento -> Provincia -> Municipio.
--
-- IMPORTANTE: este archivo no ejecuta USE. Antes de correrlo, seleccionar de
-- forma explícita la base creada por 01-esquema.sql. Es idempotente y no elimina
-- pacientes ni otros datos de la aplicación.

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY

-- A. Compatibilidad con bases que aún no tienen el catálogo territorial.
IF OBJECT_ID('Departamento', 'U') IS NULL
BEGIN
    CREATE TABLE Departamento (
        IdDepartamento INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Departamento PRIMARY KEY,
        Nombre NVARCHAR(80) NOT NULL,
        CodigoINE VARCHAR(2) NULL
    );
    CREATE UNIQUE INDEX UQ_Departamento_Nombre ON Departamento(Nombre);
END;

IF OBJECT_ID('Provincia', 'U') IS NULL
BEGIN
    CREATE TABLE Provincia (
        IdProvincia INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Provincia PRIMARY KEY,
        IdDepartamento INT NOT NULL,
        Nombre NVARCHAR(100) NOT NULL,
        CodigoINE VARCHAR(4) NULL,
        CONSTRAINT FK_Provincia_Departamento FOREIGN KEY (IdDepartamento)
            REFERENCES Departamento(IdDepartamento),
        CONSTRAINT UQ_Provincia UNIQUE (IdDepartamento, Nombre)
    );
END;

IF OBJECT_ID('Municipio', 'U') IS NULL
BEGIN
    CREATE TABLE Municipio (
        IdMunicipio INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Municipio PRIMARY KEY,
        IdProvincia INT NOT NULL,
        Nombre NVARCHAR(150) NOT NULL,
        CodigoINE VARCHAR(6) NULL,
        CONSTRAINT FK_Municipio_Provincia FOREIGN KEY (IdProvincia)
            REFERENCES Provincia(IdProvincia),
        CONSTRAINT UQ_Municipio UNIQUE (IdProvincia, Nombre)
    );
END;

-- Agrega CodigoINE cuando las tablas provienen de una versión anterior.
IF COL_LENGTH('Departamento', 'CodigoINE') IS NULL
    ALTER TABLE Departamento ADD CodigoINE VARCHAR(2) NULL;
IF COL_LENGTH('Provincia', 'CodigoINE') IS NULL
    ALTER TABLE Provincia ADD CodigoINE VARCHAR(4) NULL;
IF COL_LENGTH('Municipio', 'CodigoINE') IS NULL
    ALTER TABLE Municipio ADD CodigoINE VARCHAR(6) NULL;

-- B. Departamentos.
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Chuquisaca')
    UPDATE Departamento SET CodigoINE = '01' WHERE Nombre = N'Chuquisaca';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Chuquisaca', '01');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'La Paz')
    UPDATE Departamento SET CodigoINE = '02' WHERE Nombre = N'La Paz';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'La Paz', '02');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Cochabamba')
    UPDATE Departamento SET CodigoINE = '03' WHERE Nombre = N'Cochabamba';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Cochabamba', '03');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Oruro')
    UPDATE Departamento SET CodigoINE = '04' WHERE Nombre = N'Oruro';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Oruro', '04');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Potosí')
    UPDATE Departamento SET CodigoINE = '05' WHERE Nombre = N'Potosí';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Potosí', '05');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Tarija')
    UPDATE Departamento SET CodigoINE = '06' WHERE Nombre = N'Tarija';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Tarija', '06');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Santa Cruz')
    UPDATE Departamento SET CodigoINE = '07' WHERE Nombre = N'Santa Cruz';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Santa Cruz', '07');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Beni')
    UPDATE Departamento SET CodigoINE = '08' WHERE Nombre = N'Beni';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Beni', '08');
IF EXISTS (SELECT 1 FROM Departamento WHERE Nombre = N'Pando')
    UPDATE Departamento SET CodigoINE = '09' WHERE Nombre = N'Pando';
ELSE
    INSERT INTO Departamento (Nombre, CodigoINE) VALUES (N'Pando', '09');

-- C. Provincias.
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0101')
BEGIN
    UPDATE Provincia SET Nombre = N'Oropeza' WHERE CodigoINE = '0101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Oropeza'
)
BEGIN
    UPDATE p SET CodigoINE = '0101'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Oropeza';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Oropeza', '0101'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0102')
BEGIN
    UPDATE Provincia SET Nombre = N'Azurduy' WHERE CodigoINE = '0102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Azurduy'
)
BEGIN
    UPDATE p SET CodigoINE = '0102'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Azurduy';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Azurduy', '0102'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0103')
BEGIN
    UPDATE Provincia SET Nombre = N'Zudáñez' WHERE CodigoINE = '0103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Zudáñez'
)
BEGIN
    UPDATE p SET CodigoINE = '0103'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Zudáñez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Zudáñez', '0103'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0104')
BEGIN
    UPDATE Provincia SET Nombre = N'Tomina' WHERE CodigoINE = '0104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Tomina'
)
BEGIN
    UPDATE p SET CodigoINE = '0104'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Tomina';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Tomina', '0104'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0105')
BEGIN
    UPDATE Provincia SET Nombre = N'Hernando Siles' WHERE CodigoINE = '0105';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Hernando Siles'
)
BEGIN
    UPDATE p SET CodigoINE = '0105'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Hernando Siles';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Hernando Siles', '0105'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0106')
BEGIN
    UPDATE Provincia SET Nombre = N'Yamparáez' WHERE CodigoINE = '0106';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Yamparáez'
)
BEGIN
    UPDATE p SET CodigoINE = '0106'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Yamparáez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Yamparáez', '0106'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0107')
BEGIN
    UPDATE Provincia SET Nombre = N'Nor Cinti' WHERE CodigoINE = '0107';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Nor Cinti'
)
BEGIN
    UPDATE p SET CodigoINE = '0107'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Nor Cinti';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nor Cinti', '0107'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0108')
BEGIN
    UPDATE Provincia SET Nombre = N'Belisario Boeto' WHERE CodigoINE = '0108';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Belisario Boeto'
)
BEGIN
    UPDATE p SET CodigoINE = '0108'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Belisario Boeto';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Belisario Boeto', '0108'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0109')
BEGIN
    UPDATE Provincia SET Nombre = N'Sud Cinti' WHERE CodigoINE = '0109';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Sud Cinti'
)
BEGIN
    UPDATE p SET CodigoINE = '0109'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Sud Cinti';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sud Cinti', '0109'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0110')
BEGIN
    UPDATE Provincia SET Nombre = N'Luis Calvo' WHERE CodigoINE = '0110';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Luis Calvo'
)
BEGIN
    UPDATE p SET CodigoINE = '0110'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '01' AND p.Nombre = N'Luis Calvo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Luis Calvo', '0110'
    FROM Departamento WHERE CodigoINE = '01';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0201')
BEGIN
    UPDATE Provincia SET Nombre = N'Murillo' WHERE CodigoINE = '0201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Murillo'
)
BEGIN
    UPDATE p SET CodigoINE = '0201'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Murillo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Murillo', '0201'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0202')
BEGIN
    UPDATE Provincia SET Nombre = N'Omasuyos' WHERE CodigoINE = '0202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Omasuyos'
)
BEGIN
    UPDATE p SET CodigoINE = '0202'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Omasuyos';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Omasuyos', '0202'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0203')
BEGIN
    UPDATE Provincia SET Nombre = N'Pacajes' WHERE CodigoINE = '0203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Pacajes'
)
BEGIN
    UPDATE p SET CodigoINE = '0203'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Pacajes';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Pacajes', '0203'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0204')
BEGIN
    UPDATE Provincia SET Nombre = N'Camacho' WHERE CodigoINE = '0204';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Camacho'
)
BEGIN
    UPDATE p SET CodigoINE = '0204'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Camacho';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Camacho', '0204'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0205')
BEGIN
    UPDATE Provincia SET Nombre = N'Muñecas' WHERE CodigoINE = '0205';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Muñecas'
)
BEGIN
    UPDATE p SET CodigoINE = '0205'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Muñecas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Muñecas', '0205'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0206')
BEGIN
    UPDATE Provincia SET Nombre = N'Larecaja' WHERE CodigoINE = '0206';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Larecaja'
)
BEGIN
    UPDATE p SET CodigoINE = '0206'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Larecaja';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Larecaja', '0206'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0207')
BEGIN
    UPDATE Provincia SET Nombre = N'Franz Tamayo' WHERE CodigoINE = '0207';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Franz Tamayo'
)
BEGIN
    UPDATE p SET CodigoINE = '0207'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Franz Tamayo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Franz Tamayo', '0207'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0208')
BEGIN
    UPDATE Provincia SET Nombre = N'Ingavi' WHERE CodigoINE = '0208';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Ingavi'
)
BEGIN
    UPDATE p SET CodigoINE = '0208'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Ingavi';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ingavi', '0208'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0209')
BEGIN
    UPDATE Provincia SET Nombre = N'Loayza' WHERE CodigoINE = '0209';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Loayza'
)
BEGIN
    UPDATE p SET CodigoINE = '0209'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Loayza';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Loayza', '0209'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0210')
BEGIN
    UPDATE Provincia SET Nombre = N'Inquisivi' WHERE CodigoINE = '0210';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Inquisivi'
)
BEGIN
    UPDATE p SET CodigoINE = '0210'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Inquisivi';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Inquisivi', '0210'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0211')
BEGIN
    UPDATE Provincia SET Nombre = N'Sur Yungas' WHERE CodigoINE = '0211';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Sur Yungas'
)
BEGIN
    UPDATE p SET CodigoINE = '0211'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Sur Yungas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sur Yungas', '0211'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0212')
BEGIN
    UPDATE Provincia SET Nombre = N'Los Andes' WHERE CodigoINE = '0212';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Los Andes'
)
BEGIN
    UPDATE p SET CodigoINE = '0212'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Los Andes';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Los Andes', '0212'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0213')
BEGIN
    UPDATE Provincia SET Nombre = N'Aroma' WHERE CodigoINE = '0213';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Aroma'
)
BEGIN
    UPDATE p SET CodigoINE = '0213'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Aroma';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Aroma', '0213'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0214')
BEGIN
    UPDATE Provincia SET Nombre = N'Nor Yungas' WHERE CodigoINE = '0214';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Nor Yungas'
)
BEGIN
    UPDATE p SET CodigoINE = '0214'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Nor Yungas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nor Yungas', '0214'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0215')
BEGIN
    UPDATE Provincia SET Nombre = N'Abel Iturralde' WHERE CodigoINE = '0215';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Abel Iturralde'
)
BEGIN
    UPDATE p SET CodigoINE = '0215'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Abel Iturralde';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Abel Iturralde', '0215'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0216')
BEGIN
    UPDATE Provincia SET Nombre = N'Bautista Saavedra' WHERE CodigoINE = '0216';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Bautista Saavedra'
)
BEGIN
    UPDATE p SET CodigoINE = '0216'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Bautista Saavedra';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Bautista Saavedra', '0216'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0217')
BEGIN
    UPDATE Provincia SET Nombre = N'Manco Kapac' WHERE CodigoINE = '0217';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Manco Kapac'
)
BEGIN
    UPDATE p SET CodigoINE = '0217'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Manco Kapac';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Manco Kapac', '0217'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0218')
BEGIN
    UPDATE Provincia SET Nombre = N'Gualberto Villarroel' WHERE CodigoINE = '0218';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Gualberto Villarroel'
)
BEGIN
    UPDATE p SET CodigoINE = '0218'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Gualberto Villarroel';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Gualberto Villarroel', '0218'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0219')
BEGIN
    UPDATE Provincia SET Nombre = N'General José Manuel Pando' WHERE CodigoINE = '0219';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'General José Manuel Pando'
)
BEGIN
    UPDATE p SET CodigoINE = '0219'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'General José Manuel Pando';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'General José Manuel Pando', '0219'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0220')
BEGIN
    UPDATE Provincia SET Nombre = N'Caranavi' WHERE CodigoINE = '0220';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Caranavi'
)
BEGIN
    UPDATE p SET CodigoINE = '0220'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '02' AND p.Nombre = N'Caranavi';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Caranavi', '0220'
    FROM Departamento WHERE CodigoINE = '02';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0301')
BEGIN
    UPDATE Provincia SET Nombre = N'Cercado' WHERE CodigoINE = '0301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Cercado'
)
BEGIN
    UPDATE p SET CodigoINE = '0301'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Cercado';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cercado', '0301'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0302')
BEGIN
    UPDATE Provincia SET Nombre = N'Campero' WHERE CodigoINE = '0302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Campero'
)
BEGIN
    UPDATE p SET CodigoINE = '0302'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Campero';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Campero', '0302'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0303')
BEGIN
    UPDATE Provincia SET Nombre = N'Ayopaya' WHERE CodigoINE = '0303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Ayopaya'
)
BEGIN
    UPDATE p SET CodigoINE = '0303'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Ayopaya';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ayopaya', '0303'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0304')
BEGIN
    UPDATE Provincia SET Nombre = N'Esteban Arze' WHERE CodigoINE = '0304';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Esteban Arze'
)
BEGIN
    UPDATE p SET CodigoINE = '0304'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Esteban Arze';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Esteban Arze', '0304'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0305')
BEGIN
    UPDATE Provincia SET Nombre = N'Arani' WHERE CodigoINE = '0305';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Arani'
)
BEGIN
    UPDATE p SET CodigoINE = '0305'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Arani';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Arani', '0305'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0306')
BEGIN
    UPDATE Provincia SET Nombre = N'Arque' WHERE CodigoINE = '0306';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Arque'
)
BEGIN
    UPDATE p SET CodigoINE = '0306'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Arque';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Arque', '0306'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0307')
BEGIN
    UPDATE Provincia SET Nombre = N'Capinota' WHERE CodigoINE = '0307';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Capinota'
)
BEGIN
    UPDATE p SET CodigoINE = '0307'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Capinota';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Capinota', '0307'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0308')
BEGIN
    UPDATE Provincia SET Nombre = N'Germán Jordán' WHERE CodigoINE = '0308';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Germán Jordán'
)
BEGIN
    UPDATE p SET CodigoINE = '0308'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Germán Jordán';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Germán Jordán', '0308'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0309')
BEGIN
    UPDATE Provincia SET Nombre = N'Quillacollo' WHERE CodigoINE = '0309';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Quillacollo'
)
BEGIN
    UPDATE p SET CodigoINE = '0309'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Quillacollo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Quillacollo', '0309'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0310')
BEGIN
    UPDATE Provincia SET Nombre = N'Chapare' WHERE CodigoINE = '0310';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Chapare'
)
BEGIN
    UPDATE p SET CodigoINE = '0310'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Chapare';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Chapare', '0310'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0311')
BEGIN
    UPDATE Provincia SET Nombre = N'Tapacarí' WHERE CodigoINE = '0311';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Tapacarí'
)
BEGIN
    UPDATE p SET CodigoINE = '0311'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Tapacarí';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Tapacarí', '0311'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0312')
BEGIN
    UPDATE Provincia SET Nombre = N'Carrasco' WHERE CodigoINE = '0312';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Carrasco'
)
BEGIN
    UPDATE p SET CodigoINE = '0312'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Carrasco';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Carrasco', '0312'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0313')
BEGIN
    UPDATE Provincia SET Nombre = N'Mizque' WHERE CodigoINE = '0313';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Mizque'
)
BEGIN
    UPDATE p SET CodigoINE = '0313'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Mizque';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Mizque', '0313'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0314')
BEGIN
    UPDATE Provincia SET Nombre = N'Punata' WHERE CodigoINE = '0314';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Punata'
)
BEGIN
    UPDATE p SET CodigoINE = '0314'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Punata';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Punata', '0314'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0315')
BEGIN
    UPDATE Provincia SET Nombre = N'Bolívar' WHERE CodigoINE = '0315';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Bolívar'
)
BEGIN
    UPDATE p SET CodigoINE = '0315'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Bolívar';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Bolívar', '0315'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0316')
BEGIN
    UPDATE Provincia SET Nombre = N'Tiraque' WHERE CodigoINE = '0316';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Tiraque'
)
BEGIN
    UPDATE p SET CodigoINE = '0316'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '03' AND p.Nombre = N'Tiraque';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Tiraque', '0316'
    FROM Departamento WHERE CodigoINE = '03';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0401')
BEGIN
    UPDATE Provincia SET Nombre = N'Cercado' WHERE CodigoINE = '0401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Cercado'
)
BEGIN
    UPDATE p SET CodigoINE = '0401'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Cercado';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cercado', '0401'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0402')
BEGIN
    UPDATE Provincia SET Nombre = N'Abaroa' WHERE CodigoINE = '0402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Abaroa'
)
BEGIN
    UPDATE p SET CodigoINE = '0402'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Abaroa';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Abaroa', '0402'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0403')
BEGIN
    UPDATE Provincia SET Nombre = N'Carangas' WHERE CodigoINE = '0403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Carangas'
)
BEGIN
    UPDATE p SET CodigoINE = '0403'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Carangas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Carangas', '0403'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0404')
BEGIN
    UPDATE Provincia SET Nombre = N'Sajama' WHERE CodigoINE = '0404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sajama'
)
BEGIN
    UPDATE p SET CodigoINE = '0404'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sajama';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sajama', '0404'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0405')
BEGIN
    UPDATE Provincia SET Nombre = N'Litoral' WHERE CodigoINE = '0405';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Litoral'
)
BEGIN
    UPDATE p SET CodigoINE = '0405'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Litoral';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Litoral', '0405'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0406')
BEGIN
    UPDATE Provincia SET Nombre = N'Poopó' WHERE CodigoINE = '0406';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Poopó'
)
BEGIN
    UPDATE p SET CodigoINE = '0406'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Poopó';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Poopó', '0406'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0407')
BEGIN
    UPDATE Provincia SET Nombre = N'Pantaleón Dalence' WHERE CodigoINE = '0407';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Pantaleón Dalence'
)
BEGIN
    UPDATE p SET CodigoINE = '0407'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Pantaleón Dalence';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Pantaleón Dalence', '0407'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0408')
BEGIN
    UPDATE Provincia SET Nombre = N'Ladislao Cabrera' WHERE CodigoINE = '0408';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Ladislao Cabrera'
)
BEGIN
    UPDATE p SET CodigoINE = '0408'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Ladislao Cabrera';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ladislao Cabrera', '0408'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0409')
BEGIN
    UPDATE Provincia SET Nombre = N'Sabaya' WHERE CodigoINE = '0409';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sabaya'
)
BEGIN
    UPDATE p SET CodigoINE = '0409'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sabaya';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sabaya', '0409'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0410')
BEGIN
    UPDATE Provincia SET Nombre = N'Saucarí' WHERE CodigoINE = '0410';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Saucarí'
)
BEGIN
    UPDATE p SET CodigoINE = '0410'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Saucarí';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Saucarí', '0410'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0411')
BEGIN
    UPDATE Provincia SET Nombre = N'Tomás Barrón' WHERE CodigoINE = '0411';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Tomás Barrón'
)
BEGIN
    UPDATE p SET CodigoINE = '0411'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Tomás Barrón';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Tomás Barrón', '0411'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0412')
BEGIN
    UPDATE Provincia SET Nombre = N'Sur Carangas' WHERE CodigoINE = '0412';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sur Carangas'
)
BEGIN
    UPDATE p SET CodigoINE = '0412'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sur Carangas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sur Carangas', '0412'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0413')
BEGIN
    UPDATE Provincia SET Nombre = N'San Pedro de Totora' WHERE CodigoINE = '0413';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'San Pedro de Totora'
)
BEGIN
    UPDATE p SET CodigoINE = '0413'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'San Pedro de Totora';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'San Pedro de Totora', '0413'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0414')
BEGIN
    UPDATE Provincia SET Nombre = N'Sebastián Pagador' WHERE CodigoINE = '0414';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sebastián Pagador'
)
BEGIN
    UPDATE p SET CodigoINE = '0414'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Sebastián Pagador';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sebastián Pagador', '0414'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0415')
BEGIN
    UPDATE Provincia SET Nombre = N'Mejillones' WHERE CodigoINE = '0415';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Mejillones'
)
BEGIN
    UPDATE p SET CodigoINE = '0415'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Mejillones';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Mejillones', '0415'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0416')
BEGIN
    UPDATE Provincia SET Nombre = N'Nor Carangas' WHERE CodigoINE = '0416';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Nor Carangas'
)
BEGIN
    UPDATE p SET CodigoINE = '0416'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '04' AND p.Nombre = N'Nor Carangas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nor Carangas', '0416'
    FROM Departamento WHERE CodigoINE = '04';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0501')
BEGIN
    UPDATE Provincia SET Nombre = N'Tomás Frías' WHERE CodigoINE = '0501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Tomás Frías'
)
BEGIN
    UPDATE p SET CodigoINE = '0501'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Tomás Frías';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Tomás Frías', '0501'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0502')
BEGIN
    UPDATE Provincia SET Nombre = N'Rafael Bustillo' WHERE CodigoINE = '0502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Rafael Bustillo'
)
BEGIN
    UPDATE p SET CodigoINE = '0502'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Rafael Bustillo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Rafael Bustillo', '0502'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0503')
BEGIN
    UPDATE Provincia SET Nombre = N'Cornelio Saavedra' WHERE CodigoINE = '0503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Cornelio Saavedra'
)
BEGIN
    UPDATE p SET CodigoINE = '0503'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Cornelio Saavedra';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cornelio Saavedra', '0503'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0504')
BEGIN
    UPDATE Provincia SET Nombre = N'Chayanta' WHERE CodigoINE = '0504';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Chayanta'
)
BEGIN
    UPDATE p SET CodigoINE = '0504'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Chayanta';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Chayanta', '0504'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0505')
BEGIN
    UPDATE Provincia SET Nombre = N'Charcas' WHERE CodigoINE = '0505';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Charcas'
)
BEGIN
    UPDATE p SET CodigoINE = '0505'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Charcas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Charcas', '0505'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0506')
BEGIN
    UPDATE Provincia SET Nombre = N'Nor Chichas' WHERE CodigoINE = '0506';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Nor Chichas'
)
BEGIN
    UPDATE p SET CodigoINE = '0506'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Nor Chichas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nor Chichas', '0506'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0507')
BEGIN
    UPDATE Provincia SET Nombre = N'Alonso de Ibáñez' WHERE CodigoINE = '0507';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Alonso de Ibáñez'
)
BEGIN
    UPDATE p SET CodigoINE = '0507'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Alonso de Ibáñez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Alonso de Ibáñez', '0507'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0508')
BEGIN
    UPDATE Provincia SET Nombre = N'Sur Chichas' WHERE CodigoINE = '0508';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Sur Chichas'
)
BEGIN
    UPDATE p SET CodigoINE = '0508'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Sur Chichas';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sur Chichas', '0508'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0509')
BEGIN
    UPDATE Provincia SET Nombre = N'Nor Lípez' WHERE CodigoINE = '0509';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Nor Lípez'
)
BEGIN
    UPDATE p SET CodigoINE = '0509'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Nor Lípez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nor Lípez', '0509'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0510')
BEGIN
    UPDATE Provincia SET Nombre = N'Sur Lípez' WHERE CodigoINE = '0510';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Sur Lípez'
)
BEGIN
    UPDATE p SET CodigoINE = '0510'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Sur Lípez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sur Lípez', '0510'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0511')
BEGIN
    UPDATE Provincia SET Nombre = N'José María Linares' WHERE CodigoINE = '0511';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'José María Linares'
)
BEGIN
    UPDATE p SET CodigoINE = '0511'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'José María Linares';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'José María Linares', '0511'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0512')
BEGIN
    UPDATE Provincia SET Nombre = N'Antonio Quijarro' WHERE CodigoINE = '0512';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Antonio Quijarro'
)
BEGIN
    UPDATE p SET CodigoINE = '0512'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Antonio Quijarro';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Antonio Quijarro', '0512'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0513')
BEGIN
    UPDATE Provincia SET Nombre = N'General Bernardino Bilbao' WHERE CodigoINE = '0513';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'General Bernardino Bilbao'
)
BEGIN
    UPDATE p SET CodigoINE = '0513'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'General Bernardino Bilbao';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'General Bernardino Bilbao', '0513'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0514')
BEGIN
    UPDATE Provincia SET Nombre = N'Daniel Campos' WHERE CodigoINE = '0514';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Daniel Campos'
)
BEGIN
    UPDATE p SET CodigoINE = '0514'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Daniel Campos';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Daniel Campos', '0514'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0515')
BEGIN
    UPDATE Provincia SET Nombre = N'Modesto Omiste' WHERE CodigoINE = '0515';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Modesto Omiste'
)
BEGIN
    UPDATE p SET CodigoINE = '0515'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Modesto Omiste';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Modesto Omiste', '0515'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0516')
BEGIN
    UPDATE Provincia SET Nombre = N'Enrique Baldivieso' WHERE CodigoINE = '0516';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Enrique Baldivieso'
)
BEGIN
    UPDATE p SET CodigoINE = '0516'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '05' AND p.Nombre = N'Enrique Baldivieso';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Enrique Baldivieso', '0516'
    FROM Departamento WHERE CodigoINE = '05';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0601')
BEGIN
    UPDATE Provincia SET Nombre = N'Cercado' WHERE CodigoINE = '0601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Cercado'
)
BEGIN
    UPDATE p SET CodigoINE = '0601'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Cercado';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cercado', '0601'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0602')
BEGIN
    UPDATE Provincia SET Nombre = N'Arce' WHERE CodigoINE = '0602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Arce'
)
BEGIN
    UPDATE p SET CodigoINE = '0602'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Arce';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Arce', '0602'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0603')
BEGIN
    UPDATE Provincia SET Nombre = N'Gran Chaco' WHERE CodigoINE = '0603';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Gran Chaco'
)
BEGIN
    UPDATE p SET CodigoINE = '0603'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Gran Chaco';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Gran Chaco', '0603'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0604')
BEGIN
    UPDATE Provincia SET Nombre = N'Avilez' WHERE CodigoINE = '0604';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Avilez'
)
BEGIN
    UPDATE p SET CodigoINE = '0604'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Avilez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Avilez', '0604'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0605')
BEGIN
    UPDATE Provincia SET Nombre = N'Méndez' WHERE CodigoINE = '0605';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Méndez'
)
BEGIN
    UPDATE p SET CodigoINE = '0605'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'Méndez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Méndez', '0605'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0606')
BEGIN
    UPDATE Provincia SET Nombre = N'O''Connor' WHERE CodigoINE = '0606';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'O''Connor'
)
BEGIN
    UPDATE p SET CodigoINE = '0606'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '06' AND p.Nombre = N'O''Connor';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'O''Connor', '0606'
    FROM Departamento WHERE CodigoINE = '06';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0701')
BEGIN
    UPDATE Provincia SET Nombre = N'Andrés Ibáñez' WHERE CodigoINE = '0701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Andrés Ibáñez'
)
BEGIN
    UPDATE p SET CodigoINE = '0701'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Andrés Ibáñez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Andrés Ibáñez', '0701'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0702')
BEGIN
    UPDATE Provincia SET Nombre = N'Warnes' WHERE CodigoINE = '0702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Warnes'
)
BEGIN
    UPDATE p SET CodigoINE = '0702'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Warnes';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Warnes', '0702'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0703')
BEGIN
    UPDATE Provincia SET Nombre = N'Velasco' WHERE CodigoINE = '0703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Velasco'
)
BEGIN
    UPDATE p SET CodigoINE = '0703'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Velasco';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Velasco', '0703'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0704')
BEGIN
    UPDATE Provincia SET Nombre = N'Ichilo' WHERE CodigoINE = '0704';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ichilo'
)
BEGIN
    UPDATE p SET CodigoINE = '0704'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ichilo';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ichilo', '0704'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0705')
BEGIN
    UPDATE Provincia SET Nombre = N'Chiquitos' WHERE CodigoINE = '0705';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Chiquitos'
)
BEGIN
    UPDATE p SET CodigoINE = '0705'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Chiquitos';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Chiquitos', '0705'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0706')
BEGIN
    UPDATE Provincia SET Nombre = N'Sara' WHERE CodigoINE = '0706';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Sara'
)
BEGIN
    UPDATE p SET CodigoINE = '0706'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Sara';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Sara', '0706'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0707')
BEGIN
    UPDATE Provincia SET Nombre = N'Cordillera' WHERE CodigoINE = '0707';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Cordillera'
)
BEGIN
    UPDATE p SET CodigoINE = '0707'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Cordillera';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cordillera', '0707'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0708')
BEGIN
    UPDATE Provincia SET Nombre = N'Valle Grande' WHERE CodigoINE = '0708';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Valle Grande'
)
BEGIN
    UPDATE p SET CodigoINE = '0708'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Valle Grande';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Valle Grande', '0708'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0709')
BEGIN
    UPDATE Provincia SET Nombre = N'Florida' WHERE CodigoINE = '0709';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Florida'
)
BEGIN
    UPDATE p SET CodigoINE = '0709'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Florida';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Florida', '0709'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0710')
BEGIN
    UPDATE Provincia SET Nombre = N'Obispo Santisteban' WHERE CodigoINE = '0710';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Obispo Santisteban'
)
BEGIN
    UPDATE p SET CodigoINE = '0710'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Obispo Santisteban';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Obispo Santisteban', '0710'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0711')
BEGIN
    UPDATE Provincia SET Nombre = N'Ñuflo de Chávez' WHERE CodigoINE = '0711';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ñuflo de Chávez'
)
BEGIN
    UPDATE p SET CodigoINE = '0711'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ñuflo de Chávez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ñuflo de Chávez', '0711'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0712')
BEGIN
    UPDATE Provincia SET Nombre = N'Ángel Sandoval' WHERE CodigoINE = '0712';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ángel Sandoval'
)
BEGIN
    UPDATE p SET CodigoINE = '0712'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Ángel Sandoval';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Ángel Sandoval', '0712'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0713')
BEGIN
    UPDATE Provincia SET Nombre = N'Manuel María Caballero' WHERE CodigoINE = '0713';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Manuel María Caballero'
)
BEGIN
    UPDATE p SET CodigoINE = '0713'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Manuel María Caballero';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Manuel María Caballero', '0713'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0714')
BEGIN
    UPDATE Provincia SET Nombre = N'Germán Busch' WHERE CodigoINE = '0714';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Germán Busch'
)
BEGIN
    UPDATE p SET CodigoINE = '0714'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Germán Busch';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Germán Busch', '0714'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0715')
BEGIN
    UPDATE Provincia SET Nombre = N'Guarayos' WHERE CodigoINE = '0715';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Guarayos'
)
BEGIN
    UPDATE p SET CodigoINE = '0715'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '07' AND p.Nombre = N'Guarayos';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Guarayos', '0715'
    FROM Departamento WHERE CodigoINE = '07';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0801')
BEGIN
    UPDATE Provincia SET Nombre = N'Cercado' WHERE CodigoINE = '0801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Cercado'
)
BEGIN
    UPDATE p SET CodigoINE = '0801'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Cercado';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Cercado', '0801'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0802')
BEGIN
    UPDATE Provincia SET Nombre = N'Vaca Diez' WHERE CodigoINE = '0802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Vaca Diez'
)
BEGIN
    UPDATE p SET CodigoINE = '0802'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Vaca Diez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Vaca Diez', '0802'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0803')
BEGIN
    UPDATE Provincia SET Nombre = N'General José Ballivián' WHERE CodigoINE = '0803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'General José Ballivián'
)
BEGIN
    UPDATE p SET CodigoINE = '0803'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'General José Ballivián';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'General José Ballivián', '0803'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0804')
BEGIN
    UPDATE Provincia SET Nombre = N'Yacuma' WHERE CodigoINE = '0804';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Yacuma'
)
BEGIN
    UPDATE p SET CodigoINE = '0804'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Yacuma';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Yacuma', '0804'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0805')
BEGIN
    UPDATE Provincia SET Nombre = N'Moxos' WHERE CodigoINE = '0805';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Moxos'
)
BEGIN
    UPDATE p SET CodigoINE = '0805'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Moxos';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Moxos', '0805'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0806')
BEGIN
    UPDATE Provincia SET Nombre = N'Marbán' WHERE CodigoINE = '0806';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Marbán'
)
BEGIN
    UPDATE p SET CodigoINE = '0806'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Marbán';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Marbán', '0806'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0807')
BEGIN
    UPDATE Provincia SET Nombre = N'Mamoré' WHERE CodigoINE = '0807';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Mamoré'
)
BEGIN
    UPDATE p SET CodigoINE = '0807'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Mamoré';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Mamoré', '0807'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0808')
BEGIN
    UPDATE Provincia SET Nombre = N'Iténez' WHERE CodigoINE = '0808';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Iténez'
)
BEGIN
    UPDATE p SET CodigoINE = '0808'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '08' AND p.Nombre = N'Iténez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Iténez', '0808'
    FROM Departamento WHERE CodigoINE = '08';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0901')
BEGIN
    UPDATE Provincia SET Nombre = N'Nicolás Suárez' WHERE CodigoINE = '0901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Nicolás Suárez'
)
BEGIN
    UPDATE p SET CodigoINE = '0901'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Nicolás Suárez';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Nicolás Suárez', '0901'
    FROM Departamento WHERE CodigoINE = '09';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0902')
BEGIN
    UPDATE Provincia SET Nombre = N'Manuripi' WHERE CodigoINE = '0902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Manuripi'
)
BEGIN
    UPDATE p SET CodigoINE = '0902'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Manuripi';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Manuripi', '0902'
    FROM Departamento WHERE CodigoINE = '09';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0903')
BEGIN
    UPDATE Provincia SET Nombre = N'Madre de Dios' WHERE CodigoINE = '0903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Madre de Dios'
)
BEGIN
    UPDATE p SET CodigoINE = '0903'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Madre de Dios';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Madre de Dios', '0903'
    FROM Departamento WHERE CodigoINE = '09';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0904')
BEGIN
    UPDATE Provincia SET Nombre = N'Abuná' WHERE CodigoINE = '0904';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Abuná'
)
BEGIN
    UPDATE p SET CodigoINE = '0904'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Abuná';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Abuná', '0904'
    FROM Departamento WHERE CodigoINE = '09';
END;
IF EXISTS (SELECT 1 FROM Provincia WHERE CodigoINE = '0905')
BEGIN
    UPDATE Provincia SET Nombre = N'Federico Román' WHERE CodigoINE = '0905';
END
ELSE IF EXISTS (
    SELECT 1 FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Federico Román'
)
BEGIN
    UPDATE p SET CodigoINE = '0905'
    FROM Provincia p
    INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
    WHERE d.CodigoINE = '09' AND p.Nombre = N'Federico Román';
END
ELSE
BEGIN
    INSERT INTO Provincia (IdDepartamento, Nombre, CodigoINE)
    SELECT IdDepartamento, N'Federico Román', '0905'
    FROM Departamento WHERE CodigoINE = '09';
END;

-- D. Municipios.
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010101')
BEGIN
    UPDATE Municipio SET Nombre = N'Sucre' WHERE CodigoINE = '010101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Sucre'
)
BEGIN
    UPDATE m SET CodigoINE = '010101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Sucre';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sucre', '010101'
    FROM Provincia WHERE CodigoINE = '0101';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010102')
BEGIN
    UPDATE Municipio SET Nombre = N'Yotala' WHERE CodigoINE = '010102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Yotala'
)
BEGIN
    UPDATE m SET CodigoINE = '010102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Yotala';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yotala', '010102'
    FROM Provincia WHERE CodigoINE = '0101';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010103')
BEGIN
    UPDATE Municipio SET Nombre = N'Poroma' WHERE CodigoINE = '010103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Poroma'
)
BEGIN
    UPDATE m SET CodigoINE = '010103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0101' AND m.Nombre = N'Poroma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Poroma', '010103'
    FROM Provincia WHERE CodigoINE = '0101';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010201')
BEGIN
    UPDATE Municipio SET Nombre = N'Azurduy' WHERE CodigoINE = '010201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0102' AND m.Nombre = N'Azurduy'
)
BEGIN
    UPDATE m SET CodigoINE = '010201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0102' AND m.Nombre = N'Azurduy';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Azurduy', '010201'
    FROM Provincia WHERE CodigoINE = '0102';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010202')
BEGIN
    UPDATE Municipio SET Nombre = N'Tarvita' WHERE CodigoINE = '010202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0102' AND m.Nombre = N'Tarvita'
)
BEGIN
    UPDATE m SET CodigoINE = '010202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0102' AND m.Nombre = N'Tarvita';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tarvita', '010202'
    FROM Provincia WHERE CodigoINE = '0102';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010301')
BEGIN
    UPDATE Municipio SET Nombre = N'Zudáñez' WHERE CodigoINE = '010301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Zudáñez'
)
BEGIN
    UPDATE m SET CodigoINE = '010301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Zudáñez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Zudáñez', '010301'
    FROM Provincia WHERE CodigoINE = '0103';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010302')
BEGIN
    UPDATE Municipio SET Nombre = N'Presto' WHERE CodigoINE = '010302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Presto'
)
BEGIN
    UPDATE m SET CodigoINE = '010302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Presto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Presto', '010302'
    FROM Provincia WHERE CodigoINE = '0103';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010303')
BEGIN
    UPDATE Municipio SET Nombre = N'Mojocoya' WHERE CodigoINE = '010303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Mojocoya'
)
BEGIN
    UPDATE m SET CodigoINE = '010303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Mojocoya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mojocoya', '010303'
    FROM Provincia WHERE CodigoINE = '0103';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010304')
BEGIN
    UPDATE Municipio SET Nombre = N'Icla' WHERE CodigoINE = '010304';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Icla'
)
BEGIN
    UPDATE m SET CodigoINE = '010304'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0103' AND m.Nombre = N'Icla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Icla', '010304'
    FROM Provincia WHERE CodigoINE = '0103';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010401')
BEGIN
    UPDATE Municipio SET Nombre = N'Padilla' WHERE CodigoINE = '010401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Padilla'
)
BEGIN
    UPDATE m SET CodigoINE = '010401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Padilla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Padilla', '010401'
    FROM Provincia WHERE CodigoINE = '0104';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010402')
BEGIN
    UPDATE Municipio SET Nombre = N'Tomina' WHERE CodigoINE = '010402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Tomina'
)
BEGIN
    UPDATE m SET CodigoINE = '010402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Tomina';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tomina', '010402'
    FROM Provincia WHERE CodigoINE = '0104';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010403')
BEGIN
    UPDATE Municipio SET Nombre = N'Sopachuy' WHERE CodigoINE = '010403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Sopachuy'
)
BEGIN
    UPDATE m SET CodigoINE = '010403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Sopachuy';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sopachuy', '010403'
    FROM Provincia WHERE CodigoINE = '0104';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010404')
BEGIN
    UPDATE Municipio SET Nombre = N'Alcalá' WHERE CodigoINE = '010404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Alcalá'
)
BEGIN
    UPDATE m SET CodigoINE = '010404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'Alcalá';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Alcalá', '010404'
    FROM Provincia WHERE CodigoINE = '0104';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010405')
BEGIN
    UPDATE Municipio SET Nombre = N'El Villar' WHERE CodigoINE = '010405';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'El Villar'
)
BEGIN
    UPDATE m SET CodigoINE = '010405'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0104' AND m.Nombre = N'El Villar';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Villar', '010405'
    FROM Provincia WHERE CodigoINE = '0104';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010501')
BEGIN
    UPDATE Municipio SET Nombre = N'Monteagudo' WHERE CodigoINE = '010501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0105' AND m.Nombre = N'Monteagudo'
)
BEGIN
    UPDATE m SET CodigoINE = '010501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0105' AND m.Nombre = N'Monteagudo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Monteagudo', '010501'
    FROM Provincia WHERE CodigoINE = '0105';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010502')
BEGIN
    UPDATE Municipio SET Nombre = N'Huacareta' WHERE CodigoINE = '010502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0105' AND m.Nombre = N'Huacareta'
)
BEGIN
    UPDATE m SET CodigoINE = '010502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0105' AND m.Nombre = N'Huacareta';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huacareta', '010502'
    FROM Provincia WHERE CodigoINE = '0105';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010601')
BEGIN
    UPDATE Municipio SET Nombre = N'Tarabuco' WHERE CodigoINE = '010601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0106' AND m.Nombre = N'Tarabuco'
)
BEGIN
    UPDATE m SET CodigoINE = '010601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0106' AND m.Nombre = N'Tarabuco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tarabuco', '010601'
    FROM Provincia WHERE CodigoINE = '0106';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010602')
BEGIN
    UPDATE Municipio SET Nombre = N'Yamparáez' WHERE CodigoINE = '010602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0106' AND m.Nombre = N'Yamparáez'
)
BEGIN
    UPDATE m SET CodigoINE = '010602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0106' AND m.Nombre = N'Yamparáez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yamparáez', '010602'
    FROM Provincia WHERE CodigoINE = '0106';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010701')
BEGIN
    UPDATE Municipio SET Nombre = N'Camargo' WHERE CodigoINE = '010701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Camargo'
)
BEGIN
    UPDATE m SET CodigoINE = '010701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Camargo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Camargo', '010701'
    FROM Provincia WHERE CodigoINE = '0107';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010702')
BEGIN
    UPDATE Municipio SET Nombre = N'San Lucas' WHERE CodigoINE = '010702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'San Lucas'
)
BEGIN
    UPDATE m SET CodigoINE = '010702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'San Lucas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Lucas', '010702'
    FROM Provincia WHERE CodigoINE = '0107';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010703')
BEGIN
    UPDATE Municipio SET Nombre = N'Incahuasi' WHERE CodigoINE = '010703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Incahuasi'
)
BEGIN
    UPDATE m SET CodigoINE = '010703'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Incahuasi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Incahuasi', '010703'
    FROM Provincia WHERE CodigoINE = '0107';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010704')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Charcas' WHERE CodigoINE = '010704';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Villa Charcas'
)
BEGIN
    UPDATE m SET CodigoINE = '010704'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0107' AND m.Nombre = N'Villa Charcas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Charcas', '010704'
    FROM Provincia WHERE CodigoINE = '0107';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010801')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Serrano' WHERE CodigoINE = '010801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0108' AND m.Nombre = N'Villa Serrano'
)
BEGIN
    UPDATE m SET CodigoINE = '010801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0108' AND m.Nombre = N'Villa Serrano';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Serrano', '010801'
    FROM Provincia WHERE CodigoINE = '0108';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010901')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Abecia' WHERE CodigoINE = '010901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Villa Abecia'
)
BEGIN
    UPDATE m SET CodigoINE = '010901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Villa Abecia';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Abecia', '010901'
    FROM Provincia WHERE CodigoINE = '0109';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010902')
BEGIN
    UPDATE Municipio SET Nombre = N'Culpina' WHERE CodigoINE = '010902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Culpina'
)
BEGIN
    UPDATE m SET CodigoINE = '010902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Culpina';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Culpina', '010902'
    FROM Provincia WHERE CodigoINE = '0109';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '010903')
BEGIN
    UPDATE Municipio SET Nombre = N'Las Carreras' WHERE CodigoINE = '010903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Las Carreras'
)
BEGIN
    UPDATE m SET CodigoINE = '010903'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0109' AND m.Nombre = N'Las Carreras';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Las Carreras', '010903'
    FROM Provincia WHERE CodigoINE = '0109';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '011001')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Vaca Guzmán' WHERE CodigoINE = '011001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Villa Vaca Guzmán'
)
BEGIN
    UPDATE m SET CodigoINE = '011001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Villa Vaca Guzmán';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Vaca Guzmán', '011001'
    FROM Provincia WHERE CodigoINE = '0110';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '011002')
BEGIN
    UPDATE Municipio SET Nombre = N'Huacaya (Autonomía Guaraní Chaqueño de Huacaya)' WHERE CodigoINE = '011002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Huacaya (Autonomía Guaraní Chaqueño de Huacaya)'
)
BEGIN
    UPDATE m SET CodigoINE = '011002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Huacaya (Autonomía Guaraní Chaqueño de Huacaya)';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huacaya (Autonomía Guaraní Chaqueño de Huacaya)', '011002'
    FROM Provincia WHERE CodigoINE = '0110';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '011003')
BEGIN
    UPDATE Municipio SET Nombre = N'Macharetí' WHERE CodigoINE = '011003';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Macharetí'
)
BEGIN
    UPDATE m SET CodigoINE = '011003'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0110' AND m.Nombre = N'Macharetí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Macharetí', '011003'
    FROM Provincia WHERE CodigoINE = '0110';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020101')
BEGIN
    UPDATE Municipio SET Nombre = N'Nuestra Señora de La Paz' WHERE CodigoINE = '020101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Nuestra Señora de La Paz'
)
BEGIN
    UPDATE m SET CodigoINE = '020101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Nuestra Señora de La Paz';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Nuestra Señora de La Paz', '020101'
    FROM Provincia WHERE CodigoINE = '0201';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020102')
BEGIN
    UPDATE Municipio SET Nombre = N'Palca' WHERE CodigoINE = '020102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Palca'
)
BEGIN
    UPDATE m SET CodigoINE = '020102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Palca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Palca', '020102'
    FROM Provincia WHERE CodigoINE = '0201';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020103')
BEGIN
    UPDATE Municipio SET Nombre = N'Mecapaca' WHERE CodigoINE = '020103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Mecapaca'
)
BEGIN
    UPDATE m SET CodigoINE = '020103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Mecapaca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mecapaca', '020103'
    FROM Provincia WHERE CodigoINE = '0201';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020104')
BEGIN
    UPDATE Municipio SET Nombre = N'Achocalla' WHERE CodigoINE = '020104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Achocalla'
)
BEGIN
    UPDATE m SET CodigoINE = '020104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'Achocalla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Achocalla', '020104'
    FROM Provincia WHERE CodigoINE = '0201';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020105')
BEGIN
    UPDATE Municipio SET Nombre = N'El Alto' WHERE CodigoINE = '020105';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'El Alto'
)
BEGIN
    UPDATE m SET CodigoINE = '020105'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0201' AND m.Nombre = N'El Alto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Alto', '020105'
    FROM Provincia WHERE CodigoINE = '0201';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020201')
BEGIN
    UPDATE Municipio SET Nombre = N'Achacachi' WHERE CodigoINE = '020201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Achacachi'
)
BEGIN
    UPDATE m SET CodigoINE = '020201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Achacachi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Achacachi', '020201'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020202')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Ancoraimes' WHERE CodigoINE = '020202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Villa Ancoraimes'
)
BEGIN
    UPDATE m SET CodigoINE = '020202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Villa Ancoraimes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Ancoraimes', '020202'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020203')
BEGIN
    UPDATE Municipio SET Nombre = N'Huarina' WHERE CodigoINE = '020203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Huarina'
)
BEGIN
    UPDATE m SET CodigoINE = '020203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Huarina';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huarina', '020203'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020204')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiago de Huata' WHERE CodigoINE = '020204';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Santiago de Huata'
)
BEGIN
    UPDATE m SET CodigoINE = '020204'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Santiago de Huata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiago de Huata', '020204'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020205')
BEGIN
    UPDATE Municipio SET Nombre = N'Huatajata' WHERE CodigoINE = '020205';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Huatajata'
)
BEGIN
    UPDATE m SET CodigoINE = '020205'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Huatajata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huatajata', '020205'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020206')
BEGIN
    UPDATE Municipio SET Nombre = N'Chua Cocani' WHERE CodigoINE = '020206';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Chua Cocani'
)
BEGIN
    UPDATE m SET CodigoINE = '020206'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0202' AND m.Nombre = N'Chua Cocani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chua Cocani', '020206'
    FROM Provincia WHERE CodigoINE = '0202';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020301')
BEGIN
    UPDATE Municipio SET Nombre = N'Corocoro' WHERE CodigoINE = '020301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Corocoro'
)
BEGIN
    UPDATE m SET CodigoINE = '020301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Corocoro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Corocoro', '020301'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020302')
BEGIN
    UPDATE Municipio SET Nombre = N'Caquiaviri' WHERE CodigoINE = '020302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Caquiaviri'
)
BEGIN
    UPDATE m SET CodigoINE = '020302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Caquiaviri';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caquiaviri', '020302'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020303')
BEGIN
    UPDATE Municipio SET Nombre = N'Calacoto' WHERE CodigoINE = '020303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Calacoto'
)
BEGIN
    UPDATE m SET CodigoINE = '020303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Calacoto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Calacoto', '020303'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020304')
BEGIN
    UPDATE Municipio SET Nombre = N'Comanche' WHERE CodigoINE = '020304';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Comanche'
)
BEGIN
    UPDATE m SET CodigoINE = '020304'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Comanche';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Comanche', '020304'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020305')
BEGIN
    UPDATE Municipio SET Nombre = N'Charaña' WHERE CodigoINE = '020305';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Charaña'
)
BEGIN
    UPDATE m SET CodigoINE = '020305'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Charaña';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Charaña', '020305'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020306')
BEGIN
    UPDATE Municipio SET Nombre = N'Waldo Ballivián' WHERE CodigoINE = '020306';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Waldo Ballivián'
)
BEGIN
    UPDATE m SET CodigoINE = '020306'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Waldo Ballivián';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Waldo Ballivián', '020306'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020307')
BEGIN
    UPDATE Municipio SET Nombre = N'Nazacara de Pacajes' WHERE CodigoINE = '020307';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Nazacara de Pacajes'
)
BEGIN
    UPDATE m SET CodigoINE = '020307'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Nazacara de Pacajes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Nazacara de Pacajes', '020307'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020308')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiago de Callapa' WHERE CodigoINE = '020308';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Santiago de Callapa'
)
BEGIN
    UPDATE m SET CodigoINE = '020308'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0203' AND m.Nombre = N'Santiago de Callapa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiago de Callapa', '020308'
    FROM Provincia WHERE CodigoINE = '0203';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020401')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Acosta' WHERE CodigoINE = '020401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Puerto Acosta'
)
BEGIN
    UPDATE m SET CodigoINE = '020401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Puerto Acosta';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Acosta', '020401'
    FROM Provincia WHERE CodigoINE = '0204';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020402')
BEGIN
    UPDATE Municipio SET Nombre = N'Mocomoco' WHERE CodigoINE = '020402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Mocomoco'
)
BEGIN
    UPDATE m SET CodigoINE = '020402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Mocomoco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mocomoco', '020402'
    FROM Provincia WHERE CodigoINE = '0204';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020403')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Mayor de Carabuco' WHERE CodigoINE = '020403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Puerto Mayor de Carabuco'
)
BEGIN
    UPDATE m SET CodigoINE = '020403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Puerto Mayor de Carabuco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Mayor de Carabuco', '020403'
    FROM Provincia WHERE CodigoINE = '0204';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020404')
BEGIN
    UPDATE Municipio SET Nombre = N'Humanata' WHERE CodigoINE = '020404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Humanata'
)
BEGIN
    UPDATE m SET CodigoINE = '020404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Humanata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Humanata', '020404'
    FROM Provincia WHERE CodigoINE = '0204';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020405')
BEGIN
    UPDATE Municipio SET Nombre = N'Escoma' WHERE CodigoINE = '020405';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Escoma'
)
BEGIN
    UPDATE m SET CodigoINE = '020405'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0204' AND m.Nombre = N'Escoma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Escoma', '020405'
    FROM Provincia WHERE CodigoINE = '0204';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020501')
BEGIN
    UPDATE Municipio SET Nombre = N'Chuma' WHERE CodigoINE = '020501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Chuma'
)
BEGIN
    UPDATE m SET CodigoINE = '020501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Chuma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chuma', '020501'
    FROM Provincia WHERE CodigoINE = '0205';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020502')
BEGIN
    UPDATE Municipio SET Nombre = N'Ayata' WHERE CodigoINE = '020502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Ayata'
)
BEGIN
    UPDATE m SET CodigoINE = '020502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Ayata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ayata', '020502'
    FROM Provincia WHERE CodigoINE = '0205';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020503')
BEGIN
    UPDATE Municipio SET Nombre = N'Aucapata' WHERE CodigoINE = '020503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Aucapata'
)
BEGIN
    UPDATE m SET CodigoINE = '020503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0205' AND m.Nombre = N'Aucapata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Aucapata', '020503'
    FROM Provincia WHERE CodigoINE = '0205';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020601')
BEGIN
    UPDATE Municipio SET Nombre = N'Sorata' WHERE CodigoINE = '020601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Sorata'
)
BEGIN
    UPDATE m SET CodigoINE = '020601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Sorata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sorata', '020601'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020602')
BEGIN
    UPDATE Municipio SET Nombre = N'Guanay' WHERE CodigoINE = '020602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Guanay'
)
BEGIN
    UPDATE m SET CodigoINE = '020602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Guanay';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Guanay', '020602'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020603')
BEGIN
    UPDATE Municipio SET Nombre = N'Tacacoma' WHERE CodigoINE = '020603';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Tacacoma'
)
BEGIN
    UPDATE m SET CodigoINE = '020603'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Tacacoma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tacacoma', '020603'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020604')
BEGIN
    UPDATE Municipio SET Nombre = N'Quiabaya' WHERE CodigoINE = '020604';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Quiabaya'
)
BEGIN
    UPDATE m SET CodigoINE = '020604'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Quiabaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Quiabaya', '020604'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020605')
BEGIN
    UPDATE Municipio SET Nombre = N'Combaya' WHERE CodigoINE = '020605';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Combaya'
)
BEGIN
    UPDATE m SET CodigoINE = '020605'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Combaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Combaya', '020605'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020606')
BEGIN
    UPDATE Municipio SET Nombre = N'Tipuani' WHERE CodigoINE = '020606';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Tipuani'
)
BEGIN
    UPDATE m SET CodigoINE = '020606'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Tipuani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tipuani', '020606'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020607')
BEGIN
    UPDATE Municipio SET Nombre = N'Mapiri' WHERE CodigoINE = '020607';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Mapiri'
)
BEGIN
    UPDATE m SET CodigoINE = '020607'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Mapiri';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mapiri', '020607'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020608')
BEGIN
    UPDATE Municipio SET Nombre = N'Teoponte' WHERE CodigoINE = '020608';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Teoponte'
)
BEGIN
    UPDATE m SET CodigoINE = '020608'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0206' AND m.Nombre = N'Teoponte';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Teoponte', '020608'
    FROM Provincia WHERE CodigoINE = '0206';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020701')
BEGIN
    UPDATE Municipio SET Nombre = N'Apolo' WHERE CodigoINE = '020701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0207' AND m.Nombre = N'Apolo'
)
BEGIN
    UPDATE m SET CodigoINE = '020701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0207' AND m.Nombre = N'Apolo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Apolo', '020701'
    FROM Provincia WHERE CodigoINE = '0207';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020702')
BEGIN
    UPDATE Municipio SET Nombre = N'Pelechuco' WHERE CodigoINE = '020702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0207' AND m.Nombre = N'Pelechuco'
)
BEGIN
    UPDATE m SET CodigoINE = '020702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0207' AND m.Nombre = N'Pelechuco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pelechuco', '020702'
    FROM Provincia WHERE CodigoINE = '0207';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020801')
BEGIN
    UPDATE Municipio SET Nombre = N'Viacha' WHERE CodigoINE = '020801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Viacha'
)
BEGIN
    UPDATE m SET CodigoINE = '020801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Viacha';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Viacha', '020801'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020802')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Mayor de Guaqui' WHERE CodigoINE = '020802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Puerto Mayor de Guaqui'
)
BEGIN
    UPDATE m SET CodigoINE = '020802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Puerto Mayor de Guaqui';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Mayor de Guaqui', '020802'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020803')
BEGIN
    UPDATE Municipio SET Nombre = N'Tiahuanacu' WHERE CodigoINE = '020803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Tiahuanacu'
)
BEGIN
    UPDATE m SET CodigoINE = '020803'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Tiahuanacu';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tiahuanacu', '020803'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020804')
BEGIN
    UPDATE Municipio SET Nombre = N'Desaguadero' WHERE CodigoINE = '020804';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Desaguadero'
)
BEGIN
    UPDATE m SET CodigoINE = '020804'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Desaguadero';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Desaguadero', '020804'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020805')
BEGIN
    UPDATE Municipio SET Nombre = N'La (Marka) San Andrés de Machaca' WHERE CodigoINE = '020805';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'La (Marka) San Andrés de Machaca'
)
BEGIN
    UPDATE m SET CodigoINE = '020805'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'La (Marka) San Andrés de Machaca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'La (Marka) San Andrés de Machaca', '020805'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020806')
BEGIN
    UPDATE Municipio SET Nombre = N'Jesús de Machaka' WHERE CodigoINE = '020806';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Jesús de Machaka'
)
BEGIN
    UPDATE m SET CodigoINE = '020806'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Jesús de Machaka';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Jesús de Machaka', '020806'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020807')
BEGIN
    UPDATE Municipio SET Nombre = N'Taraco' WHERE CodigoINE = '020807';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Taraco'
)
BEGIN
    UPDATE m SET CodigoINE = '020807'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0208' AND m.Nombre = N'Taraco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Taraco', '020807'
    FROM Provincia WHERE CodigoINE = '0208';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020901')
BEGIN
    UPDATE Municipio SET Nombre = N'Luribay' WHERE CodigoINE = '020901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Luribay'
)
BEGIN
    UPDATE m SET CodigoINE = '020901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Luribay';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Luribay', '020901'
    FROM Provincia WHERE CodigoINE = '0209';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020902')
BEGIN
    UPDATE Municipio SET Nombre = N'Sapahaqui' WHERE CodigoINE = '020902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Sapahaqui'
)
BEGIN
    UPDATE m SET CodigoINE = '020902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Sapahaqui';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sapahaqui', '020902'
    FROM Provincia WHERE CodigoINE = '0209';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020903')
BEGIN
    UPDATE Municipio SET Nombre = N'Yaco' WHERE CodigoINE = '020903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Yaco'
)
BEGIN
    UPDATE m SET CodigoINE = '020903'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Yaco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yaco', '020903'
    FROM Provincia WHERE CodigoINE = '0209';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020904')
BEGIN
    UPDATE Municipio SET Nombre = N'Malla' WHERE CodigoINE = '020904';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Malla'
)
BEGIN
    UPDATE m SET CodigoINE = '020904'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Malla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Malla', '020904'
    FROM Provincia WHERE CodigoINE = '0209';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '020905')
BEGIN
    UPDATE Municipio SET Nombre = N'Cairoma' WHERE CodigoINE = '020905';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Cairoma'
)
BEGIN
    UPDATE m SET CodigoINE = '020905'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0209' AND m.Nombre = N'Cairoma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cairoma', '020905'
    FROM Provincia WHERE CodigoINE = '0209';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021001')
BEGIN
    UPDATE Municipio SET Nombre = N'Inquisivi' WHERE CodigoINE = '021001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Inquisivi'
)
BEGIN
    UPDATE m SET CodigoINE = '021001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Inquisivi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Inquisivi', '021001'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021002')
BEGIN
    UPDATE Municipio SET Nombre = N'Quime' WHERE CodigoINE = '021002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Quime'
)
BEGIN
    UPDATE m SET CodigoINE = '021002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Quime';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Quime', '021002'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021003')
BEGIN
    UPDATE Municipio SET Nombre = N'Cajuata' WHERE CodigoINE = '021003';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Cajuata'
)
BEGIN
    UPDATE m SET CodigoINE = '021003'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Cajuata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cajuata', '021003'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021004')
BEGIN
    UPDATE Municipio SET Nombre = N'Colquiri' WHERE CodigoINE = '021004';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Colquiri'
)
BEGIN
    UPDATE m SET CodigoINE = '021004'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Colquiri';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colquiri', '021004'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021005')
BEGIN
    UPDATE Municipio SET Nombre = N'Ichoca' WHERE CodigoINE = '021005';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Ichoca'
)
BEGIN
    UPDATE m SET CodigoINE = '021005'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Ichoca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ichoca', '021005'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021006')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Libertad Licoma' WHERE CodigoINE = '021006';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Villa Libertad Licoma'
)
BEGIN
    UPDATE m SET CodigoINE = '021006'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0210' AND m.Nombre = N'Villa Libertad Licoma';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Libertad Licoma', '021006'
    FROM Provincia WHERE CodigoINE = '0210';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021101')
BEGIN
    UPDATE Municipio SET Nombre = N'Chulumani' WHERE CodigoINE = '021101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Chulumani'
)
BEGIN
    UPDATE m SET CodigoINE = '021101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Chulumani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chulumani', '021101'
    FROM Provincia WHERE CodigoINE = '0211';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021102')
BEGIN
    UPDATE Municipio SET Nombre = N'Irupana' WHERE CodigoINE = '021102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Irupana'
)
BEGIN
    UPDATE m SET CodigoINE = '021102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Irupana';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Irupana', '021102'
    FROM Provincia WHERE CodigoINE = '0211';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021103')
BEGIN
    UPDATE Municipio SET Nombre = N'Yanacachi' WHERE CodigoINE = '021103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Yanacachi'
)
BEGIN
    UPDATE m SET CodigoINE = '021103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Yanacachi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yanacachi', '021103'
    FROM Provincia WHERE CodigoINE = '0211';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021104')
BEGIN
    UPDATE Municipio SET Nombre = N'Palos Blancos' WHERE CodigoINE = '021104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Palos Blancos'
)
BEGIN
    UPDATE m SET CodigoINE = '021104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'Palos Blancos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Palos Blancos', '021104'
    FROM Provincia WHERE CodigoINE = '0211';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021105')
BEGIN
    UPDATE Municipio SET Nombre = N'La Asunta' WHERE CodigoINE = '021105';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'La Asunta'
)
BEGIN
    UPDATE m SET CodigoINE = '021105'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0211' AND m.Nombre = N'La Asunta';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'La Asunta', '021105'
    FROM Provincia WHERE CodigoINE = '0211';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021201')
BEGIN
    UPDATE Municipio SET Nombre = N'Pucarani' WHERE CodigoINE = '021201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Pucarani'
)
BEGIN
    UPDATE m SET CodigoINE = '021201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Pucarani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pucarani', '021201'
    FROM Provincia WHERE CodigoINE = '0212';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021202')
BEGIN
    UPDATE Municipio SET Nombre = N'Laja' WHERE CodigoINE = '021202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Laja'
)
BEGIN
    UPDATE m SET CodigoINE = '021202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Laja';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Laja', '021202'
    FROM Provincia WHERE CodigoINE = '0212';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021203')
BEGIN
    UPDATE Municipio SET Nombre = N'Batallas' WHERE CodigoINE = '021203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Batallas'
)
BEGIN
    UPDATE m SET CodigoINE = '021203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Batallas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Batallas', '021203'
    FROM Provincia WHERE CodigoINE = '0212';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021204')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Pérez' WHERE CodigoINE = '021204';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Puerto Pérez'
)
BEGIN
    UPDATE m SET CodigoINE = '021204'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0212' AND m.Nombre = N'Puerto Pérez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Pérez', '021204'
    FROM Provincia WHERE CodigoINE = '0212';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021301')
BEGIN
    UPDATE Municipio SET Nombre = N'Sicasica' WHERE CodigoINE = '021301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Sicasica'
)
BEGIN
    UPDATE m SET CodigoINE = '021301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Sicasica';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sicasica', '021301'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021302')
BEGIN
    UPDATE Municipio SET Nombre = N'Umala' WHERE CodigoINE = '021302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Umala'
)
BEGIN
    UPDATE m SET CodigoINE = '021302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Umala';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Umala', '021302'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021303')
BEGIN
    UPDATE Municipio SET Nombre = N'Ayo Ayo' WHERE CodigoINE = '021303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Ayo Ayo'
)
BEGIN
    UPDATE m SET CodigoINE = '021303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Ayo Ayo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ayo Ayo', '021303'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021304')
BEGIN
    UPDATE Municipio SET Nombre = N'Calamarca' WHERE CodigoINE = '021304';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Calamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '021304'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Calamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Calamarca', '021304'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021305')
BEGIN
    UPDATE Municipio SET Nombre = N'Patacamaya' WHERE CodigoINE = '021305';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Patacamaya'
)
BEGIN
    UPDATE m SET CodigoINE = '021305'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Patacamaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Patacamaya', '021305'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021306')
BEGIN
    UPDATE Municipio SET Nombre = N'Colquencha' WHERE CodigoINE = '021306';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Colquencha'
)
BEGIN
    UPDATE m SET CodigoINE = '021306'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Colquencha';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colquencha', '021306'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021307')
BEGIN
    UPDATE Municipio SET Nombre = N'Collana' WHERE CodigoINE = '021307';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Collana'
)
BEGIN
    UPDATE m SET CodigoINE = '021307'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0213' AND m.Nombre = N'Collana';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Collana', '021307'
    FROM Provincia WHERE CodigoINE = '0213';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021401')
BEGIN
    UPDATE Municipio SET Nombre = N'Coroico' WHERE CodigoINE = '021401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0214' AND m.Nombre = N'Coroico'
)
BEGIN
    UPDATE m SET CodigoINE = '021401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0214' AND m.Nombre = N'Coroico';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Coroico', '021401'
    FROM Provincia WHERE CodigoINE = '0214';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021402')
BEGIN
    UPDATE Municipio SET Nombre = N'Coripata' WHERE CodigoINE = '021402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0214' AND m.Nombre = N'Coripata'
)
BEGIN
    UPDATE m SET CodigoINE = '021402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0214' AND m.Nombre = N'Coripata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Coripata', '021402'
    FROM Provincia WHERE CodigoINE = '0214';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021501')
BEGIN
    UPDATE Municipio SET Nombre = N'Ixiamas' WHERE CodigoINE = '021501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0215' AND m.Nombre = N'Ixiamas'
)
BEGIN
    UPDATE m SET CodigoINE = '021501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0215' AND m.Nombre = N'Ixiamas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ixiamas', '021501'
    FROM Provincia WHERE CodigoINE = '0215';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021502')
BEGIN
    UPDATE Municipio SET Nombre = N'San Buenaventura' WHERE CodigoINE = '021502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0215' AND m.Nombre = N'San Buenaventura'
)
BEGIN
    UPDATE m SET CodigoINE = '021502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0215' AND m.Nombre = N'San Buenaventura';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Buenaventura', '021502'
    FROM Provincia WHERE CodigoINE = '0215';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021601')
BEGIN
    UPDATE Municipio SET Nombre = N'Charazani' WHERE CodigoINE = '021601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0216' AND m.Nombre = N'Charazani'
)
BEGIN
    UPDATE m SET CodigoINE = '021601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0216' AND m.Nombre = N'Charazani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Charazani', '021601'
    FROM Provincia WHERE CodigoINE = '0216';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021602')
BEGIN
    UPDATE Municipio SET Nombre = N'Curva' WHERE CodigoINE = '021602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0216' AND m.Nombre = N'Curva'
)
BEGIN
    UPDATE m SET CodigoINE = '021602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0216' AND m.Nombre = N'Curva';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Curva', '021602'
    FROM Provincia WHERE CodigoINE = '0216';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021701')
BEGIN
    UPDATE Municipio SET Nombre = N'Copacabana' WHERE CodigoINE = '021701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'Copacabana'
)
BEGIN
    UPDATE m SET CodigoINE = '021701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'Copacabana';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Copacabana', '021701'
    FROM Provincia WHERE CodigoINE = '0217';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021702')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro de Tiquina' WHERE CodigoINE = '021702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'San Pedro de Tiquina'
)
BEGIN
    UPDATE m SET CodigoINE = '021702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'San Pedro de Tiquina';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro de Tiquina', '021702'
    FROM Provincia WHERE CodigoINE = '0217';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021703')
BEGIN
    UPDATE Municipio SET Nombre = N'Tito Yupanqui' WHERE CodigoINE = '021703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'Tito Yupanqui'
)
BEGIN
    UPDATE m SET CodigoINE = '021703'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0217' AND m.Nombre = N'Tito Yupanqui';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tito Yupanqui', '021703'
    FROM Provincia WHERE CodigoINE = '0217';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021801')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro de Curahuara' WHERE CodigoINE = '021801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'San Pedro de Curahuara'
)
BEGIN
    UPDATE m SET CodigoINE = '021801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'San Pedro de Curahuara';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro de Curahuara', '021801'
    FROM Provincia WHERE CodigoINE = '0218';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021802')
BEGIN
    UPDATE Municipio SET Nombre = N'Papel Pampa' WHERE CodigoINE = '021802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'Papel Pampa'
)
BEGIN
    UPDATE m SET CodigoINE = '021802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'Papel Pampa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Papel Pampa', '021802'
    FROM Provincia WHERE CodigoINE = '0218';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021803')
BEGIN
    UPDATE Municipio SET Nombre = N'Chacarilla' WHERE CodigoINE = '021803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'Chacarilla'
)
BEGIN
    UPDATE m SET CodigoINE = '021803'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0218' AND m.Nombre = N'Chacarilla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chacarilla', '021803'
    FROM Provincia WHERE CodigoINE = '0218';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021901')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiago de Machaca' WHERE CodigoINE = '021901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0219' AND m.Nombre = N'Santiago de Machaca'
)
BEGIN
    UPDATE m SET CodigoINE = '021901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0219' AND m.Nombre = N'Santiago de Machaca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiago de Machaca', '021901'
    FROM Provincia WHERE CodigoINE = '0219';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '021902')
BEGIN
    UPDATE Municipio SET Nombre = N'Catacora' WHERE CodigoINE = '021902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0219' AND m.Nombre = N'Catacora'
)
BEGIN
    UPDATE m SET CodigoINE = '021902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0219' AND m.Nombre = N'Catacora';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Catacora', '021902'
    FROM Provincia WHERE CodigoINE = '0219';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '022001')
BEGIN
    UPDATE Municipio SET Nombre = N'Caranavi' WHERE CodigoINE = '022001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0220' AND m.Nombre = N'Caranavi'
)
BEGIN
    UPDATE m SET CodigoINE = '022001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0220' AND m.Nombre = N'Caranavi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caranavi', '022001'
    FROM Provincia WHERE CodigoINE = '0220';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '022002')
BEGIN
    UPDATE Municipio SET Nombre = N'Alto Beni' WHERE CodigoINE = '022002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0220' AND m.Nombre = N'Alto Beni'
)
BEGIN
    UPDATE m SET CodigoINE = '022002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0220' AND m.Nombre = N'Alto Beni';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Alto Beni', '022002'
    FROM Provincia WHERE CodigoINE = '0220';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030101')
BEGIN
    UPDATE Municipio SET Nombre = N'Cochabamba' WHERE CodigoINE = '030101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0301' AND m.Nombre = N'Cochabamba'
)
BEGIN
    UPDATE m SET CodigoINE = '030101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0301' AND m.Nombre = N'Cochabamba';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cochabamba', '030101'
    FROM Provincia WHERE CodigoINE = '0301';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030201')
BEGIN
    UPDATE Municipio SET Nombre = N'Aiquile' WHERE CodigoINE = '030201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Aiquile'
)
BEGIN
    UPDATE m SET CodigoINE = '030201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Aiquile';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Aiquile', '030201'
    FROM Provincia WHERE CodigoINE = '0302';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030202')
BEGIN
    UPDATE Municipio SET Nombre = N'Pasorapa' WHERE CodigoINE = '030202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Pasorapa'
)
BEGIN
    UPDATE m SET CodigoINE = '030202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Pasorapa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pasorapa', '030202'
    FROM Provincia WHERE CodigoINE = '0302';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030203')
BEGIN
    UPDATE Municipio SET Nombre = N'Omereque' WHERE CodigoINE = '030203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Omereque'
)
BEGIN
    UPDATE m SET CodigoINE = '030203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0302' AND m.Nombre = N'Omereque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Omereque', '030203'
    FROM Provincia WHERE CodigoINE = '0302';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030301')
BEGIN
    UPDATE Municipio SET Nombre = N'Ayopaya' WHERE CodigoINE = '030301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Ayopaya'
)
BEGIN
    UPDATE m SET CodigoINE = '030301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Ayopaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ayopaya', '030301'
    FROM Provincia WHERE CodigoINE = '0303';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030302')
BEGIN
    UPDATE Municipio SET Nombre = N'Morochata' WHERE CodigoINE = '030302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Morochata'
)
BEGIN
    UPDATE m SET CodigoINE = '030302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Morochata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Morochata', '030302'
    FROM Provincia WHERE CodigoINE = '0303';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030303')
BEGIN
    UPDATE Municipio SET Nombre = N'Cocapata' WHERE CodigoINE = '030303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Cocapata'
)
BEGIN
    UPDATE m SET CodigoINE = '030303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0303' AND m.Nombre = N'Cocapata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cocapata', '030303'
    FROM Provincia WHERE CodigoINE = '0303';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030401')
BEGIN
    UPDATE Municipio SET Nombre = N'Tarata' WHERE CodigoINE = '030401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Tarata'
)
BEGIN
    UPDATE m SET CodigoINE = '030401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Tarata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tarata', '030401'
    FROM Provincia WHERE CodigoINE = '0304';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030402')
BEGIN
    UPDATE Municipio SET Nombre = N'Anzaldo' WHERE CodigoINE = '030402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Anzaldo'
)
BEGIN
    UPDATE m SET CodigoINE = '030402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Anzaldo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Anzaldo', '030402'
    FROM Provincia WHERE CodigoINE = '0304';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030403')
BEGIN
    UPDATE Municipio SET Nombre = N'Arbieto' WHERE CodigoINE = '030403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Arbieto'
)
BEGIN
    UPDATE m SET CodigoINE = '030403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Arbieto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Arbieto', '030403'
    FROM Provincia WHERE CodigoINE = '0304';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030404')
BEGIN
    UPDATE Municipio SET Nombre = N'Sacabamba' WHERE CodigoINE = '030404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Sacabamba'
)
BEGIN
    UPDATE m SET CodigoINE = '030404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0304' AND m.Nombre = N'Sacabamba';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sacabamba', '030404'
    FROM Provincia WHERE CodigoINE = '0304';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030501')
BEGIN
    UPDATE Municipio SET Nombre = N'Arani' WHERE CodigoINE = '030501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0305' AND m.Nombre = N'Arani'
)
BEGIN
    UPDATE m SET CodigoINE = '030501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0305' AND m.Nombre = N'Arani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Arani', '030501'
    FROM Provincia WHERE CodigoINE = '0305';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030502')
BEGIN
    UPDATE Municipio SET Nombre = N'Vacas' WHERE CodigoINE = '030502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0305' AND m.Nombre = N'Vacas'
)
BEGIN
    UPDATE m SET CodigoINE = '030502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0305' AND m.Nombre = N'Vacas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Vacas', '030502'
    FROM Provincia WHERE CodigoINE = '0305';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030601')
BEGIN
    UPDATE Municipio SET Nombre = N'Arque' WHERE CodigoINE = '030601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0306' AND m.Nombre = N'Arque'
)
BEGIN
    UPDATE m SET CodigoINE = '030601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0306' AND m.Nombre = N'Arque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Arque', '030601'
    FROM Provincia WHERE CodigoINE = '0306';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030602')
BEGIN
    UPDATE Municipio SET Nombre = N'Tacopaya' WHERE CodigoINE = '030602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0306' AND m.Nombre = N'Tacopaya'
)
BEGIN
    UPDATE m SET CodigoINE = '030602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0306' AND m.Nombre = N'Tacopaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tacopaya', '030602'
    FROM Provincia WHERE CodigoINE = '0306';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030701')
BEGIN
    UPDATE Municipio SET Nombre = N'Capinota' WHERE CodigoINE = '030701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Capinota'
)
BEGIN
    UPDATE m SET CodigoINE = '030701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Capinota';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Capinota', '030701'
    FROM Provincia WHERE CodigoINE = '0307';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030702')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiváñez' WHERE CodigoINE = '030702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Santiváñez'
)
BEGIN
    UPDATE m SET CodigoINE = '030702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Santiváñez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiváñez', '030702'
    FROM Provincia WHERE CodigoINE = '0307';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030703')
BEGIN
    UPDATE Municipio SET Nombre = N'Sicaya' WHERE CodigoINE = '030703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Sicaya'
)
BEGIN
    UPDATE m SET CodigoINE = '030703'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0307' AND m.Nombre = N'Sicaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sicaya', '030703'
    FROM Provincia WHERE CodigoINE = '0307';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030801')
BEGIN
    UPDATE Municipio SET Nombre = N'Cliza' WHERE CodigoINE = '030801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Cliza'
)
BEGIN
    UPDATE m SET CodigoINE = '030801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Cliza';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cliza', '030801'
    FROM Provincia WHERE CodigoINE = '0308';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030802')
BEGIN
    UPDATE Municipio SET Nombre = N'Toco' WHERE CodigoINE = '030802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Toco'
)
BEGIN
    UPDATE m SET CodigoINE = '030802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Toco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Toco', '030802'
    FROM Provincia WHERE CodigoINE = '0308';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030803')
BEGIN
    UPDATE Municipio SET Nombre = N'Tolata' WHERE CodigoINE = '030803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Tolata'
)
BEGIN
    UPDATE m SET CodigoINE = '030803'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0308' AND m.Nombre = N'Tolata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tolata', '030803'
    FROM Provincia WHERE CodigoINE = '0308';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030901')
BEGIN
    UPDATE Municipio SET Nombre = N'Quillacollo' WHERE CodigoINE = '030901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Quillacollo'
)
BEGIN
    UPDATE m SET CodigoINE = '030901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Quillacollo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Quillacollo', '030901'
    FROM Provincia WHERE CodigoINE = '0309';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030902')
BEGIN
    UPDATE Municipio SET Nombre = N'Sipesipe' WHERE CodigoINE = '030902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Sipesipe'
)
BEGIN
    UPDATE m SET CodigoINE = '030902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Sipesipe';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sipesipe', '030902'
    FROM Provincia WHERE CodigoINE = '0309';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030903')
BEGIN
    UPDATE Municipio SET Nombre = N'Tiquipaya' WHERE CodigoINE = '030903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Tiquipaya'
)
BEGIN
    UPDATE m SET CodigoINE = '030903'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Tiquipaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tiquipaya', '030903'
    FROM Provincia WHERE CodigoINE = '0309';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030904')
BEGIN
    UPDATE Municipio SET Nombre = N'Vinto' WHERE CodigoINE = '030904';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Vinto'
)
BEGIN
    UPDATE m SET CodigoINE = '030904'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Vinto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Vinto', '030904'
    FROM Provincia WHERE CodigoINE = '0309';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '030905')
BEGIN
    UPDATE Municipio SET Nombre = N'Colcapirhua' WHERE CodigoINE = '030905';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Colcapirhua'
)
BEGIN
    UPDATE m SET CodigoINE = '030905'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0309' AND m.Nombre = N'Colcapirhua';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colcapirhua', '030905'
    FROM Provincia WHERE CodigoINE = '0309';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031001')
BEGIN
    UPDATE Municipio SET Nombre = N'Sacaba' WHERE CodigoINE = '031001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Sacaba'
)
BEGIN
    UPDATE m SET CodigoINE = '031001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Sacaba';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sacaba', '031001'
    FROM Provincia WHERE CodigoINE = '0310';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031002')
BEGIN
    UPDATE Municipio SET Nombre = N'Colomi' WHERE CodigoINE = '031002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Colomi'
)
BEGIN
    UPDATE m SET CodigoINE = '031002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Colomi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colomi', '031002'
    FROM Provincia WHERE CodigoINE = '0310';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031003')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Tunari' WHERE CodigoINE = '031003';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Villa Tunari'
)
BEGIN
    UPDATE m SET CodigoINE = '031003'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0310' AND m.Nombre = N'Villa Tunari';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Tunari', '031003'
    FROM Provincia WHERE CodigoINE = '0310';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031101')
BEGIN
    UPDATE Municipio SET Nombre = N'Tapacarí' WHERE CodigoINE = '031101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0311' AND m.Nombre = N'Tapacarí'
)
BEGIN
    UPDATE m SET CodigoINE = '031101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0311' AND m.Nombre = N'Tapacarí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tapacarí', '031101'
    FROM Provincia WHERE CodigoINE = '0311';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031201')
BEGIN
    UPDATE Municipio SET Nombre = N'Totora' WHERE CodigoINE = '031201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Totora'
)
BEGIN
    UPDATE m SET CodigoINE = '031201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Totora';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Totora', '031201'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031202')
BEGIN
    UPDATE Municipio SET Nombre = N'Pojo' WHERE CodigoINE = '031202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Pojo'
)
BEGIN
    UPDATE m SET CodigoINE = '031202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Pojo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pojo', '031202'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031203')
BEGIN
    UPDATE Municipio SET Nombre = N'Pocona' WHERE CodigoINE = '031203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Pocona'
)
BEGIN
    UPDATE m SET CodigoINE = '031203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Pocona';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pocona', '031203'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031204')
BEGIN
    UPDATE Municipio SET Nombre = N'Chimoré' WHERE CodigoINE = '031204';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Chimoré'
)
BEGIN
    UPDATE m SET CodigoINE = '031204'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Chimoré';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chimoré', '031204'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031205')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Villarroel' WHERE CodigoINE = '031205';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Puerto Villarroel'
)
BEGIN
    UPDATE m SET CodigoINE = '031205'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Puerto Villarroel';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Villarroel', '031205'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031206')
BEGIN
    UPDATE Municipio SET Nombre = N'Entre Ríos' WHERE CodigoINE = '031206';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Entre Ríos'
)
BEGIN
    UPDATE m SET CodigoINE = '031206'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0312' AND m.Nombre = N'Entre Ríos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Entre Ríos', '031206'
    FROM Provincia WHERE CodigoINE = '0312';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031301')
BEGIN
    UPDATE Municipio SET Nombre = N'Mizque' WHERE CodigoINE = '031301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Mizque'
)
BEGIN
    UPDATE m SET CodigoINE = '031301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Mizque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mizque', '031301'
    FROM Provincia WHERE CodigoINE = '0313';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031302')
BEGIN
    UPDATE Municipio SET Nombre = N'Vila Vila' WHERE CodigoINE = '031302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Vila Vila'
)
BEGIN
    UPDATE m SET CodigoINE = '031302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Vila Vila';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Vila Vila', '031302'
    FROM Provincia WHERE CodigoINE = '0313';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031303')
BEGIN
    UPDATE Municipio SET Nombre = N'Alalay' WHERE CodigoINE = '031303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Alalay'
)
BEGIN
    UPDATE m SET CodigoINE = '031303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0313' AND m.Nombre = N'Alalay';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Alalay', '031303'
    FROM Provincia WHERE CodigoINE = '0313';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031401')
BEGIN
    UPDATE Municipio SET Nombre = N'Punata' WHERE CodigoINE = '031401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Punata'
)
BEGIN
    UPDATE m SET CodigoINE = '031401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Punata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Punata', '031401'
    FROM Provincia WHERE CodigoINE = '0314';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031402')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Rivero' WHERE CodigoINE = '031402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Villa Rivero'
)
BEGIN
    UPDATE m SET CodigoINE = '031402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Villa Rivero';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Rivero', '031402'
    FROM Provincia WHERE CodigoINE = '0314';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031403')
BEGIN
    UPDATE Municipio SET Nombre = N'San Benito' WHERE CodigoINE = '031403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'San Benito'
)
BEGIN
    UPDATE m SET CodigoINE = '031403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'San Benito';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Benito', '031403'
    FROM Provincia WHERE CodigoINE = '0314';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031404')
BEGIN
    UPDATE Municipio SET Nombre = N'Tacachi' WHERE CodigoINE = '031404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Tacachi'
)
BEGIN
    UPDATE m SET CodigoINE = '031404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Tacachi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tacachi', '031404'
    FROM Provincia WHERE CodigoINE = '0314';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031405')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Gualberto Villarroel' WHERE CodigoINE = '031405';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Villa Gualberto Villarroel'
)
BEGIN
    UPDATE m SET CodigoINE = '031405'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0314' AND m.Nombre = N'Villa Gualberto Villarroel';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Gualberto Villarroel', '031405'
    FROM Provincia WHERE CodigoINE = '0314';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031501')
BEGIN
    UPDATE Municipio SET Nombre = N'Bolívar' WHERE CodigoINE = '031501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0315' AND m.Nombre = N'Bolívar'
)
BEGIN
    UPDATE m SET CodigoINE = '031501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0315' AND m.Nombre = N'Bolívar';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Bolívar', '031501'
    FROM Provincia WHERE CodigoINE = '0315';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031601')
BEGIN
    UPDATE Municipio SET Nombre = N'Tiraque' WHERE CodigoINE = '031601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0316' AND m.Nombre = N'Tiraque'
)
BEGIN
    UPDATE m SET CodigoINE = '031601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0316' AND m.Nombre = N'Tiraque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tiraque', '031601'
    FROM Provincia WHERE CodigoINE = '0316';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '031602')
BEGIN
    UPDATE Municipio SET Nombre = N'Shinahota' WHERE CodigoINE = '031602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0316' AND m.Nombre = N'Shinahota'
)
BEGIN
    UPDATE m SET CodigoINE = '031602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0316' AND m.Nombre = N'Shinahota';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Shinahota', '031602'
    FROM Provincia WHERE CodigoINE = '0316';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040101')
BEGIN
    UPDATE Municipio SET Nombre = N'Oruro' WHERE CodigoINE = '040101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Oruro'
)
BEGIN
    UPDATE m SET CodigoINE = '040101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Oruro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Oruro', '040101'
    FROM Provincia WHERE CodigoINE = '0401';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040102')
BEGIN
    UPDATE Municipio SET Nombre = N'Caracollo' WHERE CodigoINE = '040102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Caracollo'
)
BEGIN
    UPDATE m SET CodigoINE = '040102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Caracollo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caracollo', '040102'
    FROM Provincia WHERE CodigoINE = '0401';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040103')
BEGIN
    UPDATE Municipio SET Nombre = N'El Choro' WHERE CodigoINE = '040103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'El Choro'
)
BEGIN
    UPDATE m SET CodigoINE = '040103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'El Choro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Choro', '040103'
    FROM Provincia WHERE CodigoINE = '0401';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040104')
BEGIN
    UPDATE Municipio SET Nombre = N'Paria' WHERE CodigoINE = '040104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Paria'
)
BEGIN
    UPDATE m SET CodigoINE = '040104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0401' AND m.Nombre = N'Paria';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Paria', '040104'
    FROM Provincia WHERE CodigoINE = '0401';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040201')
BEGIN
    UPDATE Municipio SET Nombre = N'Challapata' WHERE CodigoINE = '040201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0402' AND m.Nombre = N'Challapata'
)
BEGIN
    UPDATE m SET CodigoINE = '040201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0402' AND m.Nombre = N'Challapata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Challapata', '040201'
    FROM Provincia WHERE CodigoINE = '0402';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040202')
BEGIN
    UPDATE Municipio SET Nombre = N'Santuario de Quillacas' WHERE CodigoINE = '040202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0402' AND m.Nombre = N'Santuario de Quillacas'
)
BEGIN
    UPDATE m SET CodigoINE = '040202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0402' AND m.Nombre = N'Santuario de Quillacas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santuario de Quillacas', '040202'
    FROM Provincia WHERE CodigoINE = '0402';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040301')
BEGIN
    UPDATE Municipio SET Nombre = N'Corque' WHERE CodigoINE = '040301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0403' AND m.Nombre = N'Corque'
)
BEGIN
    UPDATE m SET CodigoINE = '040301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0403' AND m.Nombre = N'Corque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Corque', '040301'
    FROM Provincia WHERE CodigoINE = '0403';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040302')
BEGIN
    UPDATE Municipio SET Nombre = N'Choquecota' WHERE CodigoINE = '040302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0403' AND m.Nombre = N'Choquecota'
)
BEGIN
    UPDATE m SET CodigoINE = '040302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0403' AND m.Nombre = N'Choquecota';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Choquecota', '040302'
    FROM Provincia WHERE CodigoINE = '0403';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040401')
BEGIN
    UPDATE Municipio SET Nombre = N'Curahuara de Carangas' WHERE CodigoINE = '040401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0404' AND m.Nombre = N'Curahuara de Carangas'
)
BEGIN
    UPDATE m SET CodigoINE = '040401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0404' AND m.Nombre = N'Curahuara de Carangas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Curahuara de Carangas', '040401'
    FROM Provincia WHERE CodigoINE = '0404';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040402')
BEGIN
    UPDATE Municipio SET Nombre = N'Turco' WHERE CodigoINE = '040402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0404' AND m.Nombre = N'Turco'
)
BEGIN
    UPDATE m SET CodigoINE = '040402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0404' AND m.Nombre = N'Turco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Turco', '040402'
    FROM Provincia WHERE CodigoINE = '0404';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040501')
BEGIN
    UPDATE Municipio SET Nombre = N'Huachacalla' WHERE CodigoINE = '040501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Huachacalla'
)
BEGIN
    UPDATE m SET CodigoINE = '040501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Huachacalla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huachacalla', '040501'
    FROM Provincia WHERE CodigoINE = '0405';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040502')
BEGIN
    UPDATE Municipio SET Nombre = N'Escara' WHERE CodigoINE = '040502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Escara'
)
BEGIN
    UPDATE m SET CodigoINE = '040502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Escara';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Escara', '040502'
    FROM Provincia WHERE CodigoINE = '0405';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040503')
BEGIN
    UPDATE Municipio SET Nombre = N'Cruz de Machacamarca' WHERE CodigoINE = '040503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Cruz de Machacamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '040503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Cruz de Machacamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cruz de Machacamarca', '040503'
    FROM Provincia WHERE CodigoINE = '0405';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040504')
BEGIN
    UPDATE Municipio SET Nombre = N'Yunguyo del Litoral' WHERE CodigoINE = '040504';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Yunguyo del Litoral'
)
BEGIN
    UPDATE m SET CodigoINE = '040504'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Yunguyo del Litoral';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yunguyo del Litoral', '040504'
    FROM Provincia WHERE CodigoINE = '0405';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040505')
BEGIN
    UPDATE Municipio SET Nombre = N'Esmeralda' WHERE CodigoINE = '040505';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Esmeralda'
)
BEGIN
    UPDATE m SET CodigoINE = '040505'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0405' AND m.Nombre = N'Esmeralda';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Esmeralda', '040505'
    FROM Provincia WHERE CodigoINE = '0405';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040601')
BEGIN
    UPDATE Municipio SET Nombre = N'Poopó' WHERE CodigoINE = '040601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Poopó'
)
BEGIN
    UPDATE m SET CodigoINE = '040601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Poopó';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Poopó', '040601'
    FROM Provincia WHERE CodigoINE = '0406';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040602')
BEGIN
    UPDATE Municipio SET Nombre = N'Pazña' WHERE CodigoINE = '040602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Pazña'
)
BEGIN
    UPDATE m SET CodigoINE = '040602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Pazña';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pazña', '040602'
    FROM Provincia WHERE CodigoINE = '0406';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040603')
BEGIN
    UPDATE Municipio SET Nombre = N'Antequera' WHERE CodigoINE = '040603';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Antequera'
)
BEGIN
    UPDATE m SET CodigoINE = '040603'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0406' AND m.Nombre = N'Antequera';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Antequera', '040603'
    FROM Provincia WHERE CodigoINE = '0406';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040701')
BEGIN
    UPDATE Municipio SET Nombre = N'Huanuni' WHERE CodigoINE = '040701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0407' AND m.Nombre = N'Huanuni'
)
BEGIN
    UPDATE m SET CodigoINE = '040701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0407' AND m.Nombre = N'Huanuni';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huanuni', '040701'
    FROM Provincia WHERE CodigoINE = '0407';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040702')
BEGIN
    UPDATE Municipio SET Nombre = N'Machacamarca' WHERE CodigoINE = '040702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0407' AND m.Nombre = N'Machacamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '040702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0407' AND m.Nombre = N'Machacamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Machacamarca', '040702'
    FROM Provincia WHERE CodigoINE = '0407';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040801')
BEGIN
    UPDATE Municipio SET Nombre = N'Salinas de Garci Mendoza (Autonomía Indígena Originario Campesina de Salinas)' WHERE CodigoINE = '040801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0408' AND m.Nombre = N'Salinas de Garci Mendoza (Autonomía Indígena Originario Campesina de Salinas)'
)
BEGIN
    UPDATE m SET CodigoINE = '040801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0408' AND m.Nombre = N'Salinas de Garci Mendoza (Autonomía Indígena Originario Campesina de Salinas)';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Salinas de Garci Mendoza (Autonomía Indígena Originario Campesina de Salinas)', '040801'
    FROM Provincia WHERE CodigoINE = '0408';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040802')
BEGIN
    UPDATE Municipio SET Nombre = N'Pampa Aullagas' WHERE CodigoINE = '040802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0408' AND m.Nombre = N'Pampa Aullagas'
)
BEGIN
    UPDATE m SET CodigoINE = '040802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0408' AND m.Nombre = N'Pampa Aullagas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pampa Aullagas', '040802'
    FROM Provincia WHERE CodigoINE = '0408';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040901')
BEGIN
    UPDATE Municipio SET Nombre = N'Sabaya' WHERE CodigoINE = '040901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Sabaya'
)
BEGIN
    UPDATE m SET CodigoINE = '040901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Sabaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sabaya', '040901'
    FROM Provincia WHERE CodigoINE = '0409';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040902')
BEGIN
    UPDATE Municipio SET Nombre = N'Coipasa' WHERE CodigoINE = '040902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Coipasa'
)
BEGIN
    UPDATE m SET CodigoINE = '040902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Coipasa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Coipasa', '040902'
    FROM Provincia WHERE CodigoINE = '0409';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '040903')
BEGIN
    UPDATE Municipio SET Nombre = N'Uru Chipaya (Nación Originaria Uru Chipaya)' WHERE CodigoINE = '040903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Uru Chipaya (Nación Originaria Uru Chipaya)'
)
BEGIN
    UPDATE m SET CodigoINE = '040903'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0409' AND m.Nombre = N'Uru Chipaya (Nación Originaria Uru Chipaya)';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Uru Chipaya (Nación Originaria Uru Chipaya)', '040903'
    FROM Provincia WHERE CodigoINE = '0409';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041001')
BEGIN
    UPDATE Municipio SET Nombre = N'Toledo' WHERE CodigoINE = '041001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0410' AND m.Nombre = N'Toledo'
)
BEGIN
    UPDATE m SET CodigoINE = '041001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0410' AND m.Nombre = N'Toledo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Toledo', '041001'
    FROM Provincia WHERE CodigoINE = '0410';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041101')
BEGIN
    UPDATE Municipio SET Nombre = N'Eucaliptus' WHERE CodigoINE = '041101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0411' AND m.Nombre = N'Eucaliptus'
)
BEGIN
    UPDATE m SET CodigoINE = '041101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0411' AND m.Nombre = N'Eucaliptus';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Eucaliptus', '041101'
    FROM Provincia WHERE CodigoINE = '0411';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041201')
BEGIN
    UPDATE Municipio SET Nombre = N'Andamarca' WHERE CodigoINE = '041201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0412' AND m.Nombre = N'Andamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '041201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0412' AND m.Nombre = N'Andamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Andamarca', '041201'
    FROM Provincia WHERE CodigoINE = '0412';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041202')
BEGIN
    UPDATE Municipio SET Nombre = N'Belén de Andamarca' WHERE CodigoINE = '041202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0412' AND m.Nombre = N'Belén de Andamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '041202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0412' AND m.Nombre = N'Belén de Andamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Belén de Andamarca', '041202'
    FROM Provincia WHERE CodigoINE = '0412';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041301')
BEGIN
    UPDATE Municipio SET Nombre = N'Totora' WHERE CodigoINE = '041301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0413' AND m.Nombre = N'Totora'
)
BEGIN
    UPDATE m SET CodigoINE = '041301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0413' AND m.Nombre = N'Totora';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Totora', '041301'
    FROM Provincia WHERE CodigoINE = '0413';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041401')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiago de Huari' WHERE CodigoINE = '041401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0414' AND m.Nombre = N'Santiago de Huari'
)
BEGIN
    UPDATE m SET CodigoINE = '041401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0414' AND m.Nombre = N'Santiago de Huari';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiago de Huari', '041401'
    FROM Provincia WHERE CodigoINE = '0414';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041501')
BEGIN
    UPDATE Municipio SET Nombre = N'La Rivera' WHERE CodigoINE = '041501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'La Rivera'
)
BEGIN
    UPDATE m SET CodigoINE = '041501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'La Rivera';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'La Rivera', '041501'
    FROM Provincia WHERE CodigoINE = '0415';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041502')
BEGIN
    UPDATE Municipio SET Nombre = N'Todos Santos' WHERE CodigoINE = '041502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'Todos Santos'
)
BEGIN
    UPDATE m SET CodigoINE = '041502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'Todos Santos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Todos Santos', '041502'
    FROM Provincia WHERE CodigoINE = '0415';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041503')
BEGIN
    UPDATE Municipio SET Nombre = N'Carangas' WHERE CodigoINE = '041503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'Carangas'
)
BEGIN
    UPDATE m SET CodigoINE = '041503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0415' AND m.Nombre = N'Carangas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Carangas', '041503'
    FROM Provincia WHERE CodigoINE = '0415';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '041601')
BEGIN
    UPDATE Municipio SET Nombre = N'Santiago de Huayllamarca' WHERE CodigoINE = '041601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0416' AND m.Nombre = N'Santiago de Huayllamarca'
)
BEGIN
    UPDATE m SET CodigoINE = '041601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0416' AND m.Nombre = N'Santiago de Huayllamarca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santiago de Huayllamarca', '041601'
    FROM Provincia WHERE CodigoINE = '0416';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050101')
BEGIN
    UPDATE Municipio SET Nombre = N'Potosí' WHERE CodigoINE = '050101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Potosí'
)
BEGIN
    UPDATE m SET CodigoINE = '050101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Potosí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Potosí', '050101'
    FROM Provincia WHERE CodigoINE = '0501';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050102')
BEGIN
    UPDATE Municipio SET Nombre = N'Tinguipaya' WHERE CodigoINE = '050102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Tinguipaya'
)
BEGIN
    UPDATE m SET CodigoINE = '050102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Tinguipaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tinguipaya', '050102'
    FROM Provincia WHERE CodigoINE = '0501';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050103')
BEGIN
    UPDATE Municipio SET Nombre = N'Yocalla' WHERE CodigoINE = '050103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Yocalla'
)
BEGIN
    UPDATE m SET CodigoINE = '050103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Yocalla';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yocalla', '050103'
    FROM Provincia WHERE CodigoINE = '0501';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050104')
BEGIN
    UPDATE Municipio SET Nombre = N'Urmiri' WHERE CodigoINE = '050104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Urmiri'
)
BEGIN
    UPDATE m SET CodigoINE = '050104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0501' AND m.Nombre = N'Urmiri';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Urmiri', '050104'
    FROM Provincia WHERE CodigoINE = '0501';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050201')
BEGIN
    UPDATE Municipio SET Nombre = N'Uncía' WHERE CodigoINE = '050201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Uncía'
)
BEGIN
    UPDATE m SET CodigoINE = '050201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Uncía';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Uncía', '050201'
    FROM Provincia WHERE CodigoINE = '0502';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050202')
BEGIN
    UPDATE Municipio SET Nombre = N'Chayanta' WHERE CodigoINE = '050202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Chayanta'
)
BEGIN
    UPDATE m SET CodigoINE = '050202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Chayanta';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chayanta', '050202'
    FROM Provincia WHERE CodigoINE = '0502';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050203')
BEGIN
    UPDATE Municipio SET Nombre = N'Llallagua' WHERE CodigoINE = '050203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Llallagua'
)
BEGIN
    UPDATE m SET CodigoINE = '050203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Llallagua';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Llallagua', '050203'
    FROM Provincia WHERE CodigoINE = '0502';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050204')
BEGIN
    UPDATE Municipio SET Nombre = N'Chuquihuta Ayllu Jucumani' WHERE CodigoINE = '050204';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Chuquihuta Ayllu Jucumani'
)
BEGIN
    UPDATE m SET CodigoINE = '050204'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0502' AND m.Nombre = N'Chuquihuta Ayllu Jucumani';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chuquihuta Ayllu Jucumani', '050204'
    FROM Provincia WHERE CodigoINE = '0502';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050301')
BEGIN
    UPDATE Municipio SET Nombre = N'Betanzos' WHERE CodigoINE = '050301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Betanzos'
)
BEGIN
    UPDATE m SET CodigoINE = '050301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Betanzos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Betanzos', '050301'
    FROM Provincia WHERE CodigoINE = '0503';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050302')
BEGIN
    UPDATE Municipio SET Nombre = N'Chaquí' WHERE CodigoINE = '050302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Chaquí'
)
BEGIN
    UPDATE m SET CodigoINE = '050302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Chaquí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Chaquí', '050302'
    FROM Provincia WHERE CodigoINE = '0503';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050303')
BEGIN
    UPDATE Municipio SET Nombre = N'Tacobamba' WHERE CodigoINE = '050303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Tacobamba'
)
BEGIN
    UPDATE m SET CodigoINE = '050303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0503' AND m.Nombre = N'Tacobamba';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tacobamba', '050303'
    FROM Provincia WHERE CodigoINE = '0503';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050401')
BEGIN
    UPDATE Municipio SET Nombre = N'Colquechaca' WHERE CodigoINE = '050401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Colquechaca'
)
BEGIN
    UPDATE m SET CodigoINE = '050401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Colquechaca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colquechaca', '050401'
    FROM Provincia WHERE CodigoINE = '0504';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050402')
BEGIN
    UPDATE Municipio SET Nombre = N'Ravelo' WHERE CodigoINE = '050402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Ravelo'
)
BEGIN
    UPDATE m SET CodigoINE = '050402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Ravelo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ravelo', '050402'
    FROM Provincia WHERE CodigoINE = '0504';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050403')
BEGIN
    UPDATE Municipio SET Nombre = N'Pocoata' WHERE CodigoINE = '050403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Pocoata'
)
BEGIN
    UPDATE m SET CodigoINE = '050403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Pocoata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pocoata', '050403'
    FROM Provincia WHERE CodigoINE = '0504';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050404')
BEGIN
    UPDATE Municipio SET Nombre = N'Ocurí' WHERE CodigoINE = '050404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Ocurí'
)
BEGIN
    UPDATE m SET CodigoINE = '050404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'Ocurí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ocurí', '050404'
    FROM Provincia WHERE CodigoINE = '0504';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050405')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro de Macha' WHERE CodigoINE = '050405';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'San Pedro de Macha'
)
BEGIN
    UPDATE m SET CodigoINE = '050405'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0504' AND m.Nombre = N'San Pedro de Macha';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro de Macha', '050405'
    FROM Provincia WHERE CodigoINE = '0504';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050501')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro' WHERE CodigoINE = '050501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0505' AND m.Nombre = N'San Pedro'
)
BEGIN
    UPDATE m SET CodigoINE = '050501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0505' AND m.Nombre = N'San Pedro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro', '050501'
    FROM Provincia WHERE CodigoINE = '0505';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050502')
BEGIN
    UPDATE Municipio SET Nombre = N'Toro Toro' WHERE CodigoINE = '050502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0505' AND m.Nombre = N'Toro Toro'
)
BEGIN
    UPDATE m SET CodigoINE = '050502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0505' AND m.Nombre = N'Toro Toro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Toro Toro', '050502'
    FROM Provincia WHERE CodigoINE = '0505';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050601')
BEGIN
    UPDATE Municipio SET Nombre = N'Cotagaita' WHERE CodigoINE = '050601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0506' AND m.Nombre = N'Cotagaita'
)
BEGIN
    UPDATE m SET CodigoINE = '050601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0506' AND m.Nombre = N'Cotagaita';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cotagaita', '050601'
    FROM Provincia WHERE CodigoINE = '0506';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050602')
BEGIN
    UPDATE Municipio SET Nombre = N'Vitichi' WHERE CodigoINE = '050602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0506' AND m.Nombre = N'Vitichi'
)
BEGIN
    UPDATE m SET CodigoINE = '050602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0506' AND m.Nombre = N'Vitichi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Vitichi', '050602'
    FROM Provincia WHERE CodigoINE = '0506';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050701')
BEGIN
    UPDATE Municipio SET Nombre = N'Sacaca' WHERE CodigoINE = '050701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0507' AND m.Nombre = N'Sacaca'
)
BEGIN
    UPDATE m SET CodigoINE = '050701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0507' AND m.Nombre = N'Sacaca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sacaca', '050701'
    FROM Provincia WHERE CodigoINE = '0507';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050702')
BEGIN
    UPDATE Municipio SET Nombre = N'Caripuyo' WHERE CodigoINE = '050702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0507' AND m.Nombre = N'Caripuyo'
)
BEGIN
    UPDATE m SET CodigoINE = '050702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0507' AND m.Nombre = N'Caripuyo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caripuyo', '050702'
    FROM Provincia WHERE CodigoINE = '0507';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050801')
BEGIN
    UPDATE Municipio SET Nombre = N'Tupiza' WHERE CodigoINE = '050801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0508' AND m.Nombre = N'Tupiza'
)
BEGIN
    UPDATE m SET CodigoINE = '050801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0508' AND m.Nombre = N'Tupiza';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tupiza', '050801'
    FROM Provincia WHERE CodigoINE = '0508';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050802')
BEGIN
    UPDATE Municipio SET Nombre = N'Atocha' WHERE CodigoINE = '050802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0508' AND m.Nombre = N'Atocha'
)
BEGIN
    UPDATE m SET CodigoINE = '050802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0508' AND m.Nombre = N'Atocha';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Atocha', '050802'
    FROM Provincia WHERE CodigoINE = '0508';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050901')
BEGIN
    UPDATE Municipio SET Nombre = N'Colcha "K"' WHERE CodigoINE = '050901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0509' AND m.Nombre = N'Colcha "K"'
)
BEGIN
    UPDATE m SET CodigoINE = '050901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0509' AND m.Nombre = N'Colcha "K"';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colcha "K"', '050901'
    FROM Provincia WHERE CodigoINE = '0509';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '050902')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro de Quemes' WHERE CodigoINE = '050902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0509' AND m.Nombre = N'San Pedro de Quemes'
)
BEGIN
    UPDATE m SET CodigoINE = '050902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0509' AND m.Nombre = N'San Pedro de Quemes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro de Quemes', '050902'
    FROM Provincia WHERE CodigoINE = '0509';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051001')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pablo' WHERE CodigoINE = '051001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'San Pablo'
)
BEGIN
    UPDATE m SET CodigoINE = '051001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'San Pablo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pablo', '051001'
    FROM Provincia WHERE CodigoINE = '0510';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051002')
BEGIN
    UPDATE Municipio SET Nombre = N'Mojinete' WHERE CodigoINE = '051002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'Mojinete'
)
BEGIN
    UPDATE m SET CodigoINE = '051002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'Mojinete';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mojinete', '051002'
    FROM Provincia WHERE CodigoINE = '0510';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051003')
BEGIN
    UPDATE Municipio SET Nombre = N'San Antonio de Esmoruco' WHERE CodigoINE = '051003';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'San Antonio de Esmoruco'
)
BEGIN
    UPDATE m SET CodigoINE = '051003'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0510' AND m.Nombre = N'San Antonio de Esmoruco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Antonio de Esmoruco', '051003'
    FROM Provincia WHERE CodigoINE = '0510';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051101')
BEGIN
    UPDATE Municipio SET Nombre = N'Puna' WHERE CodigoINE = '051101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Puna'
)
BEGIN
    UPDATE m SET CodigoINE = '051101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Puna';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puna', '051101'
    FROM Provincia WHERE CodigoINE = '0511';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051102')
BEGIN
    UPDATE Municipio SET Nombre = N'Caiza "D"' WHERE CodigoINE = '051102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Caiza "D"'
)
BEGIN
    UPDATE m SET CodigoINE = '051102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Caiza "D"';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caiza "D"', '051102'
    FROM Provincia WHERE CodigoINE = '0511';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051103')
BEGIN
    UPDATE Municipio SET Nombre = N'Ckochas' WHERE CodigoINE = '051103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Ckochas'
)
BEGIN
    UPDATE m SET CodigoINE = '051103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0511' AND m.Nombre = N'Ckochas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ckochas', '051103'
    FROM Provincia WHERE CodigoINE = '0511';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051201')
BEGIN
    UPDATE Municipio SET Nombre = N'Uyuni' WHERE CodigoINE = '051201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Uyuni'
)
BEGIN
    UPDATE m SET CodigoINE = '051201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Uyuni';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Uyuni', '051201'
    FROM Provincia WHERE CodigoINE = '0512';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051202')
BEGIN
    UPDATE Municipio SET Nombre = N'Tomave' WHERE CodigoINE = '051202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Tomave'
)
BEGIN
    UPDATE m SET CodigoINE = '051202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Tomave';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tomave', '051202'
    FROM Provincia WHERE CodigoINE = '0512';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051203')
BEGIN
    UPDATE Municipio SET Nombre = N'Porco' WHERE CodigoINE = '051203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Porco'
)
BEGIN
    UPDATE m SET CodigoINE = '051203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0512' AND m.Nombre = N'Porco';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Porco', '051203'
    FROM Provincia WHERE CodigoINE = '0512';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051301')
BEGIN
    UPDATE Municipio SET Nombre = N'Arampampa' WHERE CodigoINE = '051301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0513' AND m.Nombre = N'Arampampa'
)
BEGIN
    UPDATE m SET CodigoINE = '051301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0513' AND m.Nombre = N'Arampampa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Arampampa', '051301'
    FROM Provincia WHERE CodigoINE = '0513';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051302')
BEGIN
    UPDATE Municipio SET Nombre = N'Acasio' WHERE CodigoINE = '051302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0513' AND m.Nombre = N'Acasio'
)
BEGIN
    UPDATE m SET CodigoINE = '051302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0513' AND m.Nombre = N'Acasio';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Acasio', '051302'
    FROM Provincia WHERE CodigoINE = '0513';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051401')
BEGIN
    UPDATE Municipio SET Nombre = N'Llica' WHERE CodigoINE = '051401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0514' AND m.Nombre = N'Llica'
)
BEGIN
    UPDATE m SET CodigoINE = '051401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0514' AND m.Nombre = N'Llica';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Llica', '051401'
    FROM Provincia WHERE CodigoINE = '0514';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051402')
BEGIN
    UPDATE Municipio SET Nombre = N'Tahua' WHERE CodigoINE = '051402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0514' AND m.Nombre = N'Tahua'
)
BEGIN
    UPDATE m SET CodigoINE = '051402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0514' AND m.Nombre = N'Tahua';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tahua', '051402'
    FROM Provincia WHERE CodigoINE = '0514';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051501')
BEGIN
    UPDATE Municipio SET Nombre = N'Villazón' WHERE CodigoINE = '051501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0515' AND m.Nombre = N'Villazón'
)
BEGIN
    UPDATE m SET CodigoINE = '051501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0515' AND m.Nombre = N'Villazón';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villazón', '051501'
    FROM Provincia WHERE CodigoINE = '0515';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '051601')
BEGIN
    UPDATE Municipio SET Nombre = N'San Agustín' WHERE CodigoINE = '051601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0516' AND m.Nombre = N'San Agustín'
)
BEGIN
    UPDATE m SET CodigoINE = '051601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0516' AND m.Nombre = N'San Agustín';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Agustín', '051601'
    FROM Provincia WHERE CodigoINE = '0516';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060101')
BEGIN
    UPDATE Municipio SET Nombre = N'Tarija' WHERE CodigoINE = '060101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0601' AND m.Nombre = N'Tarija'
)
BEGIN
    UPDATE m SET CodigoINE = '060101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0601' AND m.Nombre = N'Tarija';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Tarija', '060101'
    FROM Provincia WHERE CodigoINE = '0601';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060201')
BEGIN
    UPDATE Municipio SET Nombre = N'Padcaya' WHERE CodigoINE = '060201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0602' AND m.Nombre = N'Padcaya'
)
BEGIN
    UPDATE m SET CodigoINE = '060201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0602' AND m.Nombre = N'Padcaya';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Padcaya', '060201'
    FROM Provincia WHERE CodigoINE = '0602';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060202')
BEGIN
    UPDATE Municipio SET Nombre = N'Bermejo' WHERE CodigoINE = '060202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0602' AND m.Nombre = N'Bermejo'
)
BEGIN
    UPDATE m SET CodigoINE = '060202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0602' AND m.Nombre = N'Bermejo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Bermejo', '060202'
    FROM Provincia WHERE CodigoINE = '0602';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060301')
BEGIN
    UPDATE Municipio SET Nombre = N'Yacuiba' WHERE CodigoINE = '060301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Yacuiba'
)
BEGIN
    UPDATE m SET CodigoINE = '060301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Yacuiba';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yacuiba', '060301'
    FROM Provincia WHERE CodigoINE = '0603';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060302')
BEGIN
    UPDATE Municipio SET Nombre = N'Caraparí' WHERE CodigoINE = '060302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Caraparí'
)
BEGIN
    UPDATE m SET CodigoINE = '060302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Caraparí';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Caraparí', '060302'
    FROM Provincia WHERE CodigoINE = '0603';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060303')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Montes' WHERE CodigoINE = '060303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Villa Montes'
)
BEGIN
    UPDATE m SET CodigoINE = '060303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0603' AND m.Nombre = N'Villa Montes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Montes', '060303'
    FROM Provincia WHERE CodigoINE = '0603';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060401')
BEGIN
    UPDATE Municipio SET Nombre = N'Uriondo' WHERE CodigoINE = '060401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0604' AND m.Nombre = N'Uriondo'
)
BEGIN
    UPDATE m SET CodigoINE = '060401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0604' AND m.Nombre = N'Uriondo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Uriondo', '060401'
    FROM Provincia WHERE CodigoINE = '0604';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060402')
BEGIN
    UPDATE Municipio SET Nombre = N'Yunchará' WHERE CodigoINE = '060402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0604' AND m.Nombre = N'Yunchará'
)
BEGIN
    UPDATE m SET CodigoINE = '060402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0604' AND m.Nombre = N'Yunchará';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yunchará', '060402'
    FROM Provincia WHERE CodigoINE = '0604';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060501')
BEGIN
    UPDATE Municipio SET Nombre = N'San Lorenzo' WHERE CodigoINE = '060501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0605' AND m.Nombre = N'San Lorenzo'
)
BEGIN
    UPDATE m SET CodigoINE = '060501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0605' AND m.Nombre = N'San Lorenzo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Lorenzo', '060501'
    FROM Provincia WHERE CodigoINE = '0605';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060502')
BEGIN
    UPDATE Municipio SET Nombre = N'El Puente' WHERE CodigoINE = '060502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0605' AND m.Nombre = N'El Puente'
)
BEGIN
    UPDATE m SET CodigoINE = '060502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0605' AND m.Nombre = N'El Puente';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Puente', '060502'
    FROM Provincia WHERE CodigoINE = '0605';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '060601')
BEGIN
    UPDATE Municipio SET Nombre = N'Entre Ríos' WHERE CodigoINE = '060601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0606' AND m.Nombre = N'Entre Ríos'
)
BEGIN
    UPDATE m SET CodigoINE = '060601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0606' AND m.Nombre = N'Entre Ríos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Entre Ríos', '060601'
    FROM Provincia WHERE CodigoINE = '0606';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070101')
BEGIN
    UPDATE Municipio SET Nombre = N'Santa Cruz de la Sierra' WHERE CodigoINE = '070101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Santa Cruz de la Sierra'
)
BEGIN
    UPDATE m SET CodigoINE = '070101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Santa Cruz de la Sierra';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santa Cruz de la Sierra', '070101'
    FROM Provincia WHERE CodigoINE = '0701';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070102')
BEGIN
    UPDATE Municipio SET Nombre = N'Cotoca' WHERE CodigoINE = '070102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Cotoca'
)
BEGIN
    UPDATE m SET CodigoINE = '070102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Cotoca';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cotoca', '070102'
    FROM Provincia WHERE CodigoINE = '0701';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070103')
BEGIN
    UPDATE Municipio SET Nombre = N'Porongo' WHERE CodigoINE = '070103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Porongo'
)
BEGIN
    UPDATE m SET CodigoINE = '070103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'Porongo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Porongo', '070103'
    FROM Provincia WHERE CodigoINE = '0701';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070104')
BEGIN
    UPDATE Municipio SET Nombre = N'La Guardia' WHERE CodigoINE = '070104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'La Guardia'
)
BEGIN
    UPDATE m SET CodigoINE = '070104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'La Guardia';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'La Guardia', '070104'
    FROM Provincia WHERE CodigoINE = '0701';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070105')
BEGIN
    UPDATE Municipio SET Nombre = N'El Torno' WHERE CodigoINE = '070105';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'El Torno'
)
BEGIN
    UPDATE m SET CodigoINE = '070105'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0701' AND m.Nombre = N'El Torno';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Torno', '070105'
    FROM Provincia WHERE CodigoINE = '0701';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070201')
BEGIN
    UPDATE Municipio SET Nombre = N'Warnes' WHERE CodigoINE = '070201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0702' AND m.Nombre = N'Warnes'
)
BEGIN
    UPDATE m SET CodigoINE = '070201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0702' AND m.Nombre = N'Warnes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Warnes', '070201'
    FROM Provincia WHERE CodigoINE = '0702';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070202')
BEGIN
    UPDATE Municipio SET Nombre = N'Okinawa Uno' WHERE CodigoINE = '070202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0702' AND m.Nombre = N'Okinawa Uno'
)
BEGIN
    UPDATE m SET CodigoINE = '070202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0702' AND m.Nombre = N'Okinawa Uno';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Okinawa Uno', '070202'
    FROM Provincia WHERE CodigoINE = '0702';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070301')
BEGIN
    UPDATE Municipio SET Nombre = N'San Ignacio' WHERE CodigoINE = '070301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Ignacio'
)
BEGIN
    UPDATE m SET CodigoINE = '070301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Ignacio';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Ignacio', '070301'
    FROM Provincia WHERE CodigoINE = '0703';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070302')
BEGIN
    UPDATE Municipio SET Nombre = N'San Miguel' WHERE CodigoINE = '070302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Miguel'
)
BEGIN
    UPDATE m SET CodigoINE = '070302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Miguel';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Miguel', '070302'
    FROM Provincia WHERE CodigoINE = '0703';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070303')
BEGIN
    UPDATE Municipio SET Nombre = N'San Rafael' WHERE CodigoINE = '070303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Rafael'
)
BEGIN
    UPDATE m SET CodigoINE = '070303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0703' AND m.Nombre = N'San Rafael';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Rafael', '070303'
    FROM Provincia WHERE CodigoINE = '0703';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070401')
BEGIN
    UPDATE Municipio SET Nombre = N'Buena Vista' WHERE CodigoINE = '070401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'Buena Vista'
)
BEGIN
    UPDATE m SET CodigoINE = '070401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'Buena Vista';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Buena Vista', '070401'
    FROM Provincia WHERE CodigoINE = '0704';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070402')
BEGIN
    UPDATE Municipio SET Nombre = N'San Carlos' WHERE CodigoINE = '070402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'San Carlos'
)
BEGIN
    UPDATE m SET CodigoINE = '070402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'San Carlos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Carlos', '070402'
    FROM Provincia WHERE CodigoINE = '0704';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070403')
BEGIN
    UPDATE Municipio SET Nombre = N'Yapacaní' WHERE CodigoINE = '070403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'Yapacaní'
)
BEGIN
    UPDATE m SET CodigoINE = '070403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'Yapacaní';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Yapacaní', '070403'
    FROM Provincia WHERE CodigoINE = '0704';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070404')
BEGIN
    UPDATE Municipio SET Nombre = N'San Juan' WHERE CodigoINE = '070404';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'San Juan'
)
BEGIN
    UPDATE m SET CodigoINE = '070404'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0704' AND m.Nombre = N'San Juan';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Juan', '070404'
    FROM Provincia WHERE CodigoINE = '0704';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070501')
BEGIN
    UPDATE Municipio SET Nombre = N'San José' WHERE CodigoINE = '070501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'San José'
)
BEGIN
    UPDATE m SET CodigoINE = '070501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'San José';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San José', '070501'
    FROM Provincia WHERE CodigoINE = '0705';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070502')
BEGIN
    UPDATE Municipio SET Nombre = N'Pailón' WHERE CodigoINE = '070502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'Pailón'
)
BEGIN
    UPDATE m SET CodigoINE = '070502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'Pailón';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pailón', '070502'
    FROM Provincia WHERE CodigoINE = '0705';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070503')
BEGIN
    UPDATE Municipio SET Nombre = N'Roboré' WHERE CodigoINE = '070503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'Roboré'
)
BEGIN
    UPDATE m SET CodigoINE = '070503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0705' AND m.Nombre = N'Roboré';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Roboré', '070503'
    FROM Provincia WHERE CodigoINE = '0705';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070601')
BEGIN
    UPDATE Municipio SET Nombre = N'Portachuelo' WHERE CodigoINE = '070601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Portachuelo'
)
BEGIN
    UPDATE m SET CodigoINE = '070601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Portachuelo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Portachuelo', '070601'
    FROM Provincia WHERE CodigoINE = '0706';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070602')
BEGIN
    UPDATE Municipio SET Nombre = N'Santa Rosa' WHERE CodigoINE = '070602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Santa Rosa'
)
BEGIN
    UPDATE m SET CodigoINE = '070602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Santa Rosa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santa Rosa', '070602'
    FROM Provincia WHERE CodigoINE = '0706';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070603')
BEGIN
    UPDATE Municipio SET Nombre = N'Colpa Bélgica' WHERE CodigoINE = '070603';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Colpa Bélgica'
)
BEGIN
    UPDATE m SET CodigoINE = '070603'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0706' AND m.Nombre = N'Colpa Bélgica';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Colpa Bélgica', '070603'
    FROM Provincia WHERE CodigoINE = '0706';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070701')
BEGIN
    UPDATE Municipio SET Nombre = N'Lagunillas' WHERE CodigoINE = '070701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Lagunillas'
)
BEGIN
    UPDATE m SET CodigoINE = '070701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Lagunillas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Lagunillas', '070701'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070702')
BEGIN
    UPDATE Municipio SET Nombre = N'Charagua (Autonomía Guaraní Charagua Iyambae)' WHERE CodigoINE = '070702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Charagua (Autonomía Guaraní Charagua Iyambae)'
)
BEGIN
    UPDATE m SET CodigoINE = '070702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Charagua (Autonomía Guaraní Charagua Iyambae)';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Charagua (Autonomía Guaraní Charagua Iyambae)', '070702'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070703')
BEGIN
    UPDATE Municipio SET Nombre = N'Cabezas' WHERE CodigoINE = '070703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Cabezas'
)
BEGIN
    UPDATE m SET CodigoINE = '070703'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Cabezas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cabezas', '070703'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070704')
BEGIN
    UPDATE Municipio SET Nombre = N'Cuevo' WHERE CodigoINE = '070704';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Cuevo'
)
BEGIN
    UPDATE m SET CodigoINE = '070704'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Cuevo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cuevo', '070704'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070705')
BEGIN
    UPDATE Municipio SET Nombre = N'Gutiérrez (Autonomía Indígena Kereimba Iyaambae)' WHERE CodigoINE = '070705';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Gutiérrez (Autonomía Indígena Kereimba Iyaambae)'
)
BEGIN
    UPDATE m SET CodigoINE = '070705'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Gutiérrez (Autonomía Indígena Kereimba Iyaambae)';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Gutiérrez (Autonomía Indígena Kereimba Iyaambae)', '070705'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070706')
BEGIN
    UPDATE Municipio SET Nombre = N'Camiri' WHERE CodigoINE = '070706';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Camiri'
)
BEGIN
    UPDATE m SET CodigoINE = '070706'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Camiri';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Camiri', '070706'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070707')
BEGIN
    UPDATE Municipio SET Nombre = N'Boyuibe' WHERE CodigoINE = '070707';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Boyuibe'
)
BEGIN
    UPDATE m SET CodigoINE = '070707'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0707' AND m.Nombre = N'Boyuibe';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Boyuibe', '070707'
    FROM Provincia WHERE CodigoINE = '0707';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070801')
BEGIN
    UPDATE Municipio SET Nombre = N'Vallegrande' WHERE CodigoINE = '070801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Vallegrande'
)
BEGIN
    UPDATE m SET CodigoINE = '070801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Vallegrande';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Vallegrande', '070801'
    FROM Provincia WHERE CodigoINE = '0708';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070802')
BEGIN
    UPDATE Municipio SET Nombre = N'Trigal' WHERE CodigoINE = '070802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Trigal'
)
BEGIN
    UPDATE m SET CodigoINE = '070802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Trigal';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Trigal', '070802'
    FROM Provincia WHERE CodigoINE = '0708';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070803')
BEGIN
    UPDATE Municipio SET Nombre = N'Moromoro' WHERE CodigoINE = '070803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Moromoro'
)
BEGIN
    UPDATE m SET CodigoINE = '070803'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Moromoro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Moromoro', '070803'
    FROM Provincia WHERE CodigoINE = '0708';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070804')
BEGIN
    UPDATE Municipio SET Nombre = N'Postrervalle' WHERE CodigoINE = '070804';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Postrervalle'
)
BEGIN
    UPDATE m SET CodigoINE = '070804'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Postrervalle';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Postrervalle', '070804'
    FROM Provincia WHERE CodigoINE = '0708';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070805')
BEGIN
    UPDATE Municipio SET Nombre = N'Pucará' WHERE CodigoINE = '070805';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Pucará'
)
BEGIN
    UPDATE m SET CodigoINE = '070805'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0708' AND m.Nombre = N'Pucará';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pucará', '070805'
    FROM Provincia WHERE CodigoINE = '0708';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070901')
BEGIN
    UPDATE Municipio SET Nombre = N'Samaipata' WHERE CodigoINE = '070901';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Samaipata'
)
BEGIN
    UPDATE m SET CodigoINE = '070901'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Samaipata';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Samaipata', '070901'
    FROM Provincia WHERE CodigoINE = '0709';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070902')
BEGIN
    UPDATE Municipio SET Nombre = N'Pampagrande' WHERE CodigoINE = '070902';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Pampagrande'
)
BEGIN
    UPDATE m SET CodigoINE = '070902'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Pampagrande';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Pampagrande', '070902'
    FROM Provincia WHERE CodigoINE = '0709';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070903')
BEGIN
    UPDATE Municipio SET Nombre = N'Mairana' WHERE CodigoINE = '070903';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Mairana'
)
BEGIN
    UPDATE m SET CodigoINE = '070903'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Mairana';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mairana', '070903'
    FROM Provincia WHERE CodigoINE = '0709';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '070904')
BEGIN
    UPDATE Municipio SET Nombre = N'Quirusillas' WHERE CodigoINE = '070904';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Quirusillas'
)
BEGIN
    UPDATE m SET CodigoINE = '070904'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0709' AND m.Nombre = N'Quirusillas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Quirusillas', '070904'
    FROM Provincia WHERE CodigoINE = '0709';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071001')
BEGIN
    UPDATE Municipio SET Nombre = N'Montero' WHERE CodigoINE = '071001';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Montero'
)
BEGIN
    UPDATE m SET CodigoINE = '071001'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Montero';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Montero', '071001'
    FROM Provincia WHERE CodigoINE = '0710';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071002')
BEGIN
    UPDATE Municipio SET Nombre = N'General Saavedra' WHERE CodigoINE = '071002';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'General Saavedra'
)
BEGIN
    UPDATE m SET CodigoINE = '071002'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'General Saavedra';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'General Saavedra', '071002'
    FROM Provincia WHERE CodigoINE = '0710';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071003')
BEGIN
    UPDATE Municipio SET Nombre = N'Mineros' WHERE CodigoINE = '071003';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Mineros'
)
BEGIN
    UPDATE m SET CodigoINE = '071003'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Mineros';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Mineros', '071003'
    FROM Provincia WHERE CodigoINE = '0710';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071004')
BEGIN
    UPDATE Municipio SET Nombre = N'Fernández Alonso' WHERE CodigoINE = '071004';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Fernández Alonso'
)
BEGIN
    UPDATE m SET CodigoINE = '071004'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'Fernández Alonso';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Fernández Alonso', '071004'
    FROM Provincia WHERE CodigoINE = '0710';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071005')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro' WHERE CodigoINE = '071005';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'San Pedro'
)
BEGIN
    UPDATE m SET CodigoINE = '071005'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0710' AND m.Nombre = N'San Pedro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro', '071005'
    FROM Provincia WHERE CodigoINE = '0710';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071101')
BEGIN
    UPDATE Municipio SET Nombre = N'Concepción' WHERE CodigoINE = '071101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'Concepción'
)
BEGIN
    UPDATE m SET CodigoINE = '071101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'Concepción';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Concepción', '071101'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071102')
BEGIN
    UPDATE Municipio SET Nombre = N'San Javier' WHERE CodigoINE = '071102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Javier'
)
BEGIN
    UPDATE m SET CodigoINE = '071102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Javier';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Javier', '071102'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071103')
BEGIN
    UPDATE Municipio SET Nombre = N'San Julián' WHERE CodigoINE = '071103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Julián'
)
BEGIN
    UPDATE m SET CodigoINE = '071103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Julián';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Julián', '071103'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071104')
BEGIN
    UPDATE Municipio SET Nombre = N'San Antonio de Lomerio' WHERE CodigoINE = '071104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Antonio de Lomerio'
)
BEGIN
    UPDATE m SET CodigoINE = '071104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Antonio de Lomerio';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Antonio de Lomerio', '071104'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071105')
BEGIN
    UPDATE Municipio SET Nombre = N'San Ramón' WHERE CodigoINE = '071105';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Ramón'
)
BEGIN
    UPDATE m SET CodigoINE = '071105'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'San Ramón';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Ramón', '071105'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071106')
BEGIN
    UPDATE Municipio SET Nombre = N'Cuatro Cañadas' WHERE CodigoINE = '071106';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'Cuatro Cañadas'
)
BEGIN
    UPDATE m SET CodigoINE = '071106'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0711' AND m.Nombre = N'Cuatro Cañadas';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cuatro Cañadas', '071106'
    FROM Provincia WHERE CodigoINE = '0711';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071201')
BEGIN
    UPDATE Municipio SET Nombre = N'San Matías' WHERE CodigoINE = '071201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0712' AND m.Nombre = N'San Matías'
)
BEGIN
    UPDATE m SET CodigoINE = '071201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0712' AND m.Nombre = N'San Matías';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Matías', '071201'
    FROM Provincia WHERE CodigoINE = '0712';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071301')
BEGIN
    UPDATE Municipio SET Nombre = N'Comarapa' WHERE CodigoINE = '071301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0713' AND m.Nombre = N'Comarapa'
)
BEGIN
    UPDATE m SET CodigoINE = '071301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0713' AND m.Nombre = N'Comarapa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Comarapa', '071301'
    FROM Provincia WHERE CodigoINE = '0713';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071302')
BEGIN
    UPDATE Municipio SET Nombre = N'Saipina' WHERE CodigoINE = '071302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0713' AND m.Nombre = N'Saipina'
)
BEGIN
    UPDATE m SET CodigoINE = '071302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0713' AND m.Nombre = N'Saipina';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Saipina', '071302'
    FROM Provincia WHERE CodigoINE = '0713';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071401')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Suárez' WHERE CodigoINE = '071401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'Puerto Suárez'
)
BEGIN
    UPDATE m SET CodigoINE = '071401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'Puerto Suárez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Suárez', '071401'
    FROM Provincia WHERE CodigoINE = '0714';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071402')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Quijarro' WHERE CodigoINE = '071402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'Puerto Quijarro'
)
BEGIN
    UPDATE m SET CodigoINE = '071402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'Puerto Quijarro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Quijarro', '071402'
    FROM Provincia WHERE CodigoINE = '0714';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071403')
BEGIN
    UPDATE Municipio SET Nombre = N'El Carmen Rivero Tórrez' WHERE CodigoINE = '071403';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'El Carmen Rivero Tórrez'
)
BEGIN
    UPDATE m SET CodigoINE = '071403'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0714' AND m.Nombre = N'El Carmen Rivero Tórrez';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Carmen Rivero Tórrez', '071403'
    FROM Provincia WHERE CodigoINE = '0714';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071501')
BEGIN
    UPDATE Municipio SET Nombre = N'Ascención de Guarayos' WHERE CodigoINE = '071501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'Ascención de Guarayos'
)
BEGIN
    UPDATE m SET CodigoINE = '071501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'Ascención de Guarayos';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ascención de Guarayos', '071501'
    FROM Provincia WHERE CodigoINE = '0715';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071502')
BEGIN
    UPDATE Municipio SET Nombre = N'Urubichá' WHERE CodigoINE = '071502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'Urubichá'
)
BEGIN
    UPDATE m SET CodigoINE = '071502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'Urubichá';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Urubichá', '071502'
    FROM Provincia WHERE CodigoINE = '0715';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '071503')
BEGIN
    UPDATE Municipio SET Nombre = N'El Puente' WHERE CodigoINE = '071503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'El Puente'
)
BEGIN
    UPDATE m SET CodigoINE = '071503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0715' AND m.Nombre = N'El Puente';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'El Puente', '071503'
    FROM Provincia WHERE CodigoINE = '0715';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080101')
BEGIN
    UPDATE Municipio SET Nombre = N'Trinidad' WHERE CodigoINE = '080101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0801' AND m.Nombre = N'Trinidad'
)
BEGIN
    UPDATE m SET CodigoINE = '080101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0801' AND m.Nombre = N'Trinidad';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Trinidad', '080101'
    FROM Provincia WHERE CodigoINE = '0801';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080102')
BEGIN
    UPDATE Municipio SET Nombre = N'San Javier' WHERE CodigoINE = '080102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0801' AND m.Nombre = N'San Javier'
)
BEGIN
    UPDATE m SET CodigoINE = '080102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0801' AND m.Nombre = N'San Javier';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Javier', '080102'
    FROM Provincia WHERE CodigoINE = '0801';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080201')
BEGIN
    UPDATE Municipio SET Nombre = N'Riberalta' WHERE CodigoINE = '080201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0802' AND m.Nombre = N'Riberalta'
)
BEGIN
    UPDATE m SET CodigoINE = '080201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0802' AND m.Nombre = N'Riberalta';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Riberalta', '080201'
    FROM Provincia WHERE CodigoINE = '0802';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080202')
BEGIN
    UPDATE Municipio SET Nombre = N'Guayaramerín' WHERE CodigoINE = '080202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0802' AND m.Nombre = N'Guayaramerín'
)
BEGIN
    UPDATE m SET CodigoINE = '080202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0802' AND m.Nombre = N'Guayaramerín';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Guayaramerín', '080202'
    FROM Provincia WHERE CodigoINE = '0802';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080301')
BEGIN
    UPDATE Municipio SET Nombre = N'Reyes' WHERE CodigoINE = '080301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Reyes'
)
BEGIN
    UPDATE m SET CodigoINE = '080301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Reyes';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Reyes', '080301'
    FROM Provincia WHERE CodigoINE = '0803';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080302')
BEGIN
    UPDATE Municipio SET Nombre = N'San Borja' WHERE CodigoINE = '080302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'San Borja'
)
BEGIN
    UPDATE m SET CodigoINE = '080302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'San Borja';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Borja', '080302'
    FROM Provincia WHERE CodigoINE = '0803';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080303')
BEGIN
    UPDATE Municipio SET Nombre = N'Santa Rosa' WHERE CodigoINE = '080303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Santa Rosa'
)
BEGIN
    UPDATE m SET CodigoINE = '080303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Santa Rosa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santa Rosa', '080303'
    FROM Provincia WHERE CodigoINE = '0803';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080304')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Menor de Rurrenabaque' WHERE CodigoINE = '080304';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Puerto Menor de Rurrenabaque'
)
BEGIN
    UPDATE m SET CodigoINE = '080304'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0803' AND m.Nombre = N'Puerto Menor de Rurrenabaque';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Menor de Rurrenabaque', '080304'
    FROM Provincia WHERE CodigoINE = '0803';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080401')
BEGIN
    UPDATE Municipio SET Nombre = N'Santa Ana' WHERE CodigoINE = '080401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0804' AND m.Nombre = N'Santa Ana'
)
BEGIN
    UPDATE m SET CodigoINE = '080401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0804' AND m.Nombre = N'Santa Ana';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santa Ana', '080401'
    FROM Provincia WHERE CodigoINE = '0804';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080402')
BEGIN
    UPDATE Municipio SET Nombre = N'Exaltación' WHERE CodigoINE = '080402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0804' AND m.Nombre = N'Exaltación'
)
BEGIN
    UPDATE m SET CodigoINE = '080402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0804' AND m.Nombre = N'Exaltación';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Exaltación', '080402'
    FROM Provincia WHERE CodigoINE = '0804';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080501')
BEGIN
    UPDATE Municipio SET Nombre = N'San Ignacio' WHERE CodigoINE = '080501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0805' AND m.Nombre = N'San Ignacio'
)
BEGIN
    UPDATE m SET CodigoINE = '080501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0805' AND m.Nombre = N'San Ignacio';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Ignacio', '080501'
    FROM Provincia WHERE CodigoINE = '0805';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080601')
BEGIN
    UPDATE Municipio SET Nombre = N'Loreto' WHERE CodigoINE = '080601';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0806' AND m.Nombre = N'Loreto'
)
BEGIN
    UPDATE m SET CodigoINE = '080601'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0806' AND m.Nombre = N'Loreto';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Loreto', '080601'
    FROM Provincia WHERE CodigoINE = '0806';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080602')
BEGIN
    UPDATE Municipio SET Nombre = N'San Andrés' WHERE CodigoINE = '080602';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0806' AND m.Nombre = N'San Andrés'
)
BEGIN
    UPDATE m SET CodigoINE = '080602'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0806' AND m.Nombre = N'San Andrés';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Andrés', '080602'
    FROM Provincia WHERE CodigoINE = '0806';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080701')
BEGIN
    UPDATE Municipio SET Nombre = N'San Joaquín' WHERE CodigoINE = '080701';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'San Joaquín'
)
BEGIN
    UPDATE m SET CodigoINE = '080701'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'San Joaquín';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Joaquín', '080701'
    FROM Provincia WHERE CodigoINE = '0807';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080702')
BEGIN
    UPDATE Municipio SET Nombre = N'San Ramón' WHERE CodigoINE = '080702';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'San Ramón'
)
BEGIN
    UPDATE m SET CodigoINE = '080702'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'San Ramón';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Ramón', '080702'
    FROM Provincia WHERE CodigoINE = '0807';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080703')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Siles' WHERE CodigoINE = '080703';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'Puerto Siles'
)
BEGIN
    UPDATE m SET CodigoINE = '080703'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0807' AND m.Nombre = N'Puerto Siles';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Siles', '080703'
    FROM Provincia WHERE CodigoINE = '0807';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080801')
BEGIN
    UPDATE Municipio SET Nombre = N'Magdalena' WHERE CodigoINE = '080801';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Magdalena'
)
BEGIN
    UPDATE m SET CodigoINE = '080801'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Magdalena';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Magdalena', '080801'
    FROM Provincia WHERE CodigoINE = '0808';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080802')
BEGIN
    UPDATE Municipio SET Nombre = N'Baures' WHERE CodigoINE = '080802';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Baures'
)
BEGIN
    UPDATE m SET CodigoINE = '080802'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Baures';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Baures', '080802'
    FROM Provincia WHERE CodigoINE = '0808';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '080803')
BEGIN
    UPDATE Municipio SET Nombre = N'Huacaraje' WHERE CodigoINE = '080803';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Huacaraje'
)
BEGIN
    UPDATE m SET CodigoINE = '080803'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0808' AND m.Nombre = N'Huacaraje';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Huacaraje', '080803'
    FROM Provincia WHERE CodigoINE = '0808';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090101')
BEGIN
    UPDATE Municipio SET Nombre = N'Cobija' WHERE CodigoINE = '090101';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Cobija'
)
BEGIN
    UPDATE m SET CodigoINE = '090101'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Cobija';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Cobija', '090101'
    FROM Provincia WHERE CodigoINE = '0901';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090102')
BEGIN
    UPDATE Municipio SET Nombre = N'Porvenir' WHERE CodigoINE = '090102';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Porvenir'
)
BEGIN
    UPDATE m SET CodigoINE = '090102'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Porvenir';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Porvenir', '090102'
    FROM Provincia WHERE CodigoINE = '0901';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090103')
BEGIN
    UPDATE Municipio SET Nombre = N'Bolpebra' WHERE CodigoINE = '090103';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Bolpebra'
)
BEGIN
    UPDATE m SET CodigoINE = '090103'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Bolpebra';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Bolpebra', '090103'
    FROM Provincia WHERE CodigoINE = '0901';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090104')
BEGIN
    UPDATE Municipio SET Nombre = N'Bella Flor' WHERE CodigoINE = '090104';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Bella Flor'
)
BEGIN
    UPDATE m SET CodigoINE = '090104'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0901' AND m.Nombre = N'Bella Flor';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Bella Flor', '090104'
    FROM Provincia WHERE CodigoINE = '0901';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090201')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Rico' WHERE CodigoINE = '090201';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'Puerto Rico'
)
BEGIN
    UPDATE m SET CodigoINE = '090201'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'Puerto Rico';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Rico', '090201'
    FROM Provincia WHERE CodigoINE = '0902';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090202')
BEGIN
    UPDATE Municipio SET Nombre = N'San Pedro' WHERE CodigoINE = '090202';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'San Pedro'
)
BEGIN
    UPDATE m SET CodigoINE = '090202'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'San Pedro';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Pedro', '090202'
    FROM Provincia WHERE CodigoINE = '0902';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090203')
BEGIN
    UPDATE Municipio SET Nombre = N'Filadelfia' WHERE CodigoINE = '090203';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'Filadelfia'
)
BEGIN
    UPDATE m SET CodigoINE = '090203'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0902' AND m.Nombre = N'Filadelfia';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Filadelfia', '090203'
    FROM Provincia WHERE CodigoINE = '0902';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090301')
BEGIN
    UPDATE Municipio SET Nombre = N'Puerto Gonzalo Moreno' WHERE CodigoINE = '090301';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'Puerto Gonzalo Moreno'
)
BEGIN
    UPDATE m SET CodigoINE = '090301'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'Puerto Gonzalo Moreno';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Puerto Gonzalo Moreno', '090301'
    FROM Provincia WHERE CodigoINE = '0903';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090302')
BEGIN
    UPDATE Municipio SET Nombre = N'San Lorenzo' WHERE CodigoINE = '090302';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'San Lorenzo'
)
BEGIN
    UPDATE m SET CodigoINE = '090302'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'San Lorenzo';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'San Lorenzo', '090302'
    FROM Provincia WHERE CodigoINE = '0903';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090303')
BEGIN
    UPDATE Municipio SET Nombre = N'Sena' WHERE CodigoINE = '090303';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'Sena'
)
BEGIN
    UPDATE m SET CodigoINE = '090303'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0903' AND m.Nombre = N'Sena';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Sena', '090303'
    FROM Provincia WHERE CodigoINE = '0903';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090401')
BEGIN
    UPDATE Municipio SET Nombre = N'Santa Rosa' WHERE CodigoINE = '090401';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0904' AND m.Nombre = N'Santa Rosa'
)
BEGIN
    UPDATE m SET CodigoINE = '090401'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0904' AND m.Nombre = N'Santa Rosa';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santa Rosa', '090401'
    FROM Provincia WHERE CodigoINE = '0904';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090402')
BEGIN
    UPDATE Municipio SET Nombre = N'Ingavi' WHERE CodigoINE = '090402';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0904' AND m.Nombre = N'Ingavi'
)
BEGIN
    UPDATE m SET CodigoINE = '090402'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0904' AND m.Nombre = N'Ingavi';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Ingavi', '090402'
    FROM Provincia WHERE CodigoINE = '0904';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090501')
BEGIN
    UPDATE Municipio SET Nombre = N'Nueva Esperanza' WHERE CodigoINE = '090501';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Nueva Esperanza'
)
BEGIN
    UPDATE m SET CodigoINE = '090501'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Nueva Esperanza';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Nueva Esperanza', '090501'
    FROM Provincia WHERE CodigoINE = '0905';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090502')
BEGIN
    UPDATE Municipio SET Nombre = N'Villa Nueva' WHERE CodigoINE = '090502';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Villa Nueva'
)
BEGIN
    UPDATE m SET CodigoINE = '090502'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Villa Nueva';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Villa Nueva', '090502'
    FROM Provincia WHERE CodigoINE = '0905';
END;
IF EXISTS (SELECT 1 FROM Municipio WHERE CodigoINE = '090503')
BEGIN
    UPDATE Municipio SET Nombre = N'Santos Mercado' WHERE CodigoINE = '090503';
END
ELSE IF EXISTS (
    SELECT 1 FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Santos Mercado'
)
BEGIN
    UPDATE m SET CodigoINE = '090503'
    FROM Municipio m
    INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
    WHERE p.CodigoINE = '0905' AND m.Nombre = N'Santos Mercado';
END
ELSE
BEGIN
    INSERT INTO Municipio (IdProvincia, Nombre, CodigoINE)
    SELECT IdProvincia, N'Santos Mercado', '090503'
    FROM Provincia WHERE CodigoINE = '0905';
END;

-- E. Unicidad de los códigos INE cuando están informados.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Departamento_CodigoINE' AND object_id=OBJECT_ID('Departamento'))
    CREATE UNIQUE INDEX UX_Departamento_CodigoINE ON Departamento(CodigoINE) WHERE CodigoINE IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Provincia_CodigoINE' AND object_id=OBJECT_ID('Provincia'))
    CREATE UNIQUE INDEX UX_Provincia_CodigoINE ON Provincia(CodigoINE) WHERE CodigoINE IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_Municipio_CodigoINE' AND object_id=OBJECT_ID('Municipio'))
    CREATE UNIQUE INDEX UX_Municipio_CodigoINE ON Municipio(CodigoINE) WHERE CodigoINE IS NOT NULL;

COMMIT TRANSACTION;
PRINT 'Catálogo territorial cargado correctamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- F. Verificación final.
SELECT COUNT(*) AS Departamentos FROM Departamento;
SELECT COUNT(*) AS Provincias FROM Provincia;
SELECT COUNT(*) AS Municipios FROM Municipio;

-- Resultado esperado: 9 departamentos, 112 provincias y 340 municipios.

SELECT d.Nombre AS Departamento, p.Nombre AS Provincia, m.Nombre AS Municipio, m.CodigoINE
FROM Municipio m
INNER JOIN Provincia p ON p.IdProvincia = m.IdProvincia
INNER JOIN Departamento d ON d.IdDepartamento = p.IdDepartamento
ORDER BY d.CodigoINE, p.CodigoINE, m.CodigoINE;
