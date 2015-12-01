





CREATE PROCEDURE [dbo].[sp_mon_DB_2005] 
--drop table #test
AS
BEGIN
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 19-01-2010 A vd Berg
-- 22-01-2010 A vd Berg
--    aanmaken linked server, en na de import weer verwijderen ivm security-risico
-- 17-02-2010 A vd Berg
--    Alleen veranderingen in centrale tabel vermelden, nieuwe, verwijderde en aangepaste dbs
--	18-02-2010 A vd Berg
--	Inclusief identity insert bij veranderingen in databasesettings
--	22-06-2010 A vd Berg
--		Deleted db's nu echt met einddatum
--	21-09-2010 A vd Berg
--		creator toegevoegd
--  07-12-2011	Avdberg	
--	Andere opzet, eerst data binnenhalen daarna joinen
--	fout verholpen: link op id ipv dbid gaf verkeerde resultaten bij het matchen van data, nu alleen op instance_id en dbid.
--	20-12-2011	AvdBerg
--	fout: ook instanties waarbij geen versie in ingevuld gaan nu mee
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
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@instid int,@TLok nvarchar(50)
declare @cnt int,@error int
Declare @Linked_server varchar(500)

--declare @mon_db as table (
create table #mon_db (
	[Server] varchar(100) Null,
	[instance_id] int,
	[dbname] [varchar](200)  NULL,
	[dbid] [smallint]  NULL,
	[mode] [smallint]  NULL,
	[status] [int]  NULL,
	[status2] [int] NULL,
	[crdate] [datetime]  NULL,
	[category] [int] NULL,
	[cmptlevel] [int]  NULL,
	[filename] [varchar](2000) NULL,
	[version] [int] NULL,
	creator varchar(200))
	
create table #mon_db_nw (
	[Server] varchar(100) Null,
	[instance_id] int,
	[dbname] [varchar](200)  NULL,
	[dbid] [smallint]  NULL,
	[mode] [smallint]  NULL,
	[status] [int]  NULL,
	[status2] [int] NULL,
	[crdate] [datetime]  NULL,
	[category] [int] NULL,
	[cmptlevel] [int]  NULL,
	[filename] [varchar](2000) NULL,
	[version] [int] NULL,
	creator varchar(200))
	
create table #result (
	[Server] varchar(100) Null,
	[instance_id] int,
	[dbname] [varchar](200)  NULL,
	[dbid] [smallint]  NULL,
	[mode] [smallint]  NULL,
	[status] [int]  NULL,
	[status2] [int] NULL,
	[crdate] [datetime]  NULL,
	[category] [int] NULL,
	[cmptlevel] [int]  NULL,
	[filename] [varchar](2000) NULL,
	[version] [int] NULL,
	creator varchar(200))
--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor

select @TSQL1 = 'select * from openquery ('
select @TSQL2 = ''''' as servername, ''''' 
select @TSQL3 =  ''''' as instance_id, name, dbid, mode, status, status2, cast(crdate as smalldatetime) as crdate, category, cmptlevel, filename,version,SUSER_SNAME(sid) as creator from master.sys.sysdatabases order by dbid'')' 

--select * , 'ROS42'  as servername, '225' as instance_id   from openquery([ROS42], 'SELECT name, dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,SUSER_SNAME(sid) from master..sysdatabases') a full outer join (select instance_id as md_instance_id,id as md_id, [crdate] as md_createdate ,[dbname] as md_name,status as md_status,server,creator as md_creator from dbo.Mon_DB where deldate is null and instance_id = '225') md on a.name COLLATE DATABASE_DEFAULT = md.md_name COLLATE DATABASE_DEFAULT where md.md_name is null or a.name is null or a.status <> md.md_status  or md_creator is null
--execute ('SELECT ''ros42'' as servername,''225'' as instance_id,name, dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,SUSER_SNAME(sid) as creator from master..sysdatabases') at ros42

-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select  server,domein,id from mon_instance where (versie  <>  '2000'  and versie not like '7%' or isnull(versie,'10') = '10') and controle = '1' and te_bewaken =1
   order by id 
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @TLok,@instid
WHILE @@FETCH_STATUS = 0
	BEGIN
		--if @inst = '' or @inst is null set @srvr1 = @srvr
		--if @inst <> '' 
		--begin
		--	set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		--end

--linked server aanmaken
	exec dbo.sp_mon_CreateLinkedServer @srvr,@error

	--print isnull(@TLok,'') + ': ' + @srvr


-- SQL commando verder opbouwen en uitvoeren
	--select @xTSQL2 = '[' +  + ']' + ', select ' --+ char(39)
select @sqlqry = @TSQL1 + '['+@srvr+'], ''select '''''+@srvr + '' + @TSQL2
--print @sqlqry
select @sqlqry = @sqlqry + cast(@instid as varchar(10)) + @TSQL3 
--print @sqlqry
--print @TSQL2
--select @sqlqry= @sqlqry+ @TSQL2 + CAST(@instid as varchar(10)) 
--print @sqlqry
--select @sqlqry= @sqlqry+ @TSQL3 + '['+@srvr+']'
--print @sqlqry
insert into #result
exec sp_executesql @sqlqry

--drop table #test
--drop table #result

--Linked server weer verwijderen
--EXEC sp_dropserver @srvr1 ,'droplogins'

	Fetch Next from node_cursor
	into @srvr,  @TLok,@instid
	End

select * from #result
order by instance_id,dbid

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
--select * from openquery ([BORPD008], 'select ''BORPD008'' as servername ')


--select * from #test

----updates uitvoeren op mon_DB

----nieuwe dbs toevoegen
--	insert into mon_db (instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator, server)
--	select instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,servername from #test
--	where md_name is null

---- verwijderde dbs een einddatum geven
--	update mon_DB
--	set deldate = getdate()
--	 from mon_DB md inner join #test t 
--	on md.id = t.md_id 
--	where t.dbid is null

--delete from #mon_db
insert into #mon_db (server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator)
select 
server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
--,instance_id ,dbid,id, [crdate],[dbname],status ,server,creator  
from dbo.Mon_DB where deldate is null 
order by instance_id, dbid

--select * from #mon_db
--order by instance_id,dbid

--select * from #result
--order by instance_id,dbid


--databases die wel in mon_db staan maar die niet voorkomen in de recente lijst (waarbij de instantie wel voorkomt en dus is gescand)
select 'deldate zetten voor databases die wel in mon_db staan maar die niet voorkomen in de recente lijst (waarbij de instantie wel voorkomt en dus is gescand)'
-- set deldate
------select * from mon_db
------update Mon_DB set deldate = null
update Mon_DB
set deldate = getdate() 
from mon_db m inner join 
(select instance_id,dbid, mode, status, status2, crdate, category, cmptlevel, filename ,version,creator --geen dbname!
 from #mon_db --order by instance_id,dbid
except
select instance_id,dbid, mode, status, status2,  crdate, category, cmptlevel, filename ,version,creator 
 from #result --order by instance_id,dbid
 ) a on a.instance_id =  m.instance_id and a.dbid = m.dbid
 where a.instance_id in (select instance_id from #result)

select COUNT(*) as aantal_in_#Result from #result


-- databases gevonden die niet of met andere data in de mon_db-tabel staan
select 'databases gevonden die niet of met andere data in de mon_db-tabel staan'
insert into #mon_db_nw (server,instance_id,dbid,dbname, mode, status, status2, crdate, category, cmptlevel, filename,version,creator)
select server,instance_id,dbid,dbname, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
 from #result
except
select server,instance_id,dbid,dbname, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
 from #mon_db

select * from #mon_db_nw

--delete foutieve entries from Mon_DB
delete from Mon_DB
--select 'delete foutieve entries from Mon_DB',*
from Mon_DB mb inner join #mon_db_nw r
on r.instance_id = mb.instance_id and r.dbid = mb.dbid


--select * from mon_db order by instance_id,dbid
--invoegen
insert into Mon_DB (server,instance_id,dbname,dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,datum)
select *,GETDATE() from #mon_db_nw
--select * from #result


-- verwijderen verwerkte gegevens
delete from #result
--select *
from #result r inner join #mon_db_nw n on r.instance_id=n.instance_id and r.dbid= n.dbid
--select * from #result
select COUNT(*) as aantal_in_#Result_na_aftrek_nieuwe_entries from #result

--leeghalen variabele
delete from #mon_db_nw

-- databases die exact overeenkomen met al geregistreerde data
select 'databases die exact overeenkomen met al geregistreerde data'
insert into #mon_db_nw
select server,instance_id,dbname,dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
 from #result
intersect
select server,instance_id,dbname,dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
 from #mon_db
--select * from #mon_db_nw
select count(*) from #mon_db_nw

update Mon_DB set datum = GETDATE()
from Mon_DB m inner join #mon_db_nw n  on m.instance_id=n.instance_id and m.dbid= n.dbid
--select * from mon_db order by instance_id,dbid


-- verwijderen verwerkte gegevens
delete from #result
from #result r inner join #mon_db_nw n on r.instance_id=n.instance_id and r.dbid= n.dbid
--select * from #result
select COUNT(*) as aantal_in_#result_met_aftrek_bekende_dbs from #result


 
----bestaande dbs verwijderen en opnieuw toevoegen
--	--
--	delete 	from mon_DB where id in (select md_id from #test where dbname = md_name )
--	--
--  	set identity_insert mon_DB on
--	insert into mon_DB (instance_id,id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,server)
--	select instance_id, md_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,servername from #test
--	where dbname = md_name 
--	set identity_insert mon_DB off

--drop table #test
drop table #result
drop table #mon_db
drop table #mon_db_nw

SET NOCOUNT OFF
SET XACT_ABORT OFF

END



--declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@instid int,@TLok nvarchar(50),@error int
--set @srvr1 = 'ros42'
----linked server aanmaken
--	exec dbo.sp_mon_CreateLinkedServer @srvr1,@error

----select * , 'ROS42'  as servername, '225' as instance_id   from openquery([ROS42], 'SELECT name, dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,SUSER_SNAME(sid) from master..sysdatabases') a full outer join (select instance_id as md_instance_id,id as md_id, [crdate] as md_createdate ,[dbname] as md_name,status as md_status,server,creator as md_creator from dbo.Mon_DB where deldate is null and instance_id = '225') md on a.name COLLATE DATABASE_DEFAULT = md.md_name COLLATE DATABASE_DEFAULT where md.md_name is null or a.name is null or a.status <> md.md_status  or md_creator is null
----execute ('SELECT ''ros42'' as servername,''225'' as instance_id,name, dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,SUSER_SNAME(sid) as creator from master..sysdatabases') at ros42


----Linked server weer verwijderen
--EXEC sp_dropserver @srvr1 ,'droplogins'

----select * from #result order by dbid
----select *
------,instance_id ,dbid,id, [crdate],[dbname],status ,server,creator  
----from dbo.Mon_DB where deldate is null and instance_id = 225
----order by dbid

----select * from Mon_DB_Files where instance_id = 225 and dbid = 5
--	--insert into mon_db (instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator, server)
--	select 
--	server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,GETDATE() as datum
--	from #result 
--;	
----with cte_mon_db as
----(select 
----server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,datum
------,instance_id ,dbid,id, [crdate],[dbname],status ,server,creator  
----from dbo.Mon_DB where deldate is null )

----declare @mon_db as table (
----	[Server] varchar(100) Null,
----	[instance_id] int,
----	[dbname] [varchar](200)  NULL,
----	[dbid] [smallint]  NULL,
----	[mode] [smallint]  NULL,
----	[status] [int]  NULL,
----	[status2] [int] NULL,
----	[crdate] [datetime]  NULL,
----	[category] [int] NULL,
----	[cmptlevel] [int]  NULL,
----	[filename] [varchar](2000) NULL,
----	[version] [int] NULL,
----	creator varchar(200))
	

----delete from dbo.Mon_DB
----from 
----(
----select 
----server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
---- from #result
---- --where dbid = 7;
----except
----select server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
----from cte_mon_db
----) a

----insert into dbo.Mon_DB (server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator,datum)
--select *,GETDATE()
--from (select 
--server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
-- from #result
-- --where dbid = 7;
--except
--select server,instance_id,[dbname],dbid, mode, status, status2, crdate, category, cmptlevel, filename,version,creator
--from @mon_db
--) a
-- order by instance_id

--select * from Mon_DB where instance_id =225

----delete from Mon_DB where id = 1701 or id = 1702 or id = 1704





