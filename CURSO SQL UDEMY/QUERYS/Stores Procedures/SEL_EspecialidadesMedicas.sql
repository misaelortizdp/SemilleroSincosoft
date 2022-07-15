

--exec SEL_EspecialidadesMedica

CREATE PROC SEL_EspecialidadesMedica

AS
set nocount on

--select * from especialidad


if exists(SELECT * from especialidad)
	SELECT * from especialidad
else
	select 0 as resultado


