
DECLARE @idpaciente int
DECLARE @idturno int
set @idpaciente =7


-- USO DE IF, ELSE
IF @idpaciente=7
BEGIN
    set @idturno=20
    select * from Paciente where idpaciente=@idpaciente
	print @idturno

	--USO DE EXISTS
	IF EXISTS(select * from paciente where idpaciente=10)
	print 'existe'

END 
ELSE 
    PRINT 'No se cumplio la condición'
	


-- USO DEL WHILE 
declare @contador int=0

WHILE @contador <=10
BEGIN
      PRINT @contador 
	  set @contador = @contador+1

END


--USO DEL CASE

DECLARE @valor int 
DECLARE @resultado char(10)=''

set @valor =10 

set @resultado = (CASE WHEN @valor = 10 THEN 'ROJO'
                       WHEN @valor = 20 THEN 'VERDE' 
					   WHEN @valor = 30 THEN 'AZUL'
                      END )

PRINT @resultado

select *, (CASE WHEN estado=0 THEN'VERDE'
                WHEN estado=1 THEN'ROJO' 				
				else 'GRIS'
END) as colorTurno from turno 


-- BREAK Y RETURN 

--BREAK -- SACA DEL BUCLE PERO SIGUE EJECUTANDO
declare @contador2 int=0

WHILE @contador2 <=10
BEGIN
      PRINT @contador2 
	  set @contador2 = @contador2+1
	  IF @contador2 = 3
	  BREAK
END
PRINT 'SIGUE EJECUTANDO '

--RETURN -- SE SALE DEL SCRIPT O QUERY -- NO SIGUE EJECUTANDO
declare @contador3 int=0

 WHILE @contador3 <=10
BEGIN
      PRINT @contador3 
	  set @contador3 = @contador3+1
	  IF @contador3 = 3
	  RETURN
END
PRINT 'ESTE MENSAJE NO SALDRA EN CONSOLA'

-- TRY CATCH (MANEJO DE ERRORES)

declare @contadorb int 
BEGIN TRY 
    set @contadorb = 'texto'
END TRY 

BEGIN CATCH 
   print 'No es posible asignar un texto a la variable contador'
END CATCH 

