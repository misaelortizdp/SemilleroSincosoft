
--exec UPD_Paciente 4,'Jean','Darros','montes 435',jeand@gmail.com

CREATE PROC UPD_Paciente(
				@idpaciente paciente,
				@nombre varchar(50),
				@apellido varchar(50),
				@domicilio varchar(50),
				@email varchar(30))

AS
set nocount on

if exists(SELECT * from Paciente
			WHERE idPaciente = @idpaciente)
	UPDATE Paciente SET nombre = @nombre,
					apellido = @apellido,
					domicilio = @domicilio,
					email = @email
	WHERE idpaciente = @idpaciente


ELSE
	SELECT 0 as resultado

