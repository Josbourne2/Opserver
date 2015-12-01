

CREATE procedure [dbo].[sp_mon_freediskspace]
as
begin
-- =============================================================
-- ophalen vrije diskruimte van gemonitorde servers.
-- mountpoints worden niet meegenomen!

-- =============================================================

EXECUTE AS LOGIN='MonitoringAccount_OSQL'

SET XACT_ABORT OFF
SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF


declare @srvr nvarchar(50)
	, @srvr2 nvarchar(50)
	, @TLok varchar(50)
	, @build varchar(50)
	, @inst varchar(50)
	, @SQLString varchar(4000)
	, @SQLQry varchar(1000)
	, @rset varchar(256)
	, @ver varchar(256)
	, @arch varchar(256)
	, @edition varchar(500)
	, @wpos int
	, @w_build varchar(50)
	, @w_sp varchar(50)
	, @qry varchar(1000)
	, @dbnaam varchar(500)
	,@dbid varchar(10)
	, @row 		int
	, @rowcnt 	int
	, @sql		varchar(4000)
	,@instid int

create table #dbnaam (
	dbnaam 		varchar(500)
	,id 		int identity(1,1)); 
create table #diskspace (
	id 		int identity(1,1)
	,server		varchar(500)
	, blank varchar(10)
	--,dbnaam 	varchar(500)
	,diskname 	varchar(500)
	--,filesize	varchar(50)
	,Free_MB	varchar(50)
	,datum		varchar(50)
	--,dbid int
	,instid int
	)
/*
Configuration option 'show advanced options' changed from 1 to 1. Run the RECONFIGURE statement to install.
Configuration option 'xp_cmdshell' changed from 1 to 1. Run the RECONFIGURE statement to install.
ZMAAS533.A-RECHTSPRAAK.MINJUS.NL
data verzamelen
2012
data verzamelen
2012

*/


Set @row =0
select getdate() as 'Gestart', count(*) as '# servers' from mon_instance where 1=1 /*and versie = '2005' or versie like '7%'*/ and controle =1 --and node like 'borpsq18%'
declare node_cursor Cursor For
	select node, instance, versie,id from mon_instance where 1=1 /*versie like '%2005%' or versie like '7%' and */ and controle =1 /*and node = 'BORPis05'*/ order by node
	open node_cursor
	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@instid
print @srvr

WHILE @@FETCH_STATUS = 0
	BEGIN
		if @inst <> '' set @srvr2 = @srvr + '\' + @inst
		if @inst = '' or @inst is null set @srvr2 = @srvr
		set @qry = 'osql -S' + @srvr2 + ' -d master -E -h-1 -w1000 -Q "'
		set @SQLQry = 'set nocount on; SELECT cast(database_id as varchar(4)) + ''__''+ name FROM sys.databases;'
		set @SQLString = @qry + @SQLQry + '"'
--print @SQLString
		INSERT into  #dbnaam (dbnaam)
		EXEC master..xp_cmdshell @SQLString
		
IF EXISTS(SELECT dbnaam FROM #dbnaam where dbnaam  like '%master%' or dbnaam like '%msdb%' )
begin
print 'data verzamelen' + @srvr2
print @ver
			set @sql = 'EXEC master.dbo.xp_fixeddrives ;'	
		set @SQLString = @qry + @sql + '"'-- -s, -w1000'
--print @sqlstring
				INSERT into #diskspace (diskname)
				EXEC master..xp_cmdshell @SQLString;

				delete from #diskspace where diskname is null 
				delete from #diskspace where diskname like '%rows affected)%' 
				update #diskspace set diskname = ltrim(diskname)
			
			update #diskspace set instid = @instid
			update #diskspace set server = @srvr2
			update #diskspace set diskname = replace(diskname,' ','')--(diskname,1,3)
			update #diskspace set Free_MB = substring(diskname,2,len(diskname) -1) --(diskname,1,3)
			update #diskspace set diskname = left(diskname,1)
--select * from #diskspace
			
--opslaan in de database SQL_Monitoring

		insert into Mon_Server_Freediskspace (driveletter,mbvrij,instance_id,datum) select diskname,free_mb,@instid,getdate() from #diskspace-- where diskname in ('log','dat','row')
--end
		END
		

		-- opschonen voor volgende servernaam en resetten id-velden
		truncate table #diskspace
		truncate table #dbnaam
		set @row = 0
		set @srvr2 =''
	

	Fetch Next from node_cursor
	into @srvr, @inst, @ver,@instid
	End
Close node_cursor
Deallocate node_cursor

--select * from #dbnaam
--select * from #diskspace
-- verwijderen tijdelijke tabellen
drop table #dbnaam
drop table #diskspace






END




