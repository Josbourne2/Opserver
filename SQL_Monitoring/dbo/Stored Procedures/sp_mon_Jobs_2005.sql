





CREATE PROCEDURE [dbo].[sp_mon_Jobs_2005] 
--drop table #test
AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 20-09-2010 A vd Berg
-- 25-05-2011 A vd Berg
--     @error-variabele werd niet gereset; na een fout met een linked server werden alle volgende servers als fout behandeld. Is gecorrigeerd.

-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

--=========================================================================
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
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@instid int,@TLok nvarchar(50)
declare @cnt int,@error int
Declare @Linked_server varchar(500)

--if exists (select name from tempdb..sysobjects where name like '#jobs%') drop table #jobs
create table #jobs (
instance_id	int 
,job_id uniqueidentifier  
,jobname VARCHAR(200)
,job_enabled bit
, schedule_id int
,schedule_name varchar(300)
,schedule_enabled bit
,owner varchar(100)
,crdate smalldatetime
,updatedate smalldatetime
,deldate smalldatetime
)

--if exists (select name from tempdb..sysobjects where name like '#instance%') drop table #instance
create table #instance (
	node varchar (100)
	,instance varchar (100)
	,versie varchar(50)
	,domein varchar(100)
	,id int
	)
insert into #instance (node,instance,domein,id)
	select node, instance,domein,id from mon_instance where (versie >= '2005' ) and controle = 1 and te_bewaken = 1
	--and Node like 'zmpdb037%'
   order by node,instance

--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor



select @TSQL3 =  '''SELECT  sj.name as jobname,sj.job_id,sj.enabled as job_enabled,ss.schedule_id,ss.name as schedule_name,ss.enabled as schedule_enabled,SUSER_SNAME(sj.owner_sid) as owner ,sj.date_created,sj.date_modified 
FROM msdb.dbo.sysjobs sj left outer join msdb.dbo.sysjobschedules js on sj.job_id =js.job_id left outer join msdb.dbo.sysschedules ss on js.schedule_id =ss.schedule_id''' 
--select @TSQL3 = @TSQL3 + ') a '
--select @TSQL3 = @TSQL3 + 'full outer join (select instance_id as md_instance_id, id as md_id, [crdate] as md_createdate ,[dbname] as md_name,status as md_status, server from dbo.Mon_DB where deldate is null and server = '
--select @TSQL4 = ') md on a.name COLLATE DATABASE_DEFAULT = md.md_name COLLATE DATABASE_DEFAULT '

--print @tsql3
-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select node, instance,domein,id from #instance  --tabel eerder gedefinieerd
   --order by domein, instance,node
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @inst, @TLok,@instid
WHILE @@FETCH_STATUS = 0
	BEGIN
		if @inst = '' or @inst is null set @srvr1 = @srvr
		if @inst <> '' 
		begin
			set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		end

--linked server aanmaken
if not exists (select name from sys.servers where name = @srvr1)
Begin
	print @srvr1
	print @error
	exec dbo.sp_mon_CreateLinkedServer @srvr1,@error output
	if @error = 1 goto error
end
--exec dbo.sp_mon_CreateLinkedServer '[ZMADB009.a-rechtspraak.minjus.nl]',1

	print isnull(@TLok,'') + ': ' + @srvr1

-- SQL commando verder opbouwen en uitvoeren
	select @TSQL2 = '[' + @srvr1 + ']' + ', ' --+ char(39)

	select @TSQL1 = ' from openquery('
	--select @TSQL5 = @TSQL4 + 'where md.md_name is null or a.name is null or a.status <> md.md_status'
	--select @TSQL6 = @TSQL3 +'''' + @srvr1 + ''''+ @TSQL5
	select @sqlqry = @tsql1 + @tsql2 + @TSQL3 + ')' --+ ') b '
	--print 'query'
	--print 'select ' + cast(@instid as varchar(5)) + ', * ' +  @sqlqry
	--exec ('select  * ' +  @sqlqry)
	select @sqlqry = 'insert into #jobs (
	instance_id	,jobname,job_id,job_enabled, schedule_id,schedule_name,schedule_enabled,owner,crdate,updatedate	) 
	select ''' + cast(@instid as varchar(10)) + ''' as instance_id ,* '+ @sqlqry --+ ' where name = b.name and server = ' +  @srvr1 + ''
	--print @sqlqry
	exec (@sqlqry) -- tabel #jobs vullen met te wijzigen gegevens



--Linked server weer verwijderen
EXEC sp_dropserver @srvr1 ,'droplogins'
goto ok

error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
	delete from #instance where id = @instid  -- voorkomen dat jobs op deleted worden gezet terwijl instance niet te bereiken is
	set @error =0
	end

ok:
	begin 
	print 'ok'
	end


	Fetch Next from node_cursor
	into @srvr, @inst, @TLok,@instid
	End



select @TSQL1 = ''
select @TSQL2 = ''
select @TSQL3 = ''
select @TSQL4 = ''
select @TSQL5 = ''
select @TSQL7 = ''
select @TSQL8 = ''
select @TSQL9 = ''
--select getdate() as 'Einde'

Close node_cursor
Deallocate node_cursor
--select * from #jobs 
--where crdate>getdate()-2
--where instance_id =2


--=================================================
--nieuwe jobs toevoegen
insert into mon_jobs (instance_id,jobname,job_id,job_enabled,schedule_id,Schedule_name,schedule_enabled,owner 
,crdate,updatedate)
SELECT  j.instance_id,j.jobname,j.job_id,j.job_enabled,j.schedule_id,j.schedule_name,j.schedule_enabled,j.owner ,j.crdate,j.updatedate
FROM #jobs j
full outer join
dbo.mon_jobs lj on j.job_id =lj.job_id and j.instance_id = lj.instance_id and isnull(j.schedule_id,1234567) =isnull(lj.schedule_id,1234567)
where lj.jobname is null and j.crdate is not null
order by j.instance_id

--select * from mon_jobs 

--=================================================
--bestaande jobs updaten
update mon_jobs 
set jobname=j.jobname
	,job_id=j.job_id
	,job_enabled=j.job_enabled
	,schedule_id=j.schedule_id
	,Schedule_name= j.Schedule_name
	,schedule_enabled=j.schedule_enabled
	,owner =j.owner
	,updatedate = j.updatedate
--SELECT  dbo.instname(j.instance_id),j.jobname,j.job_id,j.schedule_id,j.schedule_name,j.owner ,j.crdate,j.updatedate,lj.updatedate
FROM #jobs j
inner join
dbo.mon_jobs lj on j.job_id =lj.job_id and j.instance_id = lj.instance_id and isnull(j.schedule_id,1234567) =isnull(lj.schedule_id,1234567)
where lj.updatedate < cast(j.updatedate as smalldatetime)
and lj.instance_id in (select id from #instance)

--select * from mon_jobs where jobname = 'Transaction Log Backup Job for DB Maintenance Plan ''DB Plan for user databases''' and instance_id =24
----A997BCC0-43A4-4104-A877-10B39BC4BA88
--select * from #jobs where jobname = 'Transaction Log Backup Job for DB Maintenance Plan ''DB Plan for user databases''' and instance_id =24

--=================================================
--verwijderde jobs afmelden


update mon_jobs 
set deldate=GETDATE()
--SELECT  dbo.instname(lj.instance_id),lj.instance_id,lj.jobname,j.jobname,j.job_id,j.schedule_id,j.schedule_name,j.owner ,j.crdate,j.updatedate,lj.updatedate,lj.deldate
FROM mon_jobs lj
full outer join
#jobs j on j.job_id =lj.job_id and j.instance_id = lj.instance_id and isnull(j.schedule_id,1234567) =isnull(lj.schedule_id,1234567)
where j.jobname is null and lj.crdate is not null and lj.deldate is  null
and lj.instance_id in (select id from #instance)






--drop table #jobs

SET NOCOUNT OFF
SET XACT_ABORT OFF


END

--EXEC sp_addlinkedserver 'ZMPDB008.rechtspraak.minjus.nl\VDI', N'SQL Server'





