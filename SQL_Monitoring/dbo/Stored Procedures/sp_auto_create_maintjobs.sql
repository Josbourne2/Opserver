CREATE PROCEDURE [dbo].[sp_auto_create_maintjobs]
AS
BEGIN
SET NOCOUNT ON
   --=====================================================================================================
   -- Beschrijving:	Controleert of er nieuwe databases zijn aangemaakt, zonder beheerjobs. Voegt jobs toe
   --				na het laatste tijdstip van de bestaande jobs. Indien database is verwijderd worden de	
   --				beheer jobs ook verwijderd. 
   --
   -- Parameters:	geen
   -- 
   -- Historie:      
   -- Aangemaakt:	07-06-2010 A vd Berg
   --
   -- Wijziging:         
   --
   --=====================================================================================================

Declare @database_id			int
,		@databasename			varchar(128)
,		@create_date			datetime
,		@jobdescription			varchar(255)
,		@BackupTXNFreq			int
,		@BackupTXN				int
,		@BackupDB				int
,		@CheckDB				int
,		@ReorganizationDB		int	
,		@backupstarttime		datetime
,		@backupstarttimeChk		datetime
,		@backupstarttimeVar		varchar(30)
,		@txnbackupstarttime		datetime
,		@txnbackupstarttimeVar	varchar(30)
,		@reorgstarttime			datetime
,		@reorgstarttimeVar		varchar(30)
,		@checkstarttime			datetime
,		@checkstarttimeVar		varchar(30)
,		@cmd					nvarchar(512)
,		@loginterval			tinyint 
,		@ver					varchar(300)



select @ver = @@version
select @ver = ltrim(rtrim(substring(@ver, 22, 5)))
select @ver

-- nieuwe bijgekomen databases
print @ver
if cast(@ver as int) <= 2000
BEGIN
	DECLARE CurBeheerJobs CURSOR FOR
	SELECT 	dbid
	,		name
	,		crdate
	FROM 	master..sysdatabases
	WHERE	'Backup DB '''+ ltrim(rtrim(name)) + '''' not in (select name from msdb..sysjobs)
	AND		name <> 'tempdb'		
	OPEN	CurBeheerJobs
END
else
BEGIN
	DECLARE CurBeheerJobs CURSOR FOR
	SELECT 	database_id
	,		name
	,		create_date
	FROM 	sys.databases
	WHERE	'Backup DB '''+ ltrim(rtrim(name)) + '''' not in (select name from msdb..sysjobs)
	AND		name <> 'tempdb'		
	OPEN	CurBeheerJobs
END


FETCH NEXT FROM CurBeheerJobs


INTO	@database_id
,		@databasename
,		@create_date

print @database_id 
print @databasename 
print @create_date

SET @backupstarttimeChk = '2010-06-01 00:00:00.000'
	
WHILE @@FETCH_STATUS = 0
	BEGIN

IF REPLACE(CONVERT(varchar(20),@backupstarttimeChk,108),':','') = '000000'
BEGIN
-- Tijdstip bepalen waarop niet een soortgelijke job draait
	select top 1 @backupstarttimeVar = 
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),1,2) + ':'+
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),3,2) + ':' +
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),5,2) 
 from msdb..sysjobs sj left outer join msdb..sysjobschedules sjs
		on sj.job_id = sjs.job_id
	where sj.name like 'Backup DB%'
	order by next_run_date desc, next_run_time desc

	select @backupstarttime = convert(datetime,isnull(@backupstarttimeVar,'21:00:00'),108)

	select @backupstarttime = dateadd(minute,5,@backupstarttime)

	set @backupstarttimeChk = @backupstarttime
	
	select top 1 @txnbackupstarttimeVar = 
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),1,2) + ':'+
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),3,2) + ':' +
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),5,2)
from msdb..sysjobs sj left outer join msdb..sysjobschedules sjs
		on sj.job_id = sjs.job_id
	where sj.name like 'Backup TXN%'
	order by next_run_date desc, next_run_time desc

	select @txnbackupstarttime = convert(datetime,isnull(@txnbackupstarttimeVar,'00:01:00'),108)

	select @txnbackupstarttime = dateadd(minute,2,@txnbackupstarttime)

	select top 1 @checkstarttimeVar = 
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),1,2) + ':'+
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),3,2) + ':' +
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),5,2)
from msdb..sysjobs sj left outer join msdb..sysjobschedules sjs
		on sj.job_id = sjs.job_id
	where sj.name like 'Check DB%'
	order by next_run_date desc, next_run_time desc

	select @checkstarttime = convert(datetime,isnull(@checkstarttimeVar,'03:00:00'),108)

	select @checkstarttime = dateadd(minute,15,@checkstarttime)

	select top 1 @reorgstarttimeVar = 
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),1,2) + ':'+
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),3,2) + ':' +
SUBSTRING(RIGHT('000000' + CONVERT(VARCHAR(6),next_run_time),6),5,2)
from msdb..sysjobs sj left outer join msdb..sysjobschedules sjs
		on sj.job_id = sjs.job_id
	where sj.name like 'Reorganization DB%'
	order by next_run_date desc, next_run_time desc

	select @reorgstarttime = convert(datetime,isnull(@reorgstarttimeVar,'02:00:00'),108)

	select @reorgstarttime = dateadd(minute,15,@reorgstarttime)

END
ELSE
BEGIN

select @backupstarttime = dateadd(minute,5,@backupstarttime)
select @txnbackupstarttime = dateadd(minute,2,@txnbackupstarttime)
select @checkstarttime = dateadd(minute,15,@checkstarttime)
select @reorgstarttime = dateadd(minute,15,@reorgstarttime)

END

	SET @loginterval = 30 -- =< 60
	
	SET @cmd = N'EXEC [dbo].[sp_create_maintjobs] 
			@plandb = '''+@databasename+''',
			@Backuptijd = '+LEFT(REPLACE(CONVERT(varchar(20),@backupstarttime,114),':',''),6)+',
			@trnstarttijd = '+LEFT(REPLACE(CONVERT(varchar(20),@txnbackupstarttime,114),':',''),6)+',
			@trninterval ='++CAST(@loginterval AS NVARCHAR(3))+',
			@reorgtijd = '+LEFT(REPLACE(CONVERT(varchar(20),@reorgstarttime,114),':',''),6)+',
			@integertijd = '+LEFT(REPLACE(CONVERT(varchar(20),@checkstarttime,114),':',''),6)+''

	PRINT @cmd

		-- beheer jobs aanmaken
		exec sp_executesql @cmd


FETCH NEXT FROM CurBeheerJobs  
INTO	@database_id
,		@databasename
,		@create_date
END

CLOSE CurBeheerJobs  
DEALLOCATE CurBeheerJobs  

---- verwijderde databases
if cast(@ver as int) <= 2000
BEGIN
	DECLARE CURBEHEERJOBS CURSOR FOR
	SELECT 	SUBSTRING(NAME,CHARINDEX('''',NAME)+1,LEN(NAME) - (CHARINDEX('''',NAME)+1))AS DB,
			SUBSTRING(NAME,1,CHARINDEX('''',NAME)-1) AS JOB
	FROM 	MSDB..SYSJOBS
	WHERE	SUBSTRING(NAME,CHARINDEX('''',NAME)+1,LEN(NAME) - (CHARINDEX('''',NAME)+1)) NOT IN (SELECT NAME FROM master..sysdatabases)
	AND		name <> 'tempdb'
	AND		(name like 'Backup DB%' OR name like 'Check DB%' OR name like 'Reorganization DB%' OR name like 'Backup TXN%')
END
ELSE
BEGIN
	DECLARE CURBEHEERJOBS CURSOR FOR
	SELECT 	SUBSTRING(NAME,CHARINDEX('''',NAME)+1,LEN(NAME) - (CHARINDEX('''',NAME)+1))AS DB,
			SUBSTRING(NAME,1,CHARINDEX('''',NAME)-1) AS JOB
	FROM 	MSDB..SYSJOBS
	WHERE	SUBSTRING(NAME,CHARINDEX('''',NAME)+1,LEN(NAME) - (CHARINDEX('''',NAME)+1)) NOT IN (SELECT NAME FROM SYS.DATABASES)
	AND		name <> 'tempdb'
	AND		(name like 'Backup DB%' OR name like 'Check DB%' OR name like 'Reorganization DB%' OR name like 'Backup TXN%')
END
OPEN	CurBeheerJobs


FETCH NEXT FROM CurBeheerJobs

INTO	@databasename
,		@jobdescription
	
WHILE @@FETCH_STATUS = 0
	BEGIN
	 
	SET @cmd = N'EXEC [msdb]..[sp_delete_job] @job_name = '+ CHAR(39)+ @jobdescription + char(39)+char(39)+ @databasename +char(39)+ char(39)+''''
	print @cmd		
	-- beheer jobs verwijderen
	exec sp_executesql @cmd

FETCH NEXT FROM CurBeheerJobs  
INTO	@databasename
,		@jobdescription
END

CLOSE CurBeheerJobs  
DEALLOCATE CurBeheerJobs  

END

