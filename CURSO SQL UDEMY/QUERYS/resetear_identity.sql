
-- RESETEA EL VALOR IDENTITI PARA QUE COMIENCE NUEVAMENTE POR 1

dbcc CHECKIDENT ('tablaexample',RESEED, 0)