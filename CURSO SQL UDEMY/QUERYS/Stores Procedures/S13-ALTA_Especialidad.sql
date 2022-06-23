

--select * from especialidad

--EXEC alta_especialidad 'DERMATOLOGÍA'

CREATE proc ALTA_Especialidad(
			@especialidad varchar(30)
			)

as

set nocount on

IF NOT EXISTS(SELECT TOP 1 idespecialidad from Especialidad WHERE especialidad = @especialidad)
BEGIN
	INSERT INTO Especialidad (especialidad)
	VALUES (@especialidad)
	print 'La especialidad se agregó correctamente'
	return
END
ELSE
BEGIN
	print 'La especialidad ya existe.'
	return
END


