
--CREACION STORED PROCEDURES
CREATE PROC S_paciente(
            @idpaciente int 
)
AS 
 
SELECT * FROM paciente WHERE idpaciente = @idpaciente

GO 

-- LLAMAR UN STORED PROCEDURES 
EXEC S_paciente 7

-- DECLARAR VARIABLES
DECLARE @ordenamiento CHAR(1)='A'

-- ASIGNAR VLOR A VARIABLE
SET @ordenamiento='D'

PRINT @ordenamiento

-- USO DE ISNULL
DECLARE @a CHAR(1)
DECLARE @b CHAR(1)

SET @a = ISNULL(@b, 'A') 

PRINT @a
