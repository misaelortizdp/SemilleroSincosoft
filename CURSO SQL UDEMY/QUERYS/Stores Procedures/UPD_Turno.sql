


/*
select * from paciente
select * from turno
select * from turnopaciente

*/

--EXEC upd_turno 4,1,'El paciente ha sido atendido'



CREATE PROC UPD_Turno(
				@idturno turno,
				@estado tinyint,
				@observacion observacion)

AS
set nocount on

if exists(SELECT * from Turno
			WHERE idturno = @idturno)
	UPDATE Turno SET estado = @estado,
					observacion = @observacion
	WHERE idturno = @idturno


ELSE
	SELECT 0 as resultado

