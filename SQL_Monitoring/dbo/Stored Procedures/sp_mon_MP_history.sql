
CREATE PROCEDURE [dbo].[sp_mon_MP_history] 

AS
BEGIN

--=========================================================================
	
/* Ophalen informatie uit alle gelinkte sql servers
** mbt history Maintenance plans
*/
--=========================================================================
-- 19-01-2010 A vd Berg
--  Alleen SQL 2000, SQL2005 bewaart standaard de historie op databaseniveau in SSIS.
-- 22-02-2010 A vd Berg
--  Aangepast met instance_id
--
-- Voor SQL2005 is alleen de MP-historie zonder databasenaam te achterhalen uit de systemdbs, 
--  tenzij/totdat gebruikt gemaakt wordt van de 'legacy' scripts. 
--  Deze laatste worden door dit script wel meegenomen, zeker 
--  omdat de 'automatische maintenancejobs met het ictroscript zijn gebaseerd op deze legacy-methode.
--
--
-- 27-09-2010 A vd Berg
-- Voor maintenanceplans > 2000 wordt de databasenaam vervangen door de scope van het mp, en de dbid = 0. 
-- Dit om toch iets van historie te kunnen raadplegen.
-- Ondersteuning voor de 'legacy' mps (= sql2000 binnen sql2005) vervalt hiermee.
---------------------------------------------------------------------

--------------------

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
declare @vnode nvarchar(50), @datum datetime, @instid int,@srvr nvarchar(50), @srvr1 nvarchar(50),@srvrStart varchar(300),@ver nvarchar(50)
declare @cnt int,@error int

--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 
--gebruik van een temp-tabel werkt hier niet icm een linked server, helaas
--if exists (select * from tempdb.dbo.sysobjects where name like '#mp_start%') 
IF OBJECT_ID('tempdb..#mp_start') IS NOT NULL 
		BEGIN
		drop table #mp_start
		END
IF OBJECT_ID('mp_data') IS NOT NULL 
		BEGIN
		drop table mp_data
		END
create table  #MP_start (datum smalldatetime, server_name varchar(100),instance_id int,dbid int)
--create table  #MP_data (server_name varchar(30), instance_id int,datum smalldatetime, MaintenanceName varchar(500),database_name varchar(100),Activity varchar(500),FoutMelding varchar(1000),succeeded bit )

Select @TSQL1 = ' select server_name, instance_id, cast(datum as smalldatetime) as datum, MaintenanceName,database_name,dbid,Activity,FoutMelding,succeeded into MP_data from openquery('
-- Select @TSQL2 komt logcontrole als node_cursor
Select @TSQL3 = ', mh.start_time AS datum,
			SUBSTRING(mh.plan_name, 1, 80) AS MaintenanceName , 
			mh.database_name,db_id(mh.database_name) as dbid,
			SUBSTRING(mh.activity, 1, 30) AS Activity,
			SUBSTRING(mh.message, 1, 50) as FoutMelding,
			mh.succeeded '
Select @TSQL4 = 'FROM		 msdb.dbo.sysdbmaintplan_history mh'

--Select @TSQL5 = '		where succeeded = 0
--		and message not like ''''Backup can not be performed on this database. This sub task is ignored''''  and mh.start_time >= ' -- status 0 = fout
Select @TSQL7 = ' ORDER BY mh.start_time ASC'
Select @TSQL8 = ''') a '

-- declareer arraytabel en vul met mon_instance
select getdate() as 'start'
select count(*) as 'aantal' from mon_instance
 
insert into #mp_start (datum , server_name ,instance_id,dbid ) select  max(datum)  as datum , server_name,instance_id,dbid  from Mon_MP_history  group by instance_id,server_name,dbid
select * from #mp_start
--drop table  #MP_start

declare node_cursor Cursor For
	select node, instance,versie,id from mon_instance where controle = '1' and isnull(te_bewaken,1) =1--and node like 'borasq10'
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
print @srvr1
print cast(@instid as varchar(3))
print @ver
--indien van toepassing de (nog) niet bestaande linked server aanmaken
set @error=0
	if @ver like '7.%' or @ver like '6.%'
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error,@version =7
			Select @TSQL3 = ', mh.start_time AS datum,
			SUBSTRING(mh.plan_name, 1, 80) AS MaintenanceName , 
			mh.database_name,db_id(mh.database_name) as dbid,
			SUBSTRING(mh.activity, 1, 30) AS Activity,
			SUBSTRING(mh.message, 1, 50) as FoutMelding,
			mh.succeeded '
			Select @TSQL4 = 'FROM		 msdb.dbo.sysdbmaintplan_history mh'
			Select @TSQL7 = ' ORDER BY mh.start_time ASC'
		END
	else
		if @ver like '2000%' 
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error
			Select @TSQL3 = ', mh.start_time AS datum,
			SUBSTRING(mh.plan_name, 1, 80) AS MaintenanceName , 
			mh.database_name,db_id(mh.database_name) as dbid,
			SUBSTRING(mh.activity, 1, 30) AS Activity,
			SUBSTRING(mh.message, 1, 50) as FoutMelding,
			mh.succeeded '
			Select @TSQL4 = 'FROM		 msdb.dbo.sysdbmaintplan_history mh'
			Select @TSQL7 = ' ORDER BY mh.start_time ASC'
		END
		else
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error
			Select @TSQL3 = ', mpl.start_time as datum,
							 mp.[name] AS MaintenanceName , 
						case when mpld.Line3 like ''''Databases:% '''' then REPLACE(mpld.Line3, ''''Databases: '''', '''''''') else null end as database_name,
						''''0'''' as dbid,
							 msp.subplan_name as activity, 
							 mpld.error_message as FoutMelding,
							 mpld.succeeded '
			Select @TSQL4 = 'FROM msdb.dbo.sysmaintplan_plans mp 
						JOIN msdb.dbo.sysmaintplan_subplans msp ON mp.id=msp.plan_id 
						JOIN msdb.dbo.sysmaintplan_log mpl ON msp.subplan_id=mpl.subplan_id 
						JOIN msdb.dbo.sysmaintplan_logdetail mpld ON mpl.task_detail_id=mpld.task_detail_id '
			Select @TSQL7 = ' ORDER BY mpl.start_time ASC'

									
		END
	if @error >0  goto error
		
--Select @TSQL5 = ' select [' + @srvr1 + '] as server_name, ' + cast(@instid as varchar(10)) + ' as instance_id, ' + @TSQL1 

-- Bepalen laatste binnengehaalde MP_status van deze server
		select server_name,datum,dbid from #mp_start where instance_id = @instid
		select @cnt = count(*) from #mp_start where instance_id = @instid

-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of alles van de laatste 30 dgn
		if @cnt >0	select  @datum = datum from #mp_start where instance_id = @instid
		--if @cnt >0 Select @tsql9 = '  WHERE  datum >= '''  + cast(@datum as varchar(30))+ ''''
		if @cnt >= 0  Select @tsql9 = '  WHERE  datum  > getdate() -30' 

		select @srvr1 ='[' +@srvr1 +']'-- + ', ' +  char(39)+  char(39)+  char(39)
		print  ': ' + @srvr1

-- SQL commando verder opbouwen en uitvoeren
		select @TSQL2 =  @srvr1 + ', ' --+ char(39)
		select @TSQL5 = 'SELECT ''''' + @srvr1 + ''''' as server_name, ''''' + cast(@instid as varchar(10)) +''''' as instance_id ' + @TSQL3
		select @sqlqry = @TSQL1 + @TSQL2 + space(1) + char(39) +  @TSQL5 + @TSQL4 + @TSQL7 + @TSQL8 + @TSQL9
print @sqlqry
		exec (@sqlqry)


		insert into Mon_MP_history (server_name, instance_id,datum, MaintenanceName,database_name,dbid,Activity,Melding,succeeded )
		select mp.server_name, mp.instance_id, mp.datum, mp.MaintenanceName,mp.database_name,mp.dbid,mp.Activity,mp.FoutMelding,mp.succeeded from MP_data mp
		left outer join Mon_MP_history mh on mp.instance_id = mh.instance_id and mp.dbid = mh.dbid and mp.datum = mh.datum and mp.Activity COLLATE DATABASE_DEFAULT = mh.activity COLLATE DATABASE_DEFAULT
		where mh.instance_id is null
		
		
----drop table MP_Data
		select @sqlqry='if exists (select * from dbo.sysobjects where name = ''MP_data'') drop table MP_data'
		exec (@sqlqry)

--	SQL 2005 en hoger kunnen gebruik maken van 'legacy maintenance plans' die loggen in de tabellen uit SQL2000.
--	Deze historie is in bovenstaande stap niet meegenomen.
--	Alsnog:

	if @ver like '20%' and @ver not like '2000%'
		BEGIN
			Select @TSQL3 = ', mh.start_time AS datum,
			SUBSTRING(mh.plan_name, 1, 80) AS MaintenanceName , 
			mh.database_name,db_id(mh.database_name) as dbid,
			SUBSTRING(mh.activity, 1, 30) AS Activity,
			SUBSTRING(mh.message, 1, 50) as FoutMelding,
			mh.succeeded '
			Select @TSQL4 = 'FROM		 msdb.dbo.sysdbmaintplan_history mh'
			Select @TSQL7 = ' ORDER BY mh.start_time ASC'
		
		
			select @TSQL2 =  @srvr1 + ', ' --+ char(39)
			select @TSQL5 = 'SELECT ''''' + @srvr1 + ''''' as server_name, ''''' + cast(@instid as varchar(10)) +''''' as instance_id ' + @TSQL3
			select @sqlqry = @TSQL1 + @TSQL2 + space(1) + char(39) +  @TSQL5 + @TSQL4 + @TSQL7 + @TSQL8 + @TSQL9
		print @sqlqry
			exec (@sqlqry)
		


		-- Gegevens inlezen vanuit de temp tabel MP_data in de tabel Mon_MP_history
		-- vanwege problemen met de checks in tsql worden de scripts via een omweg uitgevoerd:


		insert into Mon_MP_history (server_name, instance_id,datum, MaintenanceName,database_name,dbid,Activity,Melding,succeeded )
		select mp.server_name, mp.instance_id, mp.datum, mp.MaintenanceName,mp.database_name,mp.dbid,mp.Activity,mp.FoutMelding,mp.succeeded from MP_data mp
		left outer join Mon_MP_history mh on mp.instance_id = mh.instance_id and mp.dbid = mh.dbid and mp.datum = mh.datum and mp.Activity COLLATE DATABASE_DEFAULT = mh.activity COLLATE DATABASE_DEFAULT
		where mh.instance_id is null

--
		----drop table MP_Data
		select @sqlqry='if exists (select * from dbo.sysobjects where name = ''MP_data'') drop table MP_data'
		exec (@sqlqry)
		END
goto ok

error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
	end

ok:
	begin 
	print 'ok'
	end
	
		set @srvr1 =''
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
--
if exists (select * from tempdb.dbo.sysobjects where name like '#MP_Start%') drop table #MP_Start
if exists (select * from dbo.sysobjects where name like 'MP_data') drop table MP_data

SET NOCOUNT OFF
SET XACT_ABORT OFF
END

