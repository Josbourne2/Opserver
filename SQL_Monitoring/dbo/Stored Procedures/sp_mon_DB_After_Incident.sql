





CREATE PROCEDURE [dbo].[sp_mon_DB_After_Incident] 
--drop table #test
AS
BEGIN
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
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

TRUNCATE TABLE dbo.Mon_DB_2;

--declare @mon_db as table (
create table #mon_db (
	[instance_id] [int] NOT NULL,
	[name] [sysname] NOT NULL,
	[database_id] [int] NOT NULL,
	[state] [tinyint] NULL,
	[state_desc] [nvarchar](60) NULL)
	
create table #mon_db_nw (
	[instance_id] [int] NOT NULL,
	[name] [sysname] NOT NULL,
	[database_id] [int] NOT NULL,
	[state] [tinyint] NULL,
	[state_desc] [nvarchar](60) NULL)
	
create table #result (
	[instance_id] [int] NOT NULL,
	[name] [sysname] NOT NULL,
	[database_id] [int] NOT NULL,
	[state] [tinyint] NULL,
	[state_desc] [nvarchar](60) NULL)
--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor

select @TSQL1 = 'select * from openquery ('
select @TSQL3 =  ''''' as [instance_id]
      ,[name]
      ,[database_id]
      ,[state]
      ,[state_desc]
      from master.sys.databases'')'

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

	print isnull(@TLok,'') + ': ' + @srvr


-- SQL commando verder opbouwen en uitvoeren
	--select @xTSQL2 = '[' +  + ']' + ', select ' --+ char(39)
select @sqlqry = @TSQL1 + '['+@srvr+'], ''select '''''
print @sqlqry
select @sqlqry = @sqlqry + cast(@instid as varchar(10)) + @TSQL3 
print @sqlqry
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
order by instance_id,database_id

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

----delete from #mon_db
--insert into #mon_db ([instance_id]
--      ,[name]
--      ,[database_id]
--      ,[state]
--      ,[state_desc])
-- select
--[instance_id]
--      ,[name]
--      ,[database_id]
--      ,[state]
--      ,[state_desc]
----,instance_id ,dbid,id, [crdate],[dbname],status ,server,creator  
--from dbo.Mon_DB_2
--order by instance_id, database_id

--select * from #mon_db
--order by instance_id,dbid

--select * from #result
--order by instance_id,dbid

INSERT INTO Mon_DB_2 ([instance_id]
      ,[name]
      ,[database_id]
      ,[state]
      ,[state_desc])
      SELECT [instance_id]
      ,[name]
      ,[database_id]
      ,[state]
      ,[state_desc]
      from #result  



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





