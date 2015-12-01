



CREATE PROCEDURE [dbo].[sp_mon_DB_files] @node VARCHAR(255) = NULL

AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 06-12-2011 A vd Berg
--	controle en aanpassen name van de file (logical name), en gebruik 'server' ipv combi 'node' en 'instance'. 
-- 30-11-2011 A vd Berg
--	Controle-datum toegevoegd tbv script updaten autogrow-stappen
-- 14-11-2011 A vd Berg
--		In mon_instance geen SQLversie ingevuld (dat script heeft (nog) niet gelopen)? Dan wordt 2008 gebruikt.
-- 18-08-2010 A vd Berg
--		errors linked server afgevangen
-- 19-01-2010 A vd Berg
-- 22-01-2010 A vd Berg
--    aanmaken linked server, en na de import weer verwijderen ivm security-risico
-- 17-02-2010 A vd Berg
--    Alleen veranderingen in centrale tabel vermelden, nieuwe, verwijderde en aangepaste dbs
-- 18-02-2010 A vd Berg
--		inclusief identity insert bij veranderingen in database-settings
--	22-06-2010 A vd Berg



-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

--=========================================================================
SET XACT_ABORT OFF
SET NOCOUNT ON
SET XACT_ABORT ON
--print 'XACT ABORT is ON'
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
declare @vnode nvarchar(50)
		, @srvr nvarchar(50)
		--, @srvr1 nvarchar(50)
		,@instid int
		,@ver varchar(50)
declare @cnt int,@error int
Declare @Linked_server varchar(500)
declare @dbnaam varchar(150),@rowcnt int,@row int



create table #files (
instance_id int
,dbid int
,name varchar (150)
,fileid int
,filename varchar(500)
, filegroup varchar(50)
, size_kb bigint
, maxsize_kb bigint
, growth varchar(30)
, usage varchar(50)
,date smalldatetime
)

create table #dbnaam (
	dbnaam 		varchar(500)
	,id 		int identity(1,1)
	)

	
--========================
select @TSQL3 =  '''select db_id('''''


-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select server,versie,id from mon_instance 
	where controle = '1' and isnull(te_bewaken,1) =1 -- and node like 'zmadb009%' and instance is null--and (versie  like '7.%' or versie  like '6.%' )-- and controle = '1' 
   and (node = @node  or @node IS NULL)
     order by domein, instance,node
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @ver,@instid
WHILE @@FETCH_STATUS = 0
	BEGIN

	PRINT 'Beginnen node ' + @srvr
		--if @inst = '' or @inst is null set @srvr1 = @srvr
		--if @inst <> '' 
		--begin
		--	set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		--end

--linked server aanmaken
set @error=0
	if @ver like '7.%' or @ver like '6.%'
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr,@error,@version =7
		END
	else
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr,@error
		END

	if @error = 1 goto error

	

	print  @srvr
	

-- SQL commando verder opbouwen en uitvoeren
	select @TSQL2 = '[' + @srvr + ']' + ', ' --+ char(39)
select @TSQL6 = 'select ' + cast(@instid as varchar(10)) + ', * ,getdate() from openquery('

--controle SQL-versie
print @ver
if @ver is null
	BEGIN
		print 'Versie niet ingevuld; wordt nu gesteld op SQL2008'
		set @ver = '2008'
	END
if @ver like '7%' or @ver like '6%' 
	BEGIN
		--select '''SELECT name FROM master.dbo.sysdatabases where databasepropertyex(name,''''Status'''') in (''''ONLINE'''')'''
		select @TSQL5 = '''SELECT name FROM master.dbo.sysdatabases'''
		--print @tsql5
		select @TSQL9 = '.dbo.sysfiles order by fileid'''
			select @TSQL8 = '''''),name,  fileid, filename,
		filegroup = filegroup_name(groupid),
		''''size_kb'''' = convert (int, size) * 8 ,
		''''maxsize_kb'''' =  (case maxsize when -1 then -1
				else convert (int, maxsize) * 8 end),
		''''growth'''' = (case status & 0x100000 when 0x100000 then
			convert(nvarchar(15), growth) + N''''%''''
			else
			convert(nvarchar(15), convert (int, growth) * 8) + N'''' KB'''' end),
		''''usage'''' = (case status & 0x40 when 0x40 then ''''log only'''' else ''''data only'''' end)
		from '
 
		END
if @ver like '2000%'
	BEGIN
		--select '''SELECT name FROM master.dbo.sysdatabases where databasepropertyex(name,''''Status'''') in (''''ONLINE'''')'''
		select @TSQL5 = '''SELECT name FROM master.dbo.sysdatabases where databasepropertyex(name,''''Status'''') in (''''ONLINE'''')'''
		--print @tsql5
		select @TSQL9 = '.dbo.sysfiles order by fileid'''
		select @TSQL8 = '''''),name,  fileid, filename,
			filegroup = filegroup_name(groupid),
			''''size_kb'''' = convert (bigint, size) * 8 ,
			''''maxsize_kb'''' =  (case maxsize when -1 then -1
					else convert (bigint, maxsize) * 8 end),
			''''growth'''' = (case status & 0x100000 when 0x100000 then
				convert(nvarchar(15), growth) + N''''%''''
				else
				convert(nvarchar(15), convert (bigint, growth) * 8) + N'''' KB'''' end),
			''''usage'''' = (case status & 0x40 when 0x40 then ''''log only'''' else ''''data only'''' end)
			from ' 
	
	END
if @ver not like '7%' and @ver not like '6%' and @ver not like '2000%'
	 -- sql2005 of hoger
	BEGIN
		select @TSQL5 = '''SELECT name FROM master.sys.sysdatabases where databasepropertyex(name,''''Status'''') in (''''ONLINE'''')'''
		select @TSQL9 = '.sys.sysfiles order by fileid''' --sql 2000 = dbo.sysfiles
		select @TSQL8 = '''''),name,  fileid, filename,
			filegroup = filegroup_name(groupid),
			''''size_kb'''' = convert (bigint, size) * 8 ,
			''''maxsize_kb'''' =  (case maxsize when -1 then -1
					else convert (bigint, maxsize) * 8 end),
			''''growth'''' = (case status & 0x100000 when 0x100000 then
				convert(nvarchar(15), growth) + N''''%''''
				else
				convert(nvarchar(15), convert (bigint, growth) * 8) + N'''' KB'''' end),
			''''usage'''' = (case status & 0x40 when 0x40 then ''''log only'''' else ''''data only'''' end)
			from '
	END

	--import dbnamen
	select @TSQL1 = 'select * from openquery('
	select @TSQL5 = @TSQL1 + @TSQL2 + @TSQL5 + ')' 
	--print @tsql5


if exists (select srvid from master..sysservers where srvname = @srvr) 
	or exists (select *,server_id from master.sys.servers where name = @srvr) 
	BEGIN

	insert into #dbnaam (dbnaam)
	exec(@TSQL5)
	--select * from #dbnaam

		select @rowcnt=  count(dbnaam) from #dbnaam
		set @row=0
		IF @rowcnt >0
		BEGIN
		while @row < @rowcnt
			BEGIN
				
				set @row = @row +1
				select @dbnaam = ltrim(rtrim(dbnaam)) from #dbnaam where id = @row
							

				select @TSQL4 = @TSQL3 +  @dbnaam + @TSQL8 + '['  +  @dbnaam +  ']'  + @TSQL9
				select @sqlqry = @tsql6 + @tsql2 + @TSQL4 + ')'
				--print @sqlqry
				
				insert into #files 
				exec (@sqlqry) -- table #files vullen met te wijzigen gegevens

			END
		END
	truncate table  #dbnaam
	--Linked server weer verwijderen
	EXEC sp_dropserver @srvr ,'droplogins'
	goto ok
	END
ELSE 
	begin
	print 'Connectie naar '+ @srvr + ' lukte niet'
	end


error:
	begin
	print 'Connectie naar '+ @srvr + ' lukte niet'
	end

ok:
	begin 
	print 'ok'
	--select * from #files
	end



	Fetch Next from node_cursor
	into @srvr, @ver,@instid
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
--select * from #files
--select * from mon_db_files
--updates uitvoeren op mon_DB_files

--nieuwe files toevoegen
	insert into mon_db_files (instance_id,dbid,name,fileid,filename, filegroup, size_kb, maxsize_kb, growth, usage,date,controle_datum)
	select f.instance_id,f.dbid,f.name,f.fileid,f.filename, f.filegroup, f.size_kb, f.maxsize_kb, f.growth, f.usage,f.date,GETDATE() 
	from #files f
	left outer join mon_db_files df on f.instance_id =df.instance_id and f.dbid = df.dbid and f.fileid = df.fileid
	where df.instance_id is null 

---- verwijderde dbs een einddatum geven
--	hoeft niet

--bestaande entries  bijwerken
	update mon_db_files
	set filename=f.filename,name = f.name, filegroup=f.filegroup, size_kb=f.size_kb, maxsize_kb=f.maxsize_kb, growth=f.growth, date = getdate()
	--select *
	 from mon_db_files mf inner join #files f 
	on mf.instance_id = f.instance_id and mf.dbid = f.dbid and mf.fileid = f.fileid
	where mf.filename<>f.filename
	or mf.name <> f.name
	or mf.filegroup<>f.filegroup
	or mf.size_kb<>f.size_kb
	or mf.maxsize_kb<>f.maxsize_kb
	or mf.growth<>f.growth
	
--controledatum invullen van bestaande entries
	update mon_db_files
	set controle_datum=GETDATE()
	--select *
	from mon_db_files mf inner join #files f 
	on mf.instance_id = f.instance_id and mf.dbid = f.dbid and mf.fileid = f.fileid

drop table #files
drop table  #dbnaam

SET NOCOUNT OFF
SET XACT_ABORT OFF

END









