CREATE PROCEDURE [dbo].[sp_mon_DB_Usage] 
--drop table #test
AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 06-09-2010 A vd Berg
--		importeren last-useage van de databases(indexen uit dmv index_usage_stats)

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

create table #test (
	--[dbname] [varchar](200)  NULL,
instance_id int,
	[dbid] [smallint]  NULL,
	last_read smalldatetime null
	--[mode] [smallint]  NULL,
	--[status] [int]  NULL,
	--[status2] [int] NULL,
	--[crdate] [datetime]  NULL,
	--[category] [int] NULL,
	--[cmptlevel] [int]  NULL,
	--[filename] [varchar](2000)  NULL,
	--[version] [int] NULL,
--md_instance_id int,
--md_id int,
--md_createdate datetime,
--md_name varchar(100),
--md_status int,
--server varchar(300),
--servername varchar(300),
)

--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor
select @tsql3 = '
SELECT database_id, LastRead = MAX(CASE
WHEN last_user_seek > last_user_scan AND last_user_seek > last_user_lookup
THEN last_user_seek
WHEN last_user_scan > last_user_seek AND last_user_scan > last_user_lookup
THEN last_user_scan
ELSE last_user_lookup
END
), LastWrite = MAX(last_user_update) FROM
(
SELECT
s.database_id,--index_id,
last_user_seek = COALESCE(last_user_seek, ''''19000101''''),
last_user_scan = COALESCE(last_user_scan, ''''19000101''''),
last_user_lookup = COALESCE(last_user_lookup, ''''19000101''''),
last_user_update = COALESCE(last_user_update, ''''19000101'''')
FROM sys.dm_db_index_usage_stats i
right outer join (select database_id from sys.databases where database_id >4) s on i.database_id = s.database_id
) x
GROUP BY (database_id)
ORDER BY 1
'



-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select node, instance,domein,id from mon_instance where (versie = '2005' ) and controle = '1' 
   order by domein, instance,node
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
	exec dbo.sp_mon_CreateLinkedServer @srvr1,@error output
	if @error = 1 goto error

	print isnull(@TLok,'') + ': ' + @srvr1

-- SQL commando verder opbouwen en uitvoeren
	select @TSQL2 = '[' + @srvr1 + ']' + ', ''' --+ char(39)

	select @TSQL1 = ' from openquery('
	--select @TSQL5 = @TSQL4 + 'where md.md_name is null or a.name is null or a.status <> md.md_status'
	select @TSQL6 = @TSQL3 --+'''' + @srvr1 + ''''+ @TSQL5
	select @sqlqry = @tsql1 + @tsql2 + @TSQL6 --+ ') b '
	--print @sqlqry
	select @sqlqry = 'insert into #test  select ''' + cast(@instid as varchar(10)) + ''' as instance_id, database_id,lastread  '+ @sqlqry --+ ' where name = b.name and server = ' +  @srvr1 + ''
	select @sqlqry = @sqlqry + ''')'
	--print @sqlqry
	exec (@sqlqry) -- table #test vullen met te wijzigen gegevens


--select @tsql8 = @tsql7 + ' full outer join (select instance_id as md_instance_id, id as md_id, [crdate] as md_createdate ,[dbname] as md_name,status as md_status, server from dbo.Mon_DB where deldate is null and server = '





--Linked server weer verwijderen
EXEC sp_dropserver @srvr1 ,'droplogins'
goto ok

error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
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
select getdate() as 'Einde'

Close node_cursor
Deallocate node_cursor
select * from #test

--updates uitvoeren op mon_DB

--nieuwe dbs toevoegen
	insert into mon_DB_usage (instance_id,dbid, last_read,datum)
	select t.instance_id,t.dbid,t.last_read,getdate() from #test t left outer join mon_DB_usage md
   on t.instance_id = md.instance_id and t.dbid = md.dbid
	where md.last_read is null-- and instance_id is not null

-- Data bijwerken
	update mon_DB_usage
	set last_read = t.last_read, datum = getdate()
	 from mon_db_usage md inner join #test t 
	on md.instance_id = t.instance_id and md.dbid = t.dbid

--select * from mon_db_usage
drop table #test

SET NOCOUNT OFF
SET XACT_ABORT OFF

END

