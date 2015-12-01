

CREATE PROCEDURE [dbo].[sp_mon_Backup_VSS] 

AS
BEGIN
	
/* Ophalen informatie uit alle gelinkte sql servers
** mbt backupdata
-- Script tbv nieuwe data importeren die nog niet geimporteerd is, of alles van de laatste 30 dgn

*/
--=========================================================================
-- 19-01-2010 A vd Berg
-- 22-01-2010 A vd Berg
--    aanmaken linked server, en na de import weer verwijderen ivm security-risico
-- 22-06-2010 A vd Berg
--		fout eruit gehaald met outer join; nu wel alle backups
-- 03-09-2010 A vd Berg
--		device_type gefilterd na problemen met vastlopende backups. DB was nooit gebackupt, 
--		toch backupdata uit deze sp. Bleek Device_type 7 te zijn met een guid als backupfile.
--20-04-2011 A vd Berg
--		tabel opschonen (data ouder dan 3 maanden eruit)
--12-09-2011 A vd Berg
--		hernoemde/verwijderde databases geven null bij dbid(dbnaam)-functie, deze db's worden nu bewaard met dbid 0
--13-09-2011 A vd Berg
--		db's van voor SQL 2000 geven problemen met query.
--		backuphistorie na 60 dgn verwijderen ipv na 90 dagen
--31-05-2012 A vd berg
--		datumcompare loopt niet goed; records komen in meervoud in de table mon_backups.
--		conversie van datetime naar smalldatetime lost dit probleem op (er zaten verschillen in ms in die de problemen veroorzaakten)
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
declare @vnode nvarchar(50), @srvr nvarchar(50), @srvr1 nvarchar(50),@ver nvarchar(50),@id int
declare @cnt int,@error int
Declare @Linked_server varchar(500)




-- tabel opschonen (data ouder dan 2 maanden eruit)
--SM delete from dbo.Mon_Backups where backup_datum <GETDATE() -60



--Data uit linked server overhalen in een fysieke (tijdelijke) tabel. 
--gebruik van een temp-tabel werkt hier niet icm een linked server, helaas
--if exists (select * from tempdb.dbo.sysobjects where name like '#mp_start%') 
--IF OBJECT_ID('tempdb..#mp_start') IS NOT NULL 
--		BEGIN
--		drop table #mp_start
--		END

-- Select @TSQL1 komt later in node_cursor
-- Select @TSQL2 komt later in node_cursor



-- declareer arraytabel en vul met mon_instance
select getdate() as 'start'
select count(*) as 'aantal' from mon_instance--logcontrole.dbo.c_sqlnodes



declare node_cursor Cursor For
	select node, instance,versie,id from mon_instance where controle = '1' and isnull(te_bewaken,1) =1 and node <> 'maaka07'
   order by domein, instance,node
open node_cursor
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@id
WHILE @@FETCH_STATUS = 0
	BEGIN
		if @inst = '' or @inst is null set @srvr1 = @srvr
		if @inst <> '' 
		begin
			set @srvr1 = @srvr + '\'+ @inst --+ char(39)
		end

		
------select serverproperty('ProductVersion'), left(cast(serverproperty('ProductVersion') as varchar(40)),1)
------	,left(cast(serverproperty('ProductVersion') as varchar(40)),charindex('.',cast(serverproperty('ProductVersion') as varchar(40)))-1)
--linked server aanmaken
set @error=0
	if @ver like '7.%' or @ver like '6.%'
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error,@version =7
			select @TSQL3 =  '''SELECT db_id(b.database_name) as dbid,b.type ,datediff(s, b.backup_start_date,b.backup_finish_date) as duur,
					b.backup_size,ISNULL(DATEDIFF(dd,ISNULL(b.backup_start_date, ''''01/01/1900''''),GETDATE()),0)  ,
					ISNULL(b.backup_start_date, ''''01/01/1900'''') as backup_datum, b.database_name ,c.physical_device_name 
					FROM msdb..backupset b 	inner join msdb..backupmediafamily c on c.media_set_id = b.media_set_id
				where b.type IN (''''D'''',''''I'''',''''L'''') and backup_start_date >= getdate() -20 and c.device_type =7
				AND database_name  not in (''''tempdb'''',''''Northwind'''',''''pubs'''') and b.server_name =@@servername
				order by b.database_name, type,ISNULL(b.backup_start_date, ''''01/01/1900'''')''' 
				select @TSQL3 = @TSQL3 + ') a '
				select @TSQL3 = @TSQL3 + 'left outer join (select distinct [instance_id],cast(backup_datum as smalldatetime) as backup_Datum,type,dbid from dbo.Mon_Backups  where backup_datum >getdate() -20 and instance_id = '
			
		END
	else
		BEGIN
			exec dbo.sp_mon_CreateLinkedServer @srvr1,@error
			select @TSQL3 =  '''SELECT isnull(db_id(b.database_name),0) as dbid,b.type ,datediff(s, b.backup_start_date,b.backup_finish_date) as duur,
					b.backup_size,ISNULL(DATEDIFF(dd,ISNULL(b.backup_start_date, ''''01/01/1900''''),GETDATE()),0)  ,
					ISNULL(b.backup_start_date, ''''01/01/1900'''') as backup_datum, b.database_name ,c.physical_device_name 
					FROM msdb..backupset b 	inner join msdb..backupmediafamily c on c.media_set_id = b.media_set_id
				where b.type IN (''''D'''',''''I'''',''''L'''') and backup_start_date >= getdate() -20 and c.device_type =7
				AND database_name  not in (''''tempdb'''',''''Northwind'''',''''pubs'''') and b.server_name =serverproperty(''''servername'''')
				order by b.database_name, type,ISNULL(b.backup_start_date, ''''01/01/1900'''')''' 
				select @TSQL3 = @TSQL3 + ') a '
				select @TSQL3 = @TSQL3 + 'left outer join (select distinct [instance_id],cast(backup_datum as smalldatetime) as backup_Datum,type,dbid from dbo.Mon_Backups  where backup_datum >getdate() -20 and instance_id = '
			
		END
	if @error >0  goto error

if exists (select srvid from master..sysservers where srvname = @srvr1)
BEGIN
	select @TSQL1 = 'select '''+ @srvr1 + ''' ,' + cast(@id as varchar(10)) + ', a.dbid, a.type,a.duur,a.backup_size,cast(a.backup_datum as smalldatetime) as backup_Datum,a.database_name,a.physical_device_name  from openquery('
--	select @srvr1 ='[' +@srvr1 +']'-- + ', ' +  char(39)+  char(39)+  char(39)
	--print  ': ' + @srvr1
	
	select @TSQL4 = @TSQL3 + cast( @id as varchar(10))
	select @TSQL4 = @TSQL4 + ') mb on a.dbid = mb.dbid '
	select @TSQL4 = @TSQL4 + 'and a.type COLLATE DATABASE_DEFAULT = mb.type COLLATE DATABASE_DEFAULT '
	select @TSQL4 = @TSQL4 + 'and mb.backup_datum = cast(a.backup_datum as smalldatetime)  where mb.backup_datum is  null and a.backup_datum > getdate() -30 '


-- SQL commando verder opbouwen en uitvoeren
		select @TSQL2 = '[' + @srvr1 + ']' + ', ' --+ char(39)
		select @sqlqry = @tsql1 + @tsql2 + @TSQL4
	--print @sqlqry
	--exec (@sqlqry)
	select @sqlqry = 'insert into dbo.Mon_backups_VSS(server,instance_id,dbid,type,duur,backup_size,backup_datum,database_name,backup_file)  '+ @sqlqry
	--print @sqlqry
		exec (@sqlqry)
		
--Linked server weer verwijderen
	EXEC sp_dropserver @srvr1 ,'droplogins'

END
	goto ok
error:
	begin
	print 'Connectie naar '+ @srvr1 + ' lukte niet'
	end

ok:
	

		set @srvr1 =''
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@id
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

-- tabel opschonen (data ouder dan 3 maanden eruit)
--delete from dbo.Mon_Backups where backup_datum <GETDATE() -90

SET NOCOUNT OFF
SET XACT_ABORT OFF

END



