
SELECT * FROM PACIENTE 

--INSERTr

INSERT INTO paciente (nombre,apellido,fNacimiento,domicilio,idPais,telefono,email,observacion) values('andres','palomino','1990-03-09','quilla','ARG','','','')

--DELETE

SELECT *FROM PACIENTE WHERE NOMBRE='camilo'

delete from paciente where idPaciente=4
--UPDATE

UPDATE  paciente  SET idPais='COL' WHERE nombre='misael'
UPDATE PACIENTE SET observacion='Pacientes creados desde UI' 

