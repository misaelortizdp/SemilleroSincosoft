
ALTER PROCEDURE [dbo].[OU_ADICarteraProCliEdades]
@macro varchar (10), @pro varchar (500), @vta varchar (10), @ter varchar (10),
@FIodsF varchar (10), @FFodsF varchar (10),@FIescF varchar (10), @FFescF varchar (10),
@FIentF varchar (10), @FFentF varchar (10), @FIaplF varchar (10),@FFaplF varchar (10),
@fechaconsigna varchar (10),@fechaconsignaF varchar (10),@fechadoc varchar (10),@fechadocF varchar (10)
,@CPP varchar (10),@disp nvarchar (10), @prin nvarchar (5), @usu varchar (5), @sociedad varchar(5), @empresa varchar(9)= '1', @valorVtaAjust varchar(9) = '0'
, @PivotEdad varchar(9) = '0', @FechaCorteProg varchar(15) = NULL
 
as

/* estados de venta == 0=Agrupacion Abierta; 1=Cerrada; 2=Bloqueada; 3=Desagrupada */

--EXEC OU_ADICarteraProCliEdades @macro='45', @pro='241', @vta='18454', @ter='-1', @FIodsF='', @FFodsF='', @FIescF='', @FFescF='', @FIentF='', @FFentF='', @FIaplF='', @FFaplF='', @fechaconsigna='', @fechaconsignaF='', @fechadoc='', @fechadocF='31/01/2022', @CPP='-1', @disp='1', @prin='0', @usu='188', @sociedad='4', @empresa='1', @valorVtaAjust='1', @PivotEdad='0', @FechaCorteProg='10/02/2022'

SET NOCOUNT ON

declare @SqlA nvarchar (MAX), @SqlA2 nvarchar (MAX), @SqlATra nvarchar (MAX),  
@cantObr varchar (20), @cantMac varchar (20), @filConcepto varchar (150), @criterio nvarchar(150), @SqlAfectaVta nvarchar (max) 

IF(ISNULL(@FechaCorteProg,'')='' or @FechaCorteProg='-1') set @FechaCorteProg = CONVERT(VARCHAR(20),GETDATE(),103)
--***********************************************************************************************************************************
--**********************************************Temporal de las sociedades****************************************************************
--***********************************************************************************************************************************
CREATE TABLE #sociedades( Sociedad int, SocNombre varchar(100), CjtID int, CjtNombre varchar(100), ObrObra int, ObrNombre varchar(100), ObrCorporacion varchar(5)  )

if @empresa NOT IN('','-1') 
begin

	set @SqlA='
	INSERT INTO #sociedades( Sociedad , SocNombre, CjtID,  CjtNombre, ObrObra , ObrNombre, ObrCorporacion )
	SELECT	ADISociedades.ASoID, ADISociedades.ASoNombre, ADPConjuntos.CjtID,  ADPConjuntos.CjtNombre, ADPObras.ObrObra, ADPObras.ObrNombre, ADPObras.ObrCorporacion
	FROM	ADISociedades RIGHT JOIN ADPConjuntos on ADISociedades.ASoID = ADPConjuntos.CjtSociedad 
			INNER JOIN ADPObras ON ADPConjuntos.CjtID = ADPObras.ObrConjunto
			INNER JOIN ADIUsuariosObra ON ObrObra = ADIUsuariosObra.UObObra 
	WHERE	UObUsuario='+@usu+' AND ADISociedades.ASoEmpresa='''+@empresa+''' 
			'
	
	if(@sociedad not in('','-1'))
	begin
		set @SqlA=@SqlA+' AND ADISociedades.ASoID = '''+@sociedad+''''
	end
	
	if(@macro not in('','-1'))
	begin
		set @SqlA=@SqlA+' AND ADPConjuntos.CjtID = '''+@macro+''''
	end
	
	if(@pro not in('','-1'))
	begin
		set @SqlA=@SqlA+' AND ADPObras.ObrObra in('+@pro+')'
	end
	
	set @SqlA=@SqlA+'
	GROUP BY ADISociedades.ASoID, ADISociedades.ASoNombre, ADPConjuntos.CjtID,  ADPConjuntos.CjtNombre, ADPObras.ObrObra, ADPObras.ObrNombre, ADPObras.ObrCorporacion'
	--print(@SqlA)
	EXECUTE  sp_executesql @SqlA
end


--***********************************************************************************************************************************
--******************************************Temporal Ventas Ajustadas****************************************************************
--***********************************************************************************************************************************

CREATE TABLE #vtaAjustadas(codAgr int, estado int)

IF @valorVtaAjust = 1 BEGIN

	set @SqlA='
	INSERT INTO #vtaAjustadas(codAgr, estado)
	SELECT	ADIVentasTerDoc.VTDID, ADIVentasTerDoc.VTDEstado
	FROM    ADIVentasTerDoc INNER JOIN ADIPlanPagos ON ADIVentasTerDoc.VTDID = ADIPlanPagos.PPaAgrupaVenta 
			INNER JOIN ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo 
			INNER JOIN ADIConceptosPlanPagos ON ADIPlanPagosDet.PPDConcepto = ADIConceptosPlanPagos.CPPId 
			INNER JOIN #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra
	WHERE   (ADIVentasTerDoc.VTDEstado <> 3) AND (ADIConceptosPlanPagos.CPPAfectaVta = 1) AND (ADIPlanPagosDet.PPDEstado = 0)
			'		

	if(@vta not in('','-1'))
	begin
		set @SqlA=@SqlA+' AND ADIVentasTerDoc.VTDID ='+ @vta
	end

	set @SqlA=@SqlA+' GROUP BY ADIVentasTerDoc.VTDID, ADIVentasTerDoc.VTDTotNeto, ADIVentasTerDoc.VTDEstado HAVING (SUM(ADIPlanPagosDet.PPDValor) = ADIVentasTerDoc.VTDTotNeto)'

	EXECUTE  sp_executesql @SqlA

END

-- Creo la tabla de Tramites ODS
CREATE TABLE #PrincipalTIniGr( PPDid varchar (10), VTDVrAdicionales money, VTDVrExclusiones money, VTDVrSubTot money, CPPAfectaVta  varchar (100), ObrObra  varchar (100), ObrNombre  varchar (100), CjtID  varchar (100), CjtNombre  varchar (100), VtDId  varchar (100), TerID  varchar (100), TerNombre  varchar (300), TerNit  varchar (100),VTDCodInternoDetalle varchar(800), VTDCodInterno varchar(800), TCoId  varchar (100), TCoDesc  varchar (100),  Valor money, PP money, PPNC money, VTDFecha  smalldatetime, FechaCons smalldatetime,FechaDoc smalldatetime, AMvID int, PPNCna money, UnidPartes varchar (8000), Direccion varchar (100), AMADesc varchar (100), Telefono varchar (100),  vendedor varchar (100), VTDDto money, VTDDtoFin money, VTDDto2 money )
CREATE TABLE #PrincipalTIni( PPDid varchar (10), VTDVrAdicionales money, VTDVrExclusiones money, VTDVrSubTot money, CPPAfectaVta  varchar (100), ObrObra  varchar (100), ObrNombre  varchar (500), CjtID  varchar (100), CjtNombre  varchar (500), VtDId  varchar (100), TerID  varchar (100), TerNombre  varchar (500), TerNit  varchar (100),VTDCodInternoDetalle  varchar (500), VTDCodInterno varchar(800), encargo varchar(500), TCoId  varchar (100), TCoDesc  varchar (500),  Valor money, PP money, PPNC money, VTDFecha  smalldatetime, FechaCons smalldatetime,FechaDoc smalldatetime, AMvID int, PPNCna money, UnidPartes varchar (500), Direccion varchar (100), AMADesc varchar (500), Telefono varchar (100),  vendedor varchar (100), VTDDto money, VTDDtoFin money, VTDDto2 money)
CREATE TABLE #Principal( ObrObra int ,ObrNombre varchar(500), CjtID int, CjtNombre varchar (1000), VtDId int, TerID int, TerNombre varchar (1000), TerNit varchar (100), VTDCodInternoDetalle varchar (500), VTDCodInterno varchar(800), encargo varchar(500),TCoId int, TCoDesc varchar (500), Valor money, Pagado money,FIods smalldatetime, FFods smalldatetime, FIesc smalldatetime, FFesc smalldatetime, FIent smalldatetime, FFent smalldatetime,FIapl smalldatetime,FFapl smalldatetime, pagadoNC money, CPPAfectaVta int, cantObr varchar (500), cantMac varchar(500), VTDVrAdicionales money, VTDVrExclusiones money, VTDVrSubTot money, PPNCna money, UnidPartes varchar (500), Direccion varchar (100), AMADesc varchar (500), Telefono varchar (100),  vendedor varchar (1000), VTDDto money, VTDDtoFin money, VTDFecha smalldatetime, VTDDto2 money)

--**********************************************************
-- se crea una tabla temporal en vez de subconsulta
-- ya que demoraba mucho el proceso 
-- RR 15/04/2019
--***********************************************************

CREATE TABLE #t(vtdfecha smalldatetime,  VTDDto money , VTDDto2 money, VTDDtoFin money,  PPDid varchar (10), VTDVrAdicionales money, VTDVrExclusiones money, VTDVrSubTot money, CPPAfectaVta  varchar (100),ObrObra  varchar (100), 
				ObrNombre  varchar (100), CjtID  varchar (100), CjtNombre  varchar (100), VtDId  varchar (100), TerID  varchar (100), TerNombre  varchar (300), TerNit  varchar (100),VTDCodInternoDetalle  varchar (800), VTDCodInterno varchar(800), TCoId  varchar (100), TCoDesc  varchar (100),  Valor money,
				ADcFechaConsigna smalldatetime, ADCFecha smalldatetime, UnidPartes varchar (8000), Direccion varchar (100), AMADesc varchar (100), Telefono varchar (100),  vendedor varchar (100), encargo varchar(100))

--**********************************************************
-- se crea una tabla temporal en vez de subconsulta
-- ya que demoraba mucho el proceso 
--***********************************************************

CREATE TABLE #PrincipalF(VTDFecha smalldatetime, ObrObra int, ObrNombre varchar(500), CjtID int, CjtNombre varchar(500), TerID int, TerNombre varchar(500), TerNit varchar(100),
								 VTDCodInternoDetalle varchar(500), VTDCodInterno varchar(800), encargo varchar(500),TCoDesc varchar(500),TCoId int,Valor money,ValorMacro money,ValorObra money,Pagado money,PagadoMacro money,PagadoObra money
								,pagadoNC money,PagadoMacroNC money,PagadoObraNC money, CPPAfectaVta int,PagadoMacroAfec money,PagadoObraAfec money,PagadoMacroNCAfec money,PagadoObraNCAfec money,ValorMacroAfec money,ValorObraAfec money,
								ValorAfec money,PagadoAfec money,PagadoNCAfec money, cantMac varchar (20), cantObr varchar (20)
								, VTDVrAdicionales money, VTDVrExclusiones money, VTDVrSubTot money, UnidPartes varchar (8000), Direccion varchar (100), AMADesc varchar (100), Telefono varchar (100),  vendedor varchar (100), VTDDto money, VTDDtoFin money,
								VTDDto2 money
							  )


Create Table #TramitesFechasODS( TVDotroSi int, TVDFechaI smalldatetime, TVDFechaF smalldatetime, TCfId varchar (10), TVtDocVenta varchar (100))
Create Table #TramitesFechasESC( TVDotroSi int, TVDFechaI smalldatetime, TVDFechaF smalldatetime, TCfId varchar (10), TVtDocVenta varchar (100))
Create Table #TramitesFechasENT( TVDotroSi int, TVDFechaI smalldatetime, TVDFechaF smalldatetime, TCfId varchar (10), TVtDocVenta varchar (100))
Create Table #TramitesFechasAPL( TVDotroSi int, TVDFechaI smalldatetime, TVDFechaF smalldatetime, TCfId varchar (10), TVtDocVenta varchar (100))

INSERT INTO #TramitesFechasODS(TVDotroSi, TVDFechaI, TVDFechaF, TCfId, TVtDocVenta)
SELECT  DISTINCT MAX(TVDotroSi) OVER(PARTITION BY ADITramitesVentaDet.TVDCodTramite), ADITramitesVentaDet.TVDFechaI, ADITramitesVentaDet.TVDFechaF, ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta
FROM            ADITramites INNER JOIN
                         ADITramitesConfig ON ADITramites.TraID = ADITramitesConfig.TCfTramite INNER JOIN
                         ADITramitesVentaDet ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite INNER JOIN
                         ADITramitesVenta ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID INNER JOIN
                         ADIVentasTerDoc ON ADITramitesVenta.TVtDocVenta = ADIVentasTerDoc.VTDID INNER JOIN
                         #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra
WHERE     (ADITramitesConfig.TCfId IN ('ODS')) 

INSERT INTO #TramitesFechasESC(TVDotroSi,TVDFechaI, TVDFechaF, TCfId, TVtDocVenta)
SELECT  MAX(TVDotroSi) ,max(ADITramitesVentaDet.TVDFechaI), max(ADITramitesVentaDet.TVDFechaF)
, ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta
FROM            ADITramites INNER JOIN
                         ADITramitesConfig ON ADITramites.TraID = ADITramitesConfig.TCfTramite INNER JOIN
                         ADITramitesVentaDet ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite INNER JOIN
                         ADITramitesVenta ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID INNER JOIN
                         ADIVentasTerDoc ON ADITramitesVenta.TVtDocVenta = ADIVentasTerDoc.VTDID INNER JOIN
                         #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra
WHERE     (ADITramitesConfig.TCfId IN ('ESC'))
group by ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta

INSERT INTO #TramitesFechasENT(TVDotroSi,TVDFechaI, TVDFechaF, TCfId, TVtDocVenta)
SELECT  MAX(TVDotroSi) ,max(ADITramitesVentaDet.TVDFechaI), max(ADITramitesVentaDet.TVDFechaF)
, ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta
FROM            ADITramites INNER JOIN
                         ADITramitesConfig ON ADITramites.TraID = ADITramitesConfig.TCfTramite INNER JOIN
                         ADITramitesVentaDet ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite INNER JOIN
                         ADITramitesVenta ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID INNER JOIN
                         ADIVentasTerDoc ON ADITramitesVenta.TVtDocVenta = ADIVentasTerDoc.VTDID INNER JOIN
                         #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra
WHERE     (ADITramitesConfig.TCfId IN ( 'ENT'))
group by ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta



INSERT INTO #TramitesFechasAPL(TVDotroSi,TVDFechaI, TVDFechaF, TCfId, TVtDocVenta)
SELECT  MAX(TVDotroSi) ,max(ADITramitesVentaDet.TVDFechaI), max(ADITramitesVentaDet.TVDFechaF)
, ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta
FROM            ADITramites INNER JOIN
                         ADITramitesConfig ON ADITramites.TraID = ADITramitesConfig.TCfTramite INNER JOIN
                         ADITramitesVentaDet ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite INNER JOIN
                         ADITramitesVenta ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID INNER JOIN
                         ADIVentasTerDoc ON ADITramitesVenta.TVtDocVenta = ADIVentasTerDoc.VTDID INNER JOIN
                         #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra
WHERE     (ADITramitesConfig.TCfId IN ('APL'))
group by ADITramitesConfig.TCfId, ADITramitesVenta.TVtDocVenta

-- Tabla Inicial Agrupada por las fechas de consignacion
declare @SqlATIni nvarchar(max)
declare  @filfechaconsigna  varchar (300), @filfechadoc  varchar (300), @filGeneral  varchar (300)


set @filfechaconsigna=' '
set @filfechadoc=' '

-- fechas consigna
if (@fechaconsigna not in ('','-1') or @fechaconsignaF not in ('','-1')) 
begin
	IF(@fechaconsignaF in ('','-1')) 
	BEGIN
		IF(@fechaconsigna not in ('','-1')) set @filfechaconsigna=' and ADcFechaConsigna>='''+@fechaconsigna+''' '
	END	
	ELSE 
	BEGIN
		IF(@fechaconsignaF not in ('','-1')) set @filfechaconsigna=' and  ADcFechaConsigna>='''+@fechaconsigna+''' and ADcFechaConsigna <='''+@fechaconsignaF+''' '
	END
end

-- fechas doc
IF (@fechadoc not in ('','-1') or @fechadocF not in ('','-1')) 
BEGIN
	IF(@fechadocF in ('','-1')) 
	BEGIN
		IF(@fechadoc not in ('','-1')) set @filfechadoc=' and ADcFecha>='''+@fechadoc+''' '
	END
	ELSE 
	BEGIN
		IF(@fechadocF not in ('','-1')) set @filfechadoc=' and  ADcFecha>='''+@fechadoc+''' and ADcFecha <='''+@fechadocF+''' '
	END
END

-- Filtro Concepto
set @filConcepto=' ' 
set @criterio = ' '

if (@CPP not in ('','-1')) 
begin
	set @filConcepto = @filConcepto + ' PPDConcepto='''+@CPP+''' AND '
end

--Filtro de estado de ventas
IF @valorVtaAjust = 0 
BEGIN
	SET @criterio=' (VTDEstado <> 3) '
END
ELSE
BEGIN 	
	SET @criterio=' VTDId IN (SELECT codAgr FROM #vtaAjustadas) AND (VTDEstado <> 3) '
END

IF @disp = 3 
BEGIN
	SET @criterio=@criterio+' AND (VTDEstado = 2) '
END

-- Filtros Generales
SET @filGeneral = ''

if (@pro not in ('','-1')) set @filGeneral = @filGeneral + ' AND ObrObra in ('+@pro+')'

if (@vta not in ('','-1')) set @filGeneral = @filGeneral + ' AND VtDId ='+@vta

if (@ter not in ('','-1')) set @filGeneral = @filGeneral + ' AND TerID ='+@ter


--SE CAMBIAN TODOS LOS CAMPOS LLAMADOS VTDCodInterno POR VTDCodInternoDetalle por el cambio que creo RR en la siguiente lÃƒÂ­nea HD 291419 CFP 04/10/2021

--**********************************************************
-- se crea una tabla temporal en vez de subconsulta
-- ya que demoraba mucho el proceso 
-- RR 15/04/2019
--***********************************************************

declare @sqlSubConsulta nvarchar (MAX) = ''
set @sqlSubConsulta = 'INSERT INTO #t( vtdfecha, VTDDto, VTDDto2, VTDDtoFin, PPDid, VTDVrAdicionales, VTDVrExclusiones, VTDVrSubTot, CPPAfectaVta, ObrObra, ObrNombre, CjtID, CjtNombre, VtDId, TerID, TerNombre, TerNit, VTDCodInternoDetalle, VTDCodInterno, TCoId, TCoDesc, Valor, ADcFechaConsigna, ADCFecha,
				UnidPartes, Direccion, AMADesc, Telefono, vendedor, encargo)
				SELECT	VTDFecha, ISNULL(VTDDto,0) as VTDDto ,ISNULL(VTDDto2,0) as VTDDto2 , ISNULL(VTDDtoFin,0) as VTDDtoFin, ADIPlanPagosDet.PPDID, ISNULL(ADIVentasTerDoc.VTDVrAdicionales, 0) AS VTDVrAdicionales, ISNULL(ADIVentasTerDoc.VTDVrExclusiones, 0) AS VTDVrExclusiones, 
				ISNULL(ADIVentasTerDoc.VTDVrSubTot, 0) AS VTDVrSubTot, ADIConceptosPlanPagos.CPPAfectaVta, #sociedades.ObrObra, 
                #sociedades.ObrNombre, #sociedades.CjtID, #sociedades.CjtNombre, ADIVentasTerDoc.VTDID, Terceros.TerID, Terceros.TerNombre, Terceros.TerNit,
                ADIVentasTerDoc.VTDCodInternoDetalle, ADIVentasTerDoc.VTDCodInterno, ADITipoConceptosPP.TCoId, ADITipoConceptosPP.TCoDesc, ADIPlanPagosDet.PPDValor AS Valor,
				'''' as ADcFechaConsigna,'''' as ADCFecha, VTDCodInternoDetalle as UnidPartes, CASE WHEN TerNotifica = 1 THEN TerDireccionOf ELSE TerDireccion END as Direccion, 
				''N/A'' as AMADesc,  
				ISNULL(Terceros.TerCelular,'''')+'' ''+ISNULL(Terceros.TerTelefono,'''')+'' ''+ISNULL(Terceros.TerTel2,'''') as Telefono, ISNULL(ADIComisionistas.CoNombre,'''')+'' ''+ISNULL(ADIComisionistas.CoApellido,'''') as vendedor,
				VTDEncargoNo			
         FROM	ADIVentasTerDoc INNER JOIN ADIPlanPagos ON ADIPlanPagos.PPaAgrupaVenta = ADIVentasTerDoc.VTDID INNER JOIN ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo 
				INNER JOIN ADIConceptosPlanPagos ON ADIPlanPagosDet.PPDConcepto = ADIConceptosPlanPagos.CPPId INNER JOIN #sociedades ON ADIVentasTerDoc.VTDProyecto = #sociedades.ObrObra 
				INNER JOIN Terceros ON ADIVentasTerDoc.VTDTercero = Terceros.TerID INNER JOIN ADITipoConceptosPP ON ADIConceptosPlanPagos.CPPTipo = ADITipoConceptosPP.TCoId 
				LEFT OUTER JOIN ADIComisionistas ON ADIVentasTerDoc.VTDComisionista = ADIComisionistas.CoId  
		 WHERE '+@filConcepto+' '+@criterio+'  AND ADIPlanPagosDet.PPDEstado = 0  AND CjtID = '+ @macro +' '+ @filGeneral +''
 
 exec (@sqlSubConsulta)

--**********************************************************
-- se crea una tabla temporal en vez de subconsulta
-- ya que demoraba mucho el proceso 
-- RR 15/04/2019
--***********************************************************


SET @SqlATIni='
INSERT INTO #PrincipalTIni( PPDId, VTDVrAdicionales, VTDVrExclusiones, VTDVrSubTot, CPPAfectaVta, ObrObra, ObrNombre, CjtID, CjtNombre, VtDId, TerID, TerNombre, TerNit,
							VTDCodInternoDetalle, VTDCodInterno, encargo, TCoId, TCoDesc,  Valor, PP, PPNC, VTDFecha, FechaCons,FechaDoc,PPNCna,
							UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDDto2  )
SELECT	T.PPDId, T.VTDVrAdicionales, T.VTDVrExclusiones, T.VTDVrSubTot, T.CPPAfectaVta, T.ObrObra, T.ObrNombre, T.CjtID, T.CjtNombre, T.VTDID, T.TerID, T.TerNombre, T.TerNit, 
        T.VTDCodInternoDetalle, T.VTDCodInterno, T.encargo, T.TCoId, T.TCoDesc, T.Valor, SUM(PP.Pagado), SUM(PPNC.Pagado) ,T.VTDFecha,T.ADcFechaConsigna , T.ADcFecha, SUM(PPNC.Pagadona),
		UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDDto2

FROM	#t AS T LEFT OUTER JOIN	
		 
		 (	SELECT	SUM(CASE WHEN ADcTipo = ''DI'' THEN ADIMov_1.AMvVrTotal ELSE 0 END) AS Pagado, PPDet.PPDID, SUM(CASE WHEN ADcTipo = ''DI'' THEN 0 ELSE ADIMov_1.AMvVrTotal END) AS Pagadona 		 
			FROM	ADIPlanPagosDet AS PPDet INNER JOIN ADIConceptosPlanPagos AS CPP ON PPDet.PPDConcepto = CPP.CPPId    
					INNER JOIN ADIMov AS ADIMov_1 ON PPDet.PPDID = ADIMov_1.AMvPlanPagoDet 
					INNER JOIN ADIDocs ON ADIMov_1.AMvDoc = ADIDocs.ADcID INNER JOIN #sociedades ON ADIDocs.ADcObra = #sociedades.ObrObra 
			WHERE	'+@filConcepto+'  ADcEstado=''C'' AND (PPDet.PPDEstado = 0) AND (ADIDocs.ADcTipo in (''DI'',''DE'')) '+@filfechaconsigna+' '+@filfechadoc+'
			GROUP BY ADcTipo, PPDet.PPDID) AS PPNC ON T.PPDID = PPNC.PPDID LEFT OUTER JOIN 
						
		 (	SELECT	SUM( ADIMov.AMvVrTotal) AS Pagado, PPDet.PPDID
			FROM	ADIPlanPagosDet AS PPDet INNER JOIN ADIConceptosPlanPagos AS CPP ON PPDet.PPDConcepto = CPP.CPPId 
			INNER JOIN ADIMov  ON PPDet.PPDID = ADIMov.AMvPlanPagoDet INNER JOIN ADIDocs ON ADIMov.AMvDoc = ADIDocs.ADcID  
			/*INNER JOIN #sociedades ON ADIDocs.ADcObra = #sociedades.ObrObra*/ 
			WHERE  '+@filConcepto+' ADcEstado IN (''C'') and (ADIDocs.ADcTipo <> CASE WHEN CPP.CPPAfectaVta=1 THEN ''DI'' ELSE ''DE'' END '+@filfechaconsigna+' '+@filfechadoc+') 
			GROUP BY PPDet.PPDID) AS PP ON T.PPDID = PP.PPDID '


SET @SqlATIni = @SqlATIni + ' GROUP BY T.PPDID,T.VTDVrAdicionales,T.VTDVrExclusiones,T.VTDVrSubTot,T.CPPAfectaVta,T.ObrObra,T.ObrNombre,T.CjtID,T.CjtNombre,T.VTDID,T.TerID,T.TerNombre,T.TerNit,T.VTDCodInternoDetalle,t.VTDCodInterno,T.encargo,T.TCoId,T.TCoDesc,T.Valor,T.VTDFecha,T.ADcFechaConsigna,T.ADcFecha, UnidPartes,Direccion,AMADesc,Telefono,vendedor,VTDDto,VTDDtoFin,VTDDto2'

--PRINT(@SqlATIni)
 
EXEC(@SqlATIni)

 
-- OU_ADICarteraProCliEdades_23 @macro='15', @pro='-1', @vta='-1', @ter='-1', @FIodsF='', @FFodsF='', @FIescF='', @FFescF='', @FIentF='', @FFentF='', @FIaplF='', @FFaplF='', @fechaconsigna='', @fechaconsignaF='', @fechadoc='', @fechadocF='', @CPP='-1', @disp='-1', @prin='0', @usu='50', @sociedad='3', @empresa='1', @valorVtaAjust='0', @PivotEdad='0', @FechaCorteProg='30/06/2015'
  

/*------------------------------
	 CONSULTA PRINCIPAL
--------------------------------*/
set @SqlA= ' 



INSERT INTO #Principal( ObrObra, ObrNombre, CjtID, CjtNombre, VtDId,TerID, TerNombre, TerNit, VTDCodInternoDetalle,VTDCodInterno, encargo,TCoId, TCoDesc, Valor, Pagado,
						FIods , FFods , FIesc , FFesc , FIent , FFent, FIapl ,FFapl,
						pagadoNC, CPPAfectaVta, cantMac, cantObr,   VTDVrAdicionales, VTDVrExclusiones, 
						VTDVrSubTot, PPNCna, UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDFecha, VTDDto2 
					  )
SELECT	Prin.ObrObra, Prin.ObrNombre, Prin.CjtID, Prin.CjtNombre, Prin.VtDId, Prin.TerID, Prin.TerNombre, Prin.TerNit, Prin.VTDCodInternoDetalle, Prin.VTDCodInterno, Prin.encargo, Prin.TCoId, Prin.TCoDesc, (ISNULL(Prin.Valor,0)) as Valor, SUM(ISNULL( Prin.PP,0)) as PP , 
		ODS.TVDFechaI, ODS.TVDFechaF, ESC.TVDFechaI, ESC.TVDFechaF, ENT.TVDFechaI, ENT.TVDFechaF, APL.TVDFechaI, APL.TVDFechaF, 
		SUM(ISNULL(Prin.PPNC,0)) AS PagoNC, CPPAfectaVta, CantConj.Cant, CantObra.Cant , ISNULL(VTDVrAdicionales,0) as VTDVrAdicionales, ISNULL(VTDVrExclusiones,0) AS  VTDVrExclusiones, 
		ISNULL(VTDVrSubTot,0) as VTDVrSubTot, SUM(ISNULL(Prin.PPNCna,0)) ,UnidPartes, Direccion, AMADesc, Telefono,  vendedor, ISNULL(VTDDto, 0) , ISNULL(VTDDtoFin, 0), Prin.VTDFecha, ISNULL(VTDDto2, 0)
FROM   (SELECT  VTDVrAdicionales,PPDid, VTDVrExclusiones, VTDVrSubTot, CPPAfectaVta, ObrObra, ObrNombre, CjtID, CjtNombre, VtDId, 
				TerID, TerNombre, TerNit, VTDCodInternoDetalle, VTDCodInterno,  encargo, TCoId, TCoDesc,  Valor as Valor ,  SUM(PP)  as PP, (PPNC) as PPNC, VTDFecha, (FechaCons) as FechaCons,
				FechaDoc ,(PPNCna) as PPNCna, UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDDto2
		FROM	#PrincipalTIni 
		GROUP BY VTDVrAdicionales,PPDid, VTDVrExclusiones, VTDVrSubTot, CPPAfectaVta, ObrObra, ObrNombre, CjtID, CjtNombre, VtDId, 
		TerID, TerNombre, TerNit, VTDCodInternoDetalle, VTDCodInterno, encargo, TCoId, TCoDesc,  Valor  ,  VTDFecha, (FechaCons) ,FechaDoc,PPNC,PPNCna  ,UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDDto2
		) Prin 

		LEFT OUTER JOIN
		(SELECT  COUNT(*) AS Cant, ADPObras.ObrConjunto 
		 FROM    ADIVentasTerDoc INNER JOIN
				ADPObras ON ADIVentasTerDoc.VTDProyecto = ADPObras.ObrObra
		 WHERE	VTDID in (SELECT #PrincipalTIni.VTDId FROM  #PrincipalTIni  GROUP BY #PrincipalTIni.VTDId) GROUP BY ADPObras.ObrConjunto
		) CantConj ON Prin.CjtID = CantConj.ObrConjunto 

		LEFT OUTER JOIN
		(SELECT  COUNT(*) AS Cant, VTDProyecto
		 FROM	ADIVentasTerDoc
		 WHERE	VTDID IN (SELECT #PrincipalTIni.VTDId FROM  #PrincipalTIni GROUP BY #PrincipalTIni.VTDId) GROUP BY ADIVentasTerDoc.VTDProyecto
		) CantObra ON Prin.ObrObra = CantObra.VTDProyecto

		LEFT OUTER JOIN
		(SELECT #TramitesFechasODS.TVDFechaI, #TramitesFechasODS.TVDFechaF, #TramitesFechasODS.TVtDocVenta FROM #TramitesFechasODS) ODS ON Prin.VtDId = ODS.TVtDocVenta 
		
		LEFT OUTER JOIN
		(SELECT #TramitesFechasAPL.TVDFechaI, #TramitesFechasAPL.TVDFechaF, #TramitesFechasAPL.TVtDocVenta FROM #TramitesFechasAPL ) APL ON Prin.VtDId = APL.TVtDocVenta 
		
		LEFT OUTER JOIN
		(SELECT #TramitesFechasESC.TVDFechaI, #TramitesFechasESC.TVDFechaF, #TramitesFechasESC.TVtDocVenta FROM  #TramitesFechasESC ) ESC ON Prin.VtDId = ESC.TVtDocVenta 
		
		LEFT OUTER JOIN
		(SELECT #TramitesFechasENT.TVDFechaI, #TramitesFechasENT.TVDFechaF, #TramitesFechasENT.TVtDocVenta FROM  #TramitesFechasENT ) ENT ON Prin.VtDId = ENT.TVtDocVenta
WHERE	Prin.CjtID='+@macro

if (@pro not in ('','-1')) set @SqlA = @SqlA+' AND Prin.ObrObra in ('+@pro+')'

if (@vta not in ('','-1')) set @SqlA = @SqlA+' AND Prin.VtDId ='+@vta

if (@ter not in ('','-1')) set @SqlA = @SqlA+' AND Prin.TerID ='+@ter

set @SqlA = @SqlA+' 
GROUP BY ( ISNULL(Prin.Valor,0)), Prin.ObrObra, Prin.ObrNombre, Prin.CjtID, Prin.CjtNombre, Prin.VtDId, Prin.TerID, Prin.TerNombre, Prin.TerNit, Prin.VTDCodInternoDetalle, Prin.VTDCodInterno, Prin.encargo,Prin.TCoId, Prin.TCoDesc, 
                      ODS.TVDFechaI, ODS.TVDFechaF, ESC.TVDFechaI, ESC.TVDFechaF, ENT.TVDFechaI, ENT.TVDFechaF, APL.TVDFechaI, 
                      APL.TVDFechaF,Prin.VTDFecha,  CPPAfectaVta, CantConj.Cant, CantObra.Cant,Prin.PPDid , ISNULL(VTDVrAdicionales,0) , ISNULL(VTDVrExclusiones,0) , ISNULL(VTDVrSubTot,0),UnidPartes, Direccion, AMADesc, Telefono,  vendedor, ISNULL(VTDDto, 0) , ISNULL(VTDDtoFin, 0), ISNULL(VTDDto2, 0)
'
EXECUTE  sp_executesql @SqlA

 -- desarrollo de grama para obtener la primer fecha de bloqueo RR 24/10/2018

declare @CFG_Fecha int
set @CFG_Fecha=ISNULL( ADI.JAP_ADI_ADIConfigEmpresa('ADI_Fecha_InfVenta_Grama', @empresa ) , 0) 

if(@CFG_Fecha = 1)
begin
	
	select	max(LogID) as idlogvta, VtDId as idventa
	into #maxidlogventa
	from	adilog
			inner join #Principal on logvta = VtDId							
	where	Logtipo = 0
	group by VtDId

	--select * from #maxidlogventa

	select	min(logfechareal) as primerfechabloqeuo, logvta
	into #fechasbloqueo
	from	adilog
			inner join #maxidlogventa on logvta = idventa
	where	logtipo = 29 and logid > idlogvta
	group by logvta

	--select * from #fechasbloqueo

	--select	* from #Principal

	update	#Principal
	set		VTDFecha = null

	UPDATE	#Principal
	SET		#Principal.VTDFecha =ISNULL(convert(varchar(11),primerfechabloqeuo,103),'')
	FROM	#Principal 
			INNER JOIN #fechasbloqueo ON #Principal.VtDId = #fechasbloqueo.logvta	

end

-- desarrollo de grama para obtener la primer fecha de bloqueo RR 24/10/2018

 

set @SqlAfectaVta='
INSERT INTO #PrincipalF (
	VTDFecha,
	ObrObra,
	ObrNombre,
	CjtID,
	CjtNombre,
	TerID,
	TerNombre,
	TerNit,
	VTDCodInternoDetalle,
	VTDCodInterno,
	encargo,
	TCoDesc,
	TCoId,
	Valor,
	CPPAfectaVta,
	ValorAfec,
	Pagado,
	PagadoNC,
	PagadoAfec,
	PagadoNCAfec,
	cantMac,
	cantObr,
	VTDVrAdicionales,
	VTDVrExclusiones,
	VTDVrSubTot,
	UnidPartes,
	Direccion,
	AMADesc,
	Telefono,
	vendedor,
	VTDDto,
	VTDDtoFin,
	VTDDto2
)
SELECT 
	VTDFecha,
	ObrObra, 
	ObrNombre, 
	CjtID, 
	CjtNombre, 
	TerID, 
	TerNombre, 
	TerNit, 
	VTDCodInternoDetalle,
	VTDCodInterno,
	encargo,
	TCoDesc,
	TCoId,
	ISNULL(CASE WHEN CPPAfectaVta=0 THEN SUM(Valor) ELSE 0 END,0.00)  as Valor,
	CPPAfectaVta,ISNULL(CASE WHEN CPPAfectaVta=1 THEN SUM(Valor) ELSE 0 END,0.00)  as ValorAfec,
	ISNULL(CASE WHEN CPPAfectaVta=0 THEN SUM(pagado) ELSE 0 END,0) as Pagado,
	ISNULL(CASE WHEN CPPAfectaVta=0 THEN SUM(PPNCna) ELSE 0 END,0) as PagadoNC,
	ISNULL(CASE WHEN CPPAfectaVta=1 THEN SUM(pagado) ELSE 0 END,0) as PagadoAfec,
	ISNULL(CASE WHEN CPPAfectaVta=1 THEN SUM(pagadoNC) ELSE 0 END,0) as PagadoNCAfec,
	cantMac, 
	cantObr,
	VTDVrAdicionales,
	VTDVrExclusiones,
	VTDVrSubTot,
	UnidPartes,
	Direccion,
	AMADesc,
	Telefono,
	vendedor,
	VTDDto,
	VTDDtoFin,
	VTDDto2
FROM #Principal  
WHERE 1=1 '


if (@FIodsF not in ('','-1') or @FFodsF not in ('','-1')) set @SqlAfectaVta = @SqlAfectaVta+' and FFods between '''+@FIodsF+''' and '''+@FFodsF+''''

if (@FIescF not in ('','-1') or @FFescF not in ('','-1')) set @SqlAfectaVta = @SqlAfectaVta+' and FFesc between '''+@FIescF+''' and '''+@FFescF+''''

if (@FIentF not in ('','-1') or @FFentF not in ('','-1')) set @SqlAfectaVta = @SqlAfectaVta+' and FFent between '''+@FIentF+''' and '''+@FFentF+''''

if (@FIaplF not in ('','-1') or @FFaplF not in ('','-1')) set @SqlAfectaVta = @SqlAfectaVta+' and FIapl between '''+@FIaplF+''' and '''+@FFaplF+''''

set @SqlAfectaVta = @SqlAfectaVta + ' GROUP BY VTDFecha,Pagado,PagadoNC, ObrObra, ObrNombre, CjtID, CjtNombre, TerID, TerNombre, TerNit, VTDCodInternoDetalle,VTDCodInterno, encargo,TCoDesc,TCoId , CPPAfectaVta, cantMac, cantObr, VTDVrAdicionales, VTDVrExclusiones, VTDVrSubTot,UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDtoFin, VTDDto2
Order by CjtNombre,ObrNombre,VTDCodInternoDetalle 

'

EXECUTE  sp_executesql @SqlAfectaVta
 



--print(@SqlAfectaVta)
--EXECUTE  sp_executesql @SqlA
 

/*-----------******************************************************************************************************************--------------------------------
													       C O N S U L T A     F I N A L 
-----------******************************************************************************************************************--------------------------------*/
declare @cons nvarchar(max), @tipoId VARCHAR(10), @tipoDesc VARCHAR(50), @compute nvarchar(max), @UptAfectaVtaTot nvarchar(max), @UptNoAfectaVtaTot nvarchar(max)
,@PagadoAfec money,@Pagado money,@ValorAfec money,@Valor money,@PagadoNCAfec money,@PagadoNC money

SET @cons='select VTDFecha,VTDVrAdicionales, VTDVrExclusiones, VTDVrSubTot, cantMac, cantObr, ObrObra, ObrNombre, CjtID, CjtNombre, TerID, TerNombre, TerNit, VTDCodInternoDetalle, ISNULL(VTDCodInterno,VTDCodInternoDetalle) AS VTDCodInterno, encargo,UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto , VTDDto2, VTDDtoFin, '
 
SET @UptNoAfectaVtaTot = ''
SET @UptAfectaVtaTot = ''

declare rTiposC cursor for
	SELECT DISTINCT TCOid, TCOdesc, SUM(PagadoAfec), SUM(Pagado), SUM(ValorAfec), SUM(Valor), SUM(PagadoNCAfec), SUM(PagadoNC)
	FROM #PrincipalF
	GROUP BY TCOid, TCOdesc
	ORDER BY  tcoid
open rTiposC

fetch next from rTiposC
into @tipoId, @tipoDesc, @PagadoAfec ,@Pagado ,@ValorAfec ,@Valor ,@PagadoNCAfec ,@PagadoNC

WHILE @@fetch_status=0
BEGIN
-- Ingreso valores que afecta y totales vacios
	IF (@ValorAfec>0 or @PagadoAfec>0 or @PagadoNCAfec>0) BEGIN
		
		SET  @cons=@cons+' SUM(CASE WHEN ( TCOid='+@tipoId+' and CPPAfectaVta=1)  THEN valorAfec  else 0 end) as ['+@tipoDesc+'PAAfec], '	
		SET  @cons=@cons+' SUM(CASE WHEN ( TCOid='+@tipoId+' and CPPAfectaVta=1)  THEN pagadoAfec  else 0 end)  as ['+@tipoDesc+'EAAfec] ,  '
		SET  @cons=@cons+' SUM(CASE WHEN ( TCOid='+@tipoId+' and CPPAfectaVta=1)  THEN pagadoNCAfec  else 0 end) as ['+@tipoDesc+'ENAfec],  '--Pagado NC	

		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'POAfec],'
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'PMAfec],'
		
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'EOAfec],'
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'EMAfec],'

		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'ONAfec],'-- Obra NC
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'MNAfec],'-- Macro NC
			

		-- actualizo totales de valores que afectan
		SET @UptAfectaVtaTot = @UptAfectaVtaTot + '

		'
	
	END
	
-- Ingreso valores que no afecta y totales vacios
	IF (@Valor>0 or @Pagado>0 or @PagadoNC>0) BEGIN

		SET  @cons=@cons+' SUM(CASE WHEN (TCOid='+@tipoId+' and CPPAfectaVta=0)  THEN valor  else 0 end)  as ['+@tipoDesc+'PA] ,'
		SET  @cons=@cons+' SUM(CASE WHEN (TCOid='+@tipoId+' and CPPAfectaVta=0)  THEN pagado  else 0 end)  as ['+@tipoDesc+'EA] ,'
		SET  @cons=@cons+' SUM(CASE WHEN (TCOid='+@tipoId+' and CPPAfectaVta=0) THEN pagadoNC  else 0 end)  as ['+@tipoDesc+'EN] ,'--Pagado NC	
		
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'PO],'
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'PM],'
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'EO],'
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'EM],'
 		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'ON],'-- Obra NC
		SET  @cons=@cons+' CAST(0.00 AS MONEY) as ['+@tipoDesc+'MN],'-- Macro NC
	 
		-- Actualizo totales de valores que no afectan
		
		SET @UptNoAfectaVtaTot=@UptNoAfectaVtaTot+ '
	 '
	END
	fetch next from rTiposC
	into @tipoId, @tipoDesc,@PagadoAfec ,@Pagado ,@ValorAfec ,@Valor ,@PagadoNCAfec ,@PagadoNC
END
close rTiposC
deallocate rTiposC

 

SET @cons=@cons+' 1 as orden 
INTO #Ver
from #PrincipalF
group by VTDFecha,ObrObra, ObrNombre, CjtID, CjtNombre, TerID, TerNombre, TerNit, VTDCodInternoDetalle,VTDCodInterno, encargo, cantMac, cantObr, VTDVrAdicionales, VTDVrExclusiones, VTDVrSubTot,UnidPartes, Direccion, AMADesc, Telefono,  vendedor, VTDDto, VTDDto2 , VTDDtoFin
ORDER by CjtNombre, ObrNombre, VTDCodInternoDetalle
'

/*---------------------------
	UNIDADES DISPONIBLES
-----------------------------*/
 Declare @SqlAdis nvarchar (3000) , @dispWhere nvarchar (300)

 SET @SqlAdis=' '
 SET @dispWhere=' '
 
 if(@disp <> '1' AND @disp <> '3')
 BEGIN

	SET @SqlAdis=' INSERT INTO #Ver( TerNombre, TerID, ObrNombre, ObrObra, VTDVrSubTot, CjtNombre, CjtID, VTDCodInternoDetalle, VTDCodInterno, orden)
	SELECT      ''D I S P O N I B L E'', VTDTercero, #sociedades.ObrNombre, #sociedades.ObrObra, ADIUnidades.IUnValor, #sociedades.CjtNombre, #sociedades.CjtID, 
						  ADITipoUnidad.TuAbr+''-''+IUnAlterno, ADITipoUnidad.TuAbr+''-''+IUnAlterno, 0
	FROM         ADIProyTipoUnd INNER JOIN
	#sociedades ON ADIProyTipoUnd.UnProyecto = #sociedades.ObrObra INNER JOIN	
	ADIUnidades ON ADIProyTipoUnd.UnId = ADIUnidades.IUnTipoUnidad INNER JOIN
	ADITipoUnidad ON ADIProyTipoUnd.UnTipo = ADITipoUnidad.TUId LEFT OUTER JOIN
	ADIVentasTerDoc INNER JOIN
	ADIVentasTer ON ADIVentasTerDoc.VTDID = ADIVentasTer.VtTDoc ON ADIUnidades.IUnID = ADIVentasTer.VtTUnidad AND VTDEstado<>3
	WHERE     (ADIVentasTerDoc.VTDTercero IS NULL)  AND #sociedades.CjtID ='+@macro

	IF (@pro not in ('','-1')) SET @SqlAdis = @SqlAdis+' AND #sociedades.ObrObra in ('+@pro+')'

	IF (@prin not in ('','-1')) SET @SqlAdis = @SqlAdis+' AND ADIProyTipoUnd.UnComision = 1 ' 
  
-- Filtro de Disponibles.
	IF (@disp not in ('','-1')) BEGIN
		IF (@disp in ('1')) BEGIN
		 SET @dispWhere=' WHERE TerID IS NOT NULL '
		END

		IF (@disp in ('2')) BEGIN
		 SET @dispWhere=' WHERE TerID IS NULL '
		END

	END

END

/*----------------------------------
  CARTERAS VENCIDAS EDADES AFECTAN
-------------------------------------*/
 
declare @consEdad nvarchar(max), @edad VARCHAR(20)
 

          
SET @consEdad = 'SELECT  ObrObra as Ob1, VTDCodInternoDetalle as Vta1,'

CREATE TABLE #PivotVEAfecta (CaEdDesc VARCHAR (100), CaEdID INT)
CREATE TABLE #TCartVencidasI (VTDCodInternoDetalle VARCHAR (500), DescEdad VARCHAR (500), PPDValor MONEY, ADcTotPagar MONEY, CPPAfectaVta INT, ObrObra INT,  Total MONEY )
CREATE TABLE #TCartVencidas (VTDCodInternoDetalle VARCHAR (500), DescEdad VARCHAR (500), PPDValor MONEY, ADcTotPagar MONEY, CPPAfectaVta INT, ObrObra INT,  Total MONEY )

IF (@fechaconsignaF = '' OR @fechaconsignaF IS NULL)  SET @fechaconsignaF = '01/01/2050' 

IF (@PivotEdad = '0') BEGIN

	INSERT INTO #TCartVencidas ( VTDCodInternoDetalle, DescEdad, PPDValor, ADcTotPagar, CPPAfectaVta, ObrObra,  Total)
	SELECT     VTDCodInternoDetalle, (SELECT CaEdDESC FROM ADICarteraEdades WHERE DATEDIFF(d, PPDFecha, @FechaCorteProg) BETWEEN CaEdMesI AND CaEdMesF) AS DescEdad, ADIPlanPagosDet.PPDValor, 
			   SUM( AMvVrTotal ) as ADcTotPagar, CPPAfectaVta, ObrObra , ISNULL(PPDValor,0)-SUM(ISNULL(AMvVrTotal,0)) as Total5
	FROM       ADIConceptosPlanPagos INNER JOIN
						  ADPObras INNER JOIN
						  ADIVentasTerDoc ON ADPObras.ObrObra = ADIVentasTerDoc.VTDProyecto INNER JOIN
						  ADIPlanPagos ON ADIVentasTerDoc.VTDID = ADIPlanPagos.PPaAgrupaVenta INNER JOIN
						  ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo ON ADIConceptosPlanPagos.CPPId = ADIPlanPagosDet.PPDConcepto LEFT OUTER JOIN
						  ADIDocs INNER JOIN
						  ADIMov ON ADIDocs.ADcID = ADIMov.AMvDoc ON ADIPlanPagosDet.PPDID = ADIMov.AMvPlanPagoDet AND (ADIDocs.ADcEstado IN('C')) AND (ADIDocs.ADcTipo <> 'RN')  AND ADcFechaConsigna <= @fechaconsignaF 
	WHERE     (ADIVentasTerDoc.VTDId  IN (SELECT VTDId FROM #Principal))  AND (ADIPlanPagosDet.PPDEstado = 0) AND (ADIPlanPagosDet.PPDFecha < cast((convert(varchar,@FechaCorteProg,103)) as smalldatetime) ) AND (ADIVentasTerDoc.VTDEstado <> 3)  
		AND ADIPlanPagosDet.PPdConcepto <> '-2' 
	GROUP BY  ADIVentasTerDoc.VTDCodInternoDetalle,  ADIPlanPagosDet.PPDValor, PPDFecha,
			  CPPAfectaVta,ObrObra,PPDID


	
	INSERT INTO #PivotVEAfecta (CaEdDesc, CaEdID)
	SELECT   CaEdDesc, CaEdID
	FROM     ADICarteraEdades
 
 
END ELSE BEGIN

	INSERT INTO #TCartVencidasI ( VTDCodInternoDetalle, DescEdad, PPDValor, ADcTotPagar, CPPAfectaVta, ObrObra,  Total)
	SELECT     ADIVentasTerDoc.VTDCodInternoDetalle, ADITipoConceptosPP.TCoDesc AS DescEdad, ADIPlanPagosDet.PPDValor, SUM( AMvVrTotal ) as ADcTotPagar, ADIConceptosPlanPagos.CPPAfectaVta, ADPObras.ObrObra , ISNULL(PPDValor,0)-SUM(ISNULL(AMvVrTotal,0)) as Total   
	FROM            dbo.ADIConceptosPlanPagos INNER JOIN
                         dbo.ADPObras INNER JOIN
                         dbo.ADIVentasTerDoc ON ADPObras.ObrObra = ADIVentasTerDoc.VTDProyecto INNER JOIN
                         dbo.ADIPlanPagos ON ADIVentasTerDoc.VTDID = ADIPlanPagos.PPaAgrupaVenta INNER JOIN
                         dbo.ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo ON ADIConceptosPlanPagos.CPPId = ADIPlanPagosDet.PPDConcepto INNER JOIN
                         dbo.ADITipoConceptosPP ON dbo.ADIConceptosPlanPagos.CPPTipo = dbo.ADITipoConceptosPP.TCoId LEFT OUTER JOIN
                         dbo.ADIDocs INNER JOIN
                         dbo.ADIMov ON ADIDocs.ADcID = ADIMov.AMvDoc ON ADIPlanPagosDet.PPDID = ADIMov.AMvPlanPagoDet AND ADIDocs.ADcEstado IN ('C') AND ADIDocs.ADcTipo <> 'RN'  AND ADcFechaConsigna <= @fechaconsignaF 					
	WHERE    (ADIPlanPagosDet.PPDEstado = 0) 
			AND (ADIVentasTerDoc.VTDEstado <> 3) AND (ADIPlanPagosDet.PPDFecha < cast((convert(varchar,@FechaCorteProg,103)) as smalldatetime) )  AND ADIVentasTerDoc.VTDId IN (select #Principal.VTDId from #Principal group by VTDId )  AND ADIPlanPagosDet.PPdConcepto <> '-2'
	GROUP BY  ADIVentasTerDoc.VTDCodInternoDetalle,  ADIPlanPagosDet.PPDValor, 
			  ADIConceptosPlanPagos.CPPAfectaVta, ADPObras.ObrObra, PPDID, ADITipoConceptosPP.TCoDesc

	
	INSERT INTO #TCartVencidas ( VTDCodInternoDetalle, DescEdad, PPDValor, ADcTotPagar, CPPAfectaVta, ObrObra,  Total)
	SELECT  VTDCodInternoDetalle, DescEdad, SUM(PPDValor), SUM(ADcTotPagar), CPPAfectaVta, ObrObra,  SUM(Total)
	FROM #TCartVencidasI 
	GROUP BY  VTDCodInternoDetalle, DescEdad, CPPAfectaVta, ObrObra


	INSERT INTO #PivotVEAfecta (CaEdDesc, CaEdID)
	SELECT   TCoDesc, TCoId
	FROM     ADITipoConceptosPP

END
 

-- CURSOR DEUDA
declare rFlujo cursor for

	SELECT   CaEdDesc
	FROM     #PivotVEAfecta
	GROUP BY CaEdDesc,CaEdID
	ORDER BY CaEdID
	
open rFlujo

FETCH NEXT FROM rFlujo
INTO  @edad
WHILE @@fetch_status=0
BEGIN

	SET  @consEdad=@consEdad+'(SUM(CASE WHEN (DescEdad ='''+@edad+''' and (ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0))<>0) THEN (ISNULL((ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0)),0)) ELSE 0 END))  as ['+REPLACE(@edad,'-',' a ')+'$],'

	
	FETCH NEXT FROM rFlujo
	INTO  @edad
END
CLOSE rFlujo
DEALLOCATE rFlujo
 
SET @consEdad=@consEdad+'SUM(Total) as [Total$], 1 as Fin Into #VerEdadesAfecta FROM #TCartVencidas WHERE CPPAfectaVta = 1 GROUP BY ObrObra, VTDCodInternoDetalle'



/*-------------------------------
CARTERA VENCIDA EDADES NO AFECTA
---------------------------------*/
declare @consEdadNF nvarchar(max), @edadNF VARCHAR(20)

  SET @consEdadNF = ' SELECT  ObrObra as Ob2, VTDCodInternoDetalle as Vta2,  '

-- CURSOR DEUDA
declare rFlujo cursor for

	SELECT   CaEdDesc
	FROM     #PivotVEAfecta
	GROUP BY CaEdDesc,CaEdID
	ORDER BY CaEdID
	
open rFlujo

FETCH NEXT FROM rFlujo
INTO  @edadNF
WHILE @@fetch_status=0
BEGIN	

	SET  @consEdadNF=@consEdadNF+' (SUM(CASE WHEN (DescEdad='''+@edadNF+''' and (ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0))<>0) THEN (ISNULL((ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0)),0)) ELSE 0 END))  as ['+REPLACE(@edadNF,'-',' a ')+'?] ,'

	FETCH NEXT FROM rFlujo
	INTO  @edadNF
END
CLOSE rFlujo
DEALLOCATE rFlujo
 
SET @consEdadNF = @consEdadNF + ' SUM(Total) as [Total?], 1 as Fin Into #VerEdadesNoAfecta  FROM   #TCartVencidas WHERE CPPAfectaVta = 0 GROUP BY ObrObra, VTDCodInternoDetalle '

/*----------------------
	TRAMITES ESC Y PRM
------------------------*/

declare @consTramiteESC nvarchar(max), @consTramitePRM nvarchar(max)

SET @consTramiteESC = ''
SET @consTramitePRM = ''

-- PRIMERO ESC SEGUN PROMESA
SET @consTramiteESC = @consTramiteESC+' 
SELECT VTDProyecto as Ob6, VTDCodInternoDetalle as Vta6,  DATEDIFF(d, ADITramitesVentaDet.TVDFechaI, ADITramitesVentaDet.TVDFechaF) AS EscDur, ADITramitesVentaDet.TVDFechaI AS EscFI, ADITramitesVentaDet.TVDFechaF AS EscFF 
INTO #TTramitesEsc FROM ADITramitesConfig INNER JOIN
ADITramites ON ADITramitesConfig.TCfTramite = ADITramites.TraID INNER JOIN
ADIVentasTerDoc INNER JOIN
ADITramitesVenta ON ADIVentasTerDoc.VTDID = ADITramitesVenta.TVtDocVenta INNER JOIN
ADITramitesVentaDet ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite
WHERE     (ADITramitesConfig.TCfId = ''ESC'') AND (ADIVentasTerDoc.VTDEstado <> 3) AND ADITramitesVentaDet.TVDotroSi=0 '    

SET @consTramitePRM = @consTramitePRM+' 
SELECT VTDProyecto as Ob5, VTDCodInternoDetalle as Vta5, DATEDIFF(d, ADITramitesVentaDet.TVDFechaI, ADITramitesVentaDet.TVDFechaF) AS ProDur, 
ADITramitesVentaDet.TVDFechaI AS ProFI, ADITramitesVentaDet.TVDFechaF AS ProFF INTO #TTramitesPrm
FROM ADITramitesConfig INNER JOIN ADITramites ON ADITramitesConfig.TCfTramite = ADITramites.TraID INNER JOIN
ADIVentasTerDoc INNER JOIN ADITramitesVenta ON ADIVentasTerDoc.VTDID = ADITramitesVenta.TVtDocVenta INNER JOIN ADITramitesVentaDet 
ON ADITramitesVentaDet.TVDTrVentaID = ADITramitesVenta.TVtID ON ADITramites.TraID = ADITramitesVentaDet.TVDCodTramite
WHERE (ADITramitesConfig.TCfId = ''PRM'')  AND (ADIVentasTerDoc.VTDEstado <> 3) AND ADITramitesVentaDet.TVDotroSi=0 '    

/*----------------------------------
  CARTERAS CORRIENTE EDADES AFECTAN
-------------------------------------*/

declare @consEdadCorriente nvarchar(max), @MesCorriente VARCHAR(100), @AnoCorriente VARCHAR(20)

IF (@PivotEdad = '0') 
BEGIN

	SELECT     ADIVentasTerDoc.VTDCodInternoDetalle, PPDFecha, ADIPlanPagosDet.PPDValor, SUM( AMvVrTotal ) as ADcTotPagar, CPPAfectaVta, ObrObra,  ISNULL(PPDValor,0)-SUM(ISNULL(AMvVrTotal,0))  as Total INTO #TCartCorriente
	FROM       ADIConceptosPlanPagos INNER JOIN
						  ADPObras INNER JOIN
						  ADIVentasTerDoc ON ADPObras.ObrObra = ADIVentasTerDoc.VTDProyecto INNER JOIN
						  ADIPlanPagos ON ADIVentasTerDoc.VTDID = ADIPlanPagos.PPaAgrupaVenta INNER JOIN
						  ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo ON ADIConceptosPlanPagos.CPPId = ADIPlanPagosDet.PPDConcepto LEFT OUTER JOIN
						  ADIDocs INNER JOIN
						  ADIMov ON ADIDocs.ADcID = ADIMov.AMvDoc ON ADIPlanPagosDet.PPDID = ADIMov.AMvPlanPagoDet AND (ADIDocs.ADcEstado IN ('C')) AND (ADIDocs.ADcTipo <> 'RN')  AND ADcFechaConsigna <= @fechaconsignaF 
	WHERE     (ADIPlanPagosDet.PPDEstado = 0) AND (ADIPlanPagosDet.PPDFecha >= cast((convert(varchar,@FechaCorteProg,103)) as smalldatetime) ) AND (ADIVentasTerDoc.VTDEstado <> 3)  
					AND ADIPlanPagosDet.PPdConcepto <> '-2' AND ADIVentasTerDoc.VTDId IN (select #Principal.VTDId from #Principal group by VTDId )   
	GROUP BY  ADIVentasTerDoc.VTDCodInternoDetalle,  ADIPlanPagosDet.PPDValor, PPDFecha,   CPPAfectaVta, ObrObra, PPDID

	SET @consEdadCorriente = ' SELECT  ObrObra as Ob3, VTDCodInternoDetalle as Vta3,  '

 
	-- CURSOR DEUDA
	declare rFlujo cursor for

	SELECT DATENAME(month,PPDFecha),YEAR(PPDFecha)
	FROM #TCartCorriente
	GROUP BY DATENAME(month,PPDFecha),YEAR(PPDFecha), MONTH(PPDFecha)
	ORDER BY YEAR(PPDFecha), MONTH(PPDFecha)

	open rFlujo

	FETCH NEXT FROM rFlujo
	INTO  @MesCorriente,@AnoCorriente
	WHILE @@fetch_status=0
	BEGIN	

		SET  @consEdadCorriente= ISNULL(@consEdadCorriente,'')+' (SUM(CASE WHEN (DATENAME(month,PPDFecha)='''+@MesCorriente+''' and YEAR(PPDFecha)='''+@AnoCorriente+''' and (ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0))>0) THEN (ISNULL((ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0)),0)) ELSE 0 END))  as ['+LEFT(@MesCorriente,3)+'_'+@AnoCorriente+'¡] ,'

		FETCH NEXT FROM rFlujo
		INTO  @MesCorriente,@AnoCorriente
	END
	CLOSE rFlujo
	DEALLOCATE rFlujo

	
	SET @consEdadCorriente= ISNULL(@consEdadCorriente,'') +' SUM(Total) as [Total¡], 1 as Fin Into #VerEdadesAfectaCorriente  FROM #TCartCorriente WHERE CPPAfectaVta = 1 GROUP BY ObrObra, VTDCodInternoDetalle '
END 
ELSE 
BEGIN

	SELECT     ADIVentasTerDoc.VTDCodInternoDetalle, PPDFecha, ADIPlanPagosDet.PPDValor, SUM( AMvVrTotal ) as ADcTotPagar, ADIConceptosPlanPagos.CPPAfectaVta, ADPObras.ObrObra,  ISNULL(PPDValor,0)-SUM(ISNULL(AMvVrTotal,0))  as Total, ADITipoConceptosPP.TCoDesc INTO #TCartCorrienteCo
	FROM       dbo.ADIConceptosPlanPagos INNER JOIN
                         dbo.ADPObras INNER JOIN
                         dbo.ADIVentasTerDoc ON ADPObras.ObrObra = ADIVentasTerDoc.VTDProyecto INNER JOIN
                         dbo.ADIPlanPagos ON ADIVentasTerDoc.VTDID = ADIPlanPagos.PPaAgrupaVenta INNER JOIN
                         dbo.ADIPlanPagosDet ON ADIPlanPagos.PPaID = ADIPlanPagosDet.PPDPlanPNo ON ADIConceptosPlanPagos.CPPId = ADIPlanPagosDet.PPDConcepto INNER JOIN
                         dbo.ADITipoConceptosPP ON dbo.ADIConceptosPlanPagos.CPPTipo = dbo.ADITipoConceptosPP.TCoId LEFT OUTER JOIN
                         dbo.ADIDocs INNER JOIN
                         dbo.ADIMov ON ADIDocs.ADcID = ADIMov.AMvDoc ON ADIPlanPagosDet.PPDID = ADIMov.AMvPlanPagoDet AND ADIDocs.ADcEstado IN ('C') AND ADIDocs.ADcTipo <> 'RN'  AND ADcFechaConsigna <= @fechaconsignaF
	WHERE   (ADIPlanPagosDet.PPDEstado = 0) AND ADIVentasTerDoc.VTDId IN (select #Principal.VTDId from #Principal group by VTDId ) AND (ADIPlanPagosDet.PPDFecha >= cast((convert(varchar,@FechaCorteProg,103)) as smalldatetime) ) 
	AND (ADIVentasTerDoc.VTDEstado <> 3)    AND ADIPlanPagosDet.PPdConcepto <> '-2'
	GROUP BY  ADIVentasTerDoc.VTDCodInternoDetalle,  ADIPlanPagosDet.PPDValor, PPDFecha, ADIConceptosPlanPagos.CPPAfectaVta,ADPObras.ObrObra,PPDID, ADITipoConceptosPP.TCoDesc

-- OU_ADICarteraProCliEdades @macro='15', @pro='-1', @vta='-1', @ter='-1', @FIodsF='', @FFodsF='', @FIescF='', @FFescF='', @FIentF='', @FFentF='', @FIaplF='', @FFaplF='', @fechaconsigna='', @fechaconsignaF='', @fechadoc='', @fechadocF='', @CPP='-1', @disp='-1', @prin='0', @usu='50', @sociedad='3', @empresa='1', @valorVtaAjust='0', @PivotEdad='1', @FechaCorteProg='28/07/2015'

	SET @consEdadCorriente = ' SELECT  ObrObra as Ob3, VTDCodInternoDetalle as Vta3,  '

	-- CURSOR DEUDA
	declare rFlujo cursor for

	SELECT TCoDesc
	FROM #TCartCorrienteCo
	GROUP BY TCoDesc
	ORDER BY TCoDesc

	open rFlujo

	FETCH NEXT FROM rFlujo
	INTO  @MesCorriente 
	WHILE @@fetch_status=0
	BEGIN	


		--SET  @consEdadCorriente= ISNULL(@consEdadCorriente,'') +' (SUM(CASE WHEN (TCoDesc ='''+ ISNULL(@MesCorriente,'') +'''  and (ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0))>0) THEN (ISNULL((ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0)),0)) ELSE 0 END))  as ['+LEFT(ISNULL(@MesCorriente,''),3)+'_'+ISNULL(@AnoCorriente,'')+'¡] ,'

		SET  @consEdadCorriente= ISNULL(@consEdadCorriente,'') +' (SUM(CASE WHEN (TCoDesc ='''+ ISNULL(@MesCorriente,'') +'''  and (ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0))>0) THEN (ISNULL((ISNULL(PPDValor,0)-ISNULL(ADcTotPagar, 0)),0)) ELSE 0 END))  as ['+ ISNULL(@MesCorriente,'') +'¡] ,'

		FETCH NEXT FROM rFlujo
		INTO  @MesCorriente 
	END
	CLOSE rFlujo
	DEALLOCATE rFlujo

	SET @consEdadCorriente= ISNULL(@consEdadCorriente,'') +' SUM(Total) as [Total¡], 1 as Fin Into #VerEdadesAfectaCorriente  FROM #TCartCorrienteCo WHERE CPPAfectaVta = 1 GROUP BY ObrObra, VTDCodInternoDetalle '

END

 

/*---------
	FIN
-----------*/
SET @UptAfectaVtaTot= LTRIM(RTRIM(@UptAfectaVtaTot))
SET @UptNoAfectaVtaTot= LTRIM(RTRIM(@UptNoAfectaVtaTot))

--PRINT (@cons +   @SqlAdis + @consEdad + @consEdadNF + @consTramiteEsc + @consTramitePrm + @consEdadCorriente + ' SELECT	DISTINCT	[#Ver].*, [#VerEdadesAfecta].*, [#VerEdadesNOAfecta].*, [#TTramitesEsc].*, [#TTramitesPrm].*, [#VerEdadesAfectaCorriente].* 	FROM	[#Ver] LEFT OUTER JOIN [#VerEdadesAfecta] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesAfecta].Vta1 AND [#Ver].ObrObra = [#VerEdadesAfecta].Ob1 LEFT OUTER JOIN [#VerEdadesNOAfecta] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesNOAfecta].Vta2 AND [#Ver].ObrObra = [#VerEdadesNOAfecta].Ob2  LEFT OUTER JOIN [#TTramitesEsc] ON [#Ver].VTDCodInternoDetalle = [#TTramitesEsc].Vta6 AND [#Ver].ObrObra = [#TTramitesEsc].Ob6 LEFT OUTER JOIN [#TTramitesPrm] ON [#Ver].VTDCodInternoDetalle = [#TTramitesPrm].Vta5 AND [#Ver].ObrObra = [#TTramitesPrm].Ob5 LEFT OUTER JOIN [#VerEdadesAfectaCorriente] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesAfectaCorriente].Vta3 AND [#Ver].ObrObra = [#VerEdadesAfectaCorriente].Ob3  '+@dispWhere+' ORDER by [#Ver].CjtNombre, [#Ver].ObrNombre,orden desc, [#Ver].VTDCodInternoDetalle')
EXECUTE (@cons +   @SqlAdis + @consEdad + @consEdadNF + @consTramiteEsc + @consTramitePrm + @consEdadCorriente + ' SELECT	DISTINCT [#Ver].*, [#VerEdadesAfecta].*, [#VerEdadesNOAfecta].*, [#TTramitesEsc].*, [#TTramitesPrm].*, [#VerEdadesAfectaCorriente].* 	FROM	[#Ver] LEFT OUTER JOIN [#VerEdadesAfecta] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesAfecta].Vta1 AND [#Ver].ObrObra = [#VerEdadesAfecta].Ob1 LEFT OUTER JOIN [#VerEdadesNOAfecta] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesNOAfecta].Vta2 AND [#Ver].ObrObra = [#VerEdadesNOAfecta].Ob2  LEFT OUTER JOIN [#TTramitesEsc] ON [#Ver].VTDCodInternoDetalle = [#TTramitesEsc].Vta6 AND [#Ver].ObrObra = [#TTramitesEsc].Ob6 LEFT OUTER JOIN [#TTramitesPrm] ON [#Ver].VTDCodInternoDetalle = [#TTramitesPrm].Vta5 AND [#Ver].ObrObra = [#TTramitesPrm].Ob5 LEFT OUTER JOIN [#VerEdadesAfectaCorriente] ON [#Ver].VTDCodInternoDetalle = [#VerEdadesAfectaCorriente].Vta3 AND [#Ver].ObrObra = [#VerEdadesAfectaCorriente].Ob3  '+@dispWhere+' ORDER by [#Ver].CjtNombre, [#Ver].ObrNombre,orden desc, [#Ver].VTDCodInternoDetalle')
