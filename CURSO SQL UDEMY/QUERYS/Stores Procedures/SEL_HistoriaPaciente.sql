
exec SELECT_HistoriaPaciente 1

CREATE PROC SEL_HistoriaPaciente(
				@idpaciente paciente)

AS
set nocount on

/*
select * from historia
select * from historiapaciente

*/

IF exists(SELECT * from Paciente P
				INNER JOIN HistoriaPaciente HP
				ON HP.idPaciente = P.idPaciente
				INNER JOIN Historia H
				ON H.idHistoria = HP.idHistoria
				INNER JOIN MedicoEspecialidad ME
				ON ME.idMedico = HP.idMedico
				INNER JOIN Medico M
				ON M.idMedico = ME.idMedico
				WHERE P.idPaciente = @idpaciente)
	SELECT * from Paciente P
	INNER JOIN HistoriaPaciente HP
	ON HP.idPaciente = P.idPaciente
	INNER JOIN Historia H
	ON H.idHistoria = HP.idHistoria
	INNER JOIN MedicoEspecialidad ME
	ON ME.idMedico = HP.idMedico
	INNER JOIN Medico M
	ON M.idMedico = ME.idMedico
	WHERE P.idPaciente = @idpaciente
ELSE
	--print 'No existen historias clinicas para el paciente'
	select 0 as resultado


