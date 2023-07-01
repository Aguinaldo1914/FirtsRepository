USE [DW]
GO
/****** Object:  StoredProcedure [XXXXX-XXXX].[TemposXXXXX-XXXXNew]******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [XXXXX-XXXX].[TemposXXXXX-XXXXNew]
AS

-- Projetado por: Aguinaldo Freire da Silva Junior/ Mis - Aguapei
-- Objetivo: Acompanhamento de tempos e intervalos dos operadores
-- Rotina: Diario ás 07h
-- Ultima Atualização: ----------


DECLARE @dDataIni SMALLDATETIME
SET @dDataIni = CASE WHEN DATEPART(WEEKDAY, GETDATE()-1) = 1 THEN CAST(CONVERT(VARCHAR,GETDATE()-2,101) AS SMALLDATETIME)
				     ELSE CAST(CONVERT(VARCHAR,GETDATE()-1,101) AS SMALLDATETIME)END

IF OBJECT_ID('TEMPDB..##TempTempo', N'U') IS NOT NULL DROP TABLE ##TEMPTEMPO
DECLARE @TEMPOS VARCHAR(MAX)
SET @TEMPOS  = 'SELECT DISTINCT
					CAST(NULL AS VARCHAR(50)) AS MediaInstanceLogged
					,CAST(NULL AS VARCHAR(50)) AS MediaReadyTime
					,CAST(NULL AS VARCHAR(50)) AS MediaTalkTime
					,CAST(NULL AS VARCHAR(50)) AS MediaBanheiro
					,CAST(NULL AS VARCHAR(50)) AS MediaLanche
					,CAST(NULL AS VARCHAR(50)) AS MediaDescanso
 				   ,[CODIGOSITE]
				  ,[date]
				  ,[Agent]
				  ,[Fullname]
				  ,[Campaign]
				  ,[Extension]
				  ,[Instance logged time]
				  ,[Instance login]
				  ,[Instance logout]
				  ,[Campaign logged time]
				  ,[Campaign login]
				  ,[Campaign logout]
				  ,[Ready time]
				  ,[Not ready time]
				  ,[Wrapup time]
				  ,[Avg wrapup time]
				  ,[Talk time]
				  ,[Avg talk time]
				  ,[Handled calls]
				  ,[IDLE]
				  ,[IDLE average]
				  ,[Pause time]
				  ,[Pause - Ambulatório]
				  ,[Pause - Banheiro]
				  ,[Pause - Descanso]
				  ,[Pause - Feedback]
				  ,[Pause - Intervalo 20]
				  ,[Pause - Lanche]
				  ,[Pause - Ligação Ativa]
				  ,[Pause - Outra Atividade]
				  ,[Pause - Pausa 10]
				  ,[Pause - Pessoal]
				  ,[Pause - Reunião]
				  ,[Pause - Sistema]
				  ,[Pause - Treinamento]
				  ,[Pause - Clean-up (System)]
				  ,[Pause - Forced (Switch)]
				  ,[Pause - Rotate on error (Switch)]
				  ,[Pause - Rotate on no answer (Switch)]
				  ,[Pause - Sign off (System)]
				  ,[Pause - Unknown (Switch)]
				  ,[Origem]
                          
			INTO ##TEMPTEMPO
			FROM [172.17.1.115].DBDATAHIST'+SUBSTRING (CONVERT(NVARCHAR,@dDataIni ,112) ,1,4)
								+CASE WHEN YEAR(@dDataIni) <= '2020' THEN ''
									  WHEN DATEPART(MM,@dDataIni) IN (1,2,3,4,5,6) THEN '_01Sem' 
									  ELSE '_02Sem' 
								 END
								+'.DBO.TMD_RET_AGT_'+SUBSTRING (CONVERT(NVARCHAR,@dDataIni ,112) ,1,6)+' A (NOLOCK)  
			WHERE 
				 A.DATE = '+''''+CONVERT(NVARCHAR, @dDataIni,120)+''''+ 
				'AND A.CODIGOSITE IN(83, 1)
				AND A.Campaign LIKE ''%XXXXX-XXXX%'''
	EXECUTE (@TEMPOS)



--- Média de Ready Time 

	drop table if exists #MediaGeral
	select
	date,
	agent,

	[instance logged time],
	cast(cast(replace(left([instance logged time],2),':','') as int) * 60 as int) -- horas em minutos
	+ cast(replace(substring([instance logged time],2,4),':','') as int)+ -- minutos
	replace(left(cast(right([instance logged time],2) as float)/60,3),'.','') as i, -- segundos em minutos


	[Ready time],
	cast(cast(replace(left([Ready time],2),':','') as int) * 60 as int)
	+ cast(replace(substring([Ready time],2,4),':','') as int)+
	replace(left(cast(right([Ready time],2) as float)/60,3),'.','') as r,

	[Talk time],
	cast(cast(replace(left([Talk time],2),':','') as int) * 60 as int)
	+ cast(replace(substring([Talk time],2,4),':','') as int)+ 
	replace(left(cast(right([Talk time],2) as float)/60,3),'.','') as t,

	[Pause - Banheiro],
	cast(cast(replace(left([Pause - Banheiro],2),':','') as int) * 60 as int)
	+ cast(replace(substring([Pause - Banheiro],2,4),':','') as int)+ 
	replace(left(cast(right([Pause - Banheiro],2) as float)/60,3),'.','') as pb,
	
	[Pause - Lanche],
	cast(cast(replace(left([Pause - Lanche],2),':','') as int) * 60 as int)
	+ cast(replace(substring([Pause - Lanche],2,4),':','') as int)+ 
	replace(left(cast(right([Pause - Lanche],2) as float)/60,3),'.','') as pl,

	[Pause - Descanso],
	cast(cast(replace(left([Pause - Descanso],2),':','') as int) * 60 as int)
	+ cast(replace(substring([Pause - Descanso],2,4),':','') as int)+ 
	replace(left(cast(right([Pause - Descanso],2) as float)/60,3),'.','') as pd


	into #MediaGeral
	from ##temptempo
	group by 
	date,
	agent,
	[instance logged time],
	[Ready time],
	[Talk time],
	[Pause - Banheiro],
	[Pause - Lanche],
	[Pause - Descanso]


	update a
	set 
	
	a.MediaInstanceLogged =
	(select right('0' + cast(floor(avg(i) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(i) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral),

	a.MediaReadyTime = (select right('0' + cast(floor(avg(r) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(r) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral),

	a.MediaTalkTime = (select right('0' + cast(floor(avg(t) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(t) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral),

	a.MediaBanheiro = (select right('0' + cast(floor(avg(pb) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(pb) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral),

	a.MediaLanche = (select right('0' + cast(floor(avg(pl) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(pl) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral),

	a.MediaDescanso = (select right('0' + cast(floor(avg(pd) / 60) as varchar), 2) 
	+ ':' + right('0' + cast(avg(pd) % 60 as varchar), 2)
	+':00' as hora_formatada
	from #mediageral)

	from ##TEMPTEMPO A


DELETE A FROM [XXXXX-XXXX].[Tempos] A
WHERE DATE = @dDataIni

INSERT INTO [XXXXX-XXXX].[Tempos]
SELECT * FROM  ##TEMPTEMPO