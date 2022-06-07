

-- ADD FOREIGN KEY

ALTER TABLE HistoriaPaciente 
ADD FOREIGN KEY(idPaciente) REFERENCES Paciente(idPaciente)

--ADD PRIMARY KEY 
CREATE TABLE Prueba(
       idprueba int NOT NULL,
	   nombre varchar(50) NOT NULL, 
	   descripcion varchar(50) NULL,

	   CONSTRAINT PK_idprueba PRIMARY KEY (idprueba)
)
