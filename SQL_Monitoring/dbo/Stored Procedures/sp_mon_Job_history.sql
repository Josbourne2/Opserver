




CREATE PROCEDURE [dbo].[sp_mon_Job_history] 
--drop table #test
AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 20-09-2010 A vd Berg
-- 20-04-2011 A vd berg
--	delete from dbo.mon_job_history where rundate < GETDATE () -90
-- 26-09-2011 A vd Berg
--  statusveld numeriek laten zolang als mogelijk is, en ombouwen van datum- en tijdveld via stuff ipv substring.
-- 05-10-2011 A vd Berg
--	controle of linked server inderdaad bestaat, anders exit
-----------------------------------------------------------------------------------------
--=========================================================================


--oude jobhistory verwijderen (ouder dan 90 dagen)

delete from dbo.mon_job_history where rundate < GETDATE () -90



SET XACT_ABORT OFF
SET NOCOUNT ON
SET XACT_ABORT ON
print 'XACT ABORT is ON'



-- declare variabelen
--Declare @Datum nvarchar(20)
Declare @inst nvarchar(64)
Declare @TSQL1 nvarchar(4000)
Declare @TSQL2 nvarchar(4000)
Declare @TSQL3 nvarchar(4000)
Declare @TSQL4 nvarchar(4000)
Declare @TSQL5 nvarchar(4000)
Declare @TSQL6 nvarchar(4000)
Declare @TSQL7 nvarchar(4000)
Declare @TSQL8 nvarchar(4000)
Declare @TSQL9 nvarchar(4000)
Declare @sqlqry nvarchar(4000)
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@instid int,@ver nvarchar(50)
declare @cnt int,@error int
Declare @Linked_server varchar(500)

if exists (select * from tempdb..sysobjects where name = '#jobhist') drop table #jobhist
	
create table #jobhist (
	instance_id	int 
	,job_id uniqueidentifier  
	,status tinyint
	,volgnr bigint
	,rundate varchar(50)
	,runtime varchar(50)
	,runduration varCHAR(8)
	)
	create nonclustered index idx  on #jobhist (instance_id,job_id)




--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 




	select @TSQL3 = '''SELECT  sj.job_id,
	 sjh.run_status as status, 
	sjh.instance_id as volgnr,run_date,
	run_time,
	run_duration
	FROM msdb.dbo.sysjobs sj 
	INNER JOIN msdb.dbo.sysjobhistory sjh
	ON sj.job_id = sjh.job_id
	WHERE 1=1
	AND sj.enabled = 1
	AND sjh.step_id = 0
	AND sjh.run_status <> 4
	AND run_date > cast(YEAR(getdate() -20) as varchar(4)) +  RIGHT(''''0'''' + RTRIM(MONTH(GETDATE() -20)), 2) + ''''00''''
	ORDER BY sjh.run_date '''
	--select @TSQL3 =  '''SELECT  sj.name as jobname,sj.job_id,sj.enabled as job_enabled,js.schedule_id,js.name as schedule_name,js.enabled as schedule_enabled,SUSER_SNAME(sj.owner_sid) as owner ,sj.date_created,sj.date_modified 
	--FROM msdb.dbo.sysjobs sj left outer join msdb.dbo.sysjobschedules js on sj.job_id =js.job_id ''' 
	--select @TSQL3 = @TSQL3 + ') a '
	--select @TSQL3 = @TSQL3 + 'full outer join (select instance_id as md_instance_id, id as md_id, [crdate] as md_createdate ,[dbname] as md_name,status as md_status, server from dbo.Mon_DB where deldate is null and server = '
	--select @TSQL4 = ') md on a.name COLLATE DATABASE_DEFAULT = md.md_name COLLATE DATABASE_DEFAULT '

	--print @tsql3
	-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select node, instance,versie,id 
	from mon_instance 
	where  controle = '1' and isnull(te_bewaken,1)=1  --and  (versie like '7.%' or versie like '6.%' or versie like '20%' )
		--and node ='ZMPDB001.rechtspraak.minjus.nl'
   order by domein, instance,node
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@instid
WHILE @@FETCH_STATUS = 0
	BEGIN
		if @inst = '' or @inst is null set @srvr1 = @srvr
		if @inst <> '' 
		begin
			set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		end

--linked server aanmaken

set @error=0
	if @ver like '7.%' or @ver like '6.%'
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error,@version =7
		END
	else
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error
		END

	if @error = 1 goto error

if exists (select srvid from master..sysservers where srvname = @srvr1) 
	or exists (select *,server_id from master.sys.servers where name = @srvr1) --sql 7
	BEGIN
		-- SQL commando verder opbouwen en uitvoeren
			select @TSQL2 = '[' + @srvr1 + ']' + ', ' --+ char(39)

			select @TSQL1 = ' from openquery('
			--select @TSQL5 = @TSQL4 + 'where md.md_name is null or a.name is null or a.status <> md.md_status'
			--select @TSQL6 = @TSQL3 +'''' + @srvr1 + ''''+ @TSQL5
			select @sqlqry = @tsql1 + @tsql2 + @TSQL3 + ')' --+ ') b '

			select @sqlqry = 'insert into #jobhist (
			instance_id	,job_id,status, volgnr,rundate,runtime,runduration) 
			select ''' + cast(@instid as varchar(10)) + ''' as instance_id ,* '+ @sqlqry --+ ' where name = b.name and server = ' +  @srvr1 + ''
			--print @sqlqry
			exec (@sqlqry) -- tabel #jobhist vullen met te wijzigen gegevens



		--Linked server weer verwijderen
		EXEC sp_dropserver @srvr1 ,'droplogins'
		goto ok
	END
else
	BEGIN
	goto error
	END
	
error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
	end

ok:
	begin 
	print 'ok'
	end


	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@instid
	End



select @TSQL1 = ''
select @TSQL2 = ''
select @TSQL3 = ''
select @TSQL4 = ''
select @TSQL5 = ''
select @TSQL7 = ''
select @TSQL8 = ''
select @TSQL9 = ''
select getdate() as 'Einde'

Close node_cursor
Deallocate node_cursor
select * from #jobhist



--=================================================
--nieuwe jobhistory toevoegen

insert into dbo.mon_job_history (instance_id,job_id,status,volgnr,rundate,runtime,runduration)
select jh.instance_id,jh.job_id
,CASE jh.status
	WHEN 0 THEN 'Failed'
	WHEN 1 THEN 'Succeeded'
	WHEN 2 THEN 'Retry'
	WHEN 3 THEN 'Canceled'
	ELSE 'Unknown'
END as status
,jh.volgnr
,STUFF(STUFF(CAST(jh.rundate as varchar),7,0,'-'),5,0,'-') as run_date
,STUFF(STUFF(REPLACE(STR(jh.runtime,6,0),' ','0'),5,0,':'),3,0,':') as run_time
,jh.runduration
from #jobhist jh
left outer join mon_job_history lj
on jh.instance_id =lj.instance_id and jh.job_id =lj.job_id and jh.volgnr = lj.volgnr
where lj.volgnr is null


--drop table #jobhist
--select top 10 CAST(
--STUFF(STUFF(CAST(jh.rundate as varchar),7,0,'-'),5,0,'-') + ' ' + 
--STUFF(STUFF(REPLACE(STR(jh.runtime,6,0),' ','0'),5,0,':'),3,0,':') as datetime) AS [LastRun]
--,SUBSTRING(CAST(jh.rundate AS CHAR(8)),5,2) + '/' + 
--RIGHT(CAST(jh.rundate AS CHAR(8)),2) + '/' + 
--LEFT(CAST(jh.rundate AS CHAR(8)),4) 
--, LEFT(RIGHT('000000' + CAST(jh.runtime AS VARCHAR(10)),6),2) + ':' + 
-- SUBSTRING(RIGHT('000000' + CAST(jh.runtime AS VARCHAR(10)),6),3,2) + ':' + 
-- RIGHT(RIGHT('000000' + CAST(jh.runtime AS VARCHAR(10)),6),2)
--as run_time
--,* from #jobhist jh





--=================================================
--oude jobhistory verwijderen (ouder dan 90 dagen)

delete from dbo.mon_job_history where rundate < GETDATE () -90

SET NOCOUNT OFF
SET XACT_ABORT OFF


END






