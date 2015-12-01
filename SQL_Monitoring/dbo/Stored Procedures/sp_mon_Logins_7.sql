CREATE PROCEDURE [dbo].[sp_mon_Logins_7] 
AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
   Script tbv nieuwe data importeren die nog niet geimporteerd is, of wat gewijzigd is
*/
--=========================================================================
-- 19-01-2010 A vd Berg
-- 22-01-2010 A vd Berg
--    aanmaken linked server, en na de import weer verwijderen ivm security-risico
-- 17-02-2010 A vd Berg
--    Alleen veranderingen in centrale tabel vermelden, nieuwe, verwijderde en aangepaste logins
--	18-02-2010 A vd Berg
--	set identity_insert mon_logins off/on
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------

--=========================================================================
SET XACT_ABORT OFF
SET NOCOUNT ON
SET XACT_ABORT ON
print 'XACT ABORT is ON'
-- declare variabelen
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
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@error int,@ver nvarchar(50),@instid int
declare @cnt int
Declare @Linked_server varchar(500)
create table #test (
 createdate datetime, updatedate datetime, name varchar(100),
	[status] [smallint] ,
	[accdate] [datetime] NULL,
	[dbname] [sysname] NULL,
	[language] [sysname] NULL,
	[denylogin] [int] NULL,
	[hasaccess] [int] NULL,
	[isntname] [int] NULL,
	[isntgroup] [int] NULL,
	[isntuser] [int] NULL,
	[sysadmin] [int] NULL,
	[securityadmin] [int] NULL,
	[serveradmin] [int] NULL,
	[setupadmin] [int] NULL,
	[processadmin] [int] NULL,
	[diskadmin] [int] NULL,
	[dbcreator] [int] NULL,
	[loginname] [sysname] NULL
,ml_id int
,ml_createdate datetime,ml_updatedate datetime, ml_name varchar(100),server varchar(300),servername varchar(300)
,instance_id int
)

--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor

select @TSQL3 =  '''SELECT  [createdate],[updatedate] ,isnull([name],loginname) as name,status,accdate,dbname,language, [denylogin] ,[hasaccess]  ,[isntname],[isntgroup] ,[isntuser],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[loginname] FROM [master]..[syslogins]''' 
select @TSQL3 = @TSQL3 + ') a '
select @TSQL3 = @TSQL3 + 'full outer join (select id as ml_id, [createdate] as ML_createdate,[updatedate] as ml_updatedate ,[name] as ml_name,server from dbo.Mon_logins where deletedate is null and server = '
select @TSQL4 = ') ml on a.name COLLATE DATABASE_DEFAULT = ml.ml_name COLLATE DATABASE_DEFAULT '


-- declareer arraytabel en vul met mon_instance

declare node_cursor Cursor For
	select node, instance,domein,id from mon_instance where ( versie like '7%') and controle = '1'
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
	--if @ver like '7.%' or @ver like '6.%'
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error output,@version =7
		END
	--else
	--	BEGIN
	--		exec dbo.sp_mon_CreateLinkedServer @srvr1,@error
	--	END
	if @error >0  goto error
		
	print ': ' + @srvr1


-- SQL commando verder opbouwen en uitvoeren
	select @TSQL2 = '[' + @srvr1 + ']' + ', ' --+ char(39)

	select @TSQL1 = ' from openquery('
	select @TSQL5 = @TSQL4 + 'where ml.ml_name is null or a.name is null or ml.ml_updatedate +0.001 < a.updatedate'
	select @TSQL6 = @TSQL3 +'''' + @srvr1 + ''''+ @TSQL5
	select @sqlqry = @tsql1 + @tsql2 + @TSQL6 --+ ') b '
	--print @sqlqry
	select @sqlqry = 'insert into #test select * , ''' + @srvr1 + '''  as servername, ''' + cast(@instid as varchar(10)) + ''' as instance_id  '+ @sqlqry --+ ' where name = b.name and server = ' +  @srvr1 + ''
--	print @sqlqry
	exec (@sqlqry) -- table #test vullen met te wijzigen gegevens



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
select * from #test

--==============================================================================
--updates uitvoeren op mon_logins

--nieuwe logins toevoegen
	insert into mon_logins (instance_id,[createdate],[updatedate] ,[name],status,accdate,dbname,language, [denylogin] ,[hasaccess]  ,[isntname],[isntgroup] ,[isntuser],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[loginname],server)
	select instance_id,[createdate],[updatedate] ,[name],status,accdate,dbname,language, [denylogin] ,[hasaccess]  ,[isntname],[isntgroup] ,[isntuser],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[loginname],servername from #test
	where ml_name is null

-- verwijderde logins een einddatum geven
	update mon_logins
	set deletedate = isnull(ml_updatedate,getdate()), updatedate = isnull(ml_updatedate,getdate())
	 from mon_logins ml inner join #test t 
	on ml.id = t.ml_id 
--veranderde logins verwijderen en opnieuw toevoegen
	--
	delete from mon_logins where id in (select ml_id from #test where name = ml_name and updatedate > ml_updatedate) 
	--
	set identity_insert mon_logins on
 	insert into mon_logins (instance_id,id,[createdate],[updatedate] ,[name],status,accdate,dbname,language, [denylogin] ,[hasaccess]  ,[isntname],[isntgroup] ,[isntuser],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[loginname],server)
	select instance_id,ml_id,[createdate],[updatedate] ,[name],status,accdate,dbname,language, [denylogin] ,[hasaccess]  ,[isntname],[isntgroup] ,[isntuser],[sysadmin],[securityadmin],[serveradmin],[setupadmin],[processadmin],[diskadmin],[dbcreator],[loginname],servername from #test
	where name = ml_name and updatedate > ml_updatedate and ml_name is not null
	set identity_insert mon_logins off

drop table #test

SET NOCOUNT OFF
SET XACT_ABORT OFF

END

