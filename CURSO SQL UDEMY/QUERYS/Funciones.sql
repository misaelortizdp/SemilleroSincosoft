

--FUNCIONES ESCALARES

--select dbo.nombrefun (256)
select dbo.concatenar('Lopez','Roberto')
select dbo.obtenerPais (9)

select * from paciente

CREATE FUNCTION nombrefun (@var int)
RETURNS int

AS

BEGIN
	set @var = @var * 5
	return @var
END

CREATE FUNCTION concatenar (
				@apellido varchar(50),
				@nombre varchar(50)
				)
RETURNS varchar(100)

AS
BEGIN
	declare @resultado varchar(100)
	set @resultado = @apellido + ', ' + @nombre
	return @resultado	

END

CREATE FUNCTION obtenerPais(
				@idpaciente paciente
				)
RETURNS varchar(50)

AS
BEGIN
	declare @pais varchar(50)
	SET @pais = (SELECT PA.pais From paciente P
					INNER JOIN Pais PA
					ON PA.idPais = P.idPais
					WHERE idPaciente=@idpaciente)
	
	RETURN @pais
END

--FUNCIONES DE TIPO TABLA

select * from dbo.listaPaises()


CREATE FUNCTION listaPaises()
RETURNS @paises TABLE(idpais char(3), pais varchar(50))
AS
BEGIN
	
	INSERT INTO @paises values('ESP','España')
	INSERT INTO @paises values('MEX','Mexico')
	INSERT INTO @paises values('CHI','Chile')
	INSERT INTO @paises values('PER','Perú')
	INSERT INTO @paises values('ARG','Argentina')

	RETURN

END




