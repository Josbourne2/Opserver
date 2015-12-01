CREATE PROCEDURE [dbo].[usp_Verzamel_dbprops_linked_server]
	(@srv nvarchar(50)=null)
AS
BEGIN
	/*
Van servers die niet met powershell benaderd kunnen worden 
kunnen met dit script de instance-parameters worden verzameld en ingelezen.

Er zijn een aantal databaseservers die expliciet uitgesloten worden (zie verder); deze geven connectieproblemen.
Vanwege problemen met gebruik van MSDTC owrdt alleen de beperkte inventarisatie gedaan; dit gebeurt door de variable @alternative op 1 te zetten ipv 0
*/

 
 SET NOCOUNT ON
 
--DECLARE @srv nvarchar(50) --='xx'--te gebruiken bij het testen van het script
DECLARE @srvs nvarchar(50)
DECLARE @ins varchar(100)
DECLARE @iid int
DECLARE @sname varchar(100)
DECLARE @inst TABLE(id int identity(1,1), iid int,name varchar(100),sname varchar(100),ins varchar(100))
DECLARE @id int=1,@idmax int
DECLARE @qry varchar(max),@qry2 varchar(max)
DECLARE @error nvarchar(2000)
DECLARE @alternative_default bit =1--zet op 0 als msdtc wel goed te gebruiken is.
DECLARE @alternative bit 

DECLARE @maxid int,@sql nvarchar(400),@date varchar(100), @dbname varchar(300), @dbid int,@mirror int,@dbstatus varchar(20)
DECLARE @did int ,@dmaxid int

SET @alternative=@alternative_default
set @date = GETDATE()
--if exists (select 1 from tempdb.sys.objects where name like '#temp1%') drop table #temp1
Create table #temp1(dbname varchar(300),dbid int,status varchar(20),state_desc varchar(20),datafiles int,size bigint,data_MB bigint
	,dataspaceusage bigint, spaceavailable bigint,logfiles int,log_MB bigint,logused_mb bigint,logavailable_MB bigint,
	user_access varchar(20),owner varchar(100),collation varchar(30),recoverymodel varchar(20),compatibilitylevel tinyint,ismirroringenabled bit,mirroringrole varchar(30)
	,mirroringrolesequence bigint,createdate smalldatetime,lastbackupdate smalldatetime,lastdifferentialbackupdate smalldatetime,lastlogbackupdate smalldatetime,
	fulltext bit,autoclose bit,pageverifyoption varchar(20),read_only bit,logreusewaitstatus varchar(30),autoshrink bit,
	autocreatestatisticsenabled bit, autoupdatestatisticsenabled bit,standby bit,cleanly_shutdown bit
	)
	
	--if exists (select 1 from tempdb.sys.objects where name like '#temp2%') drop table #temp2
Create table #temp2(date smalldatetime,
	server varchar(50),instance varchar(50),
	iid int,dbname varchar(300),dbid int,status varchar(20),state_desc varchar(20),datafiles int,size bigint,data_MB bigint
	,dataspaceusage bigint, spaceavailable bigint,logfiles int,log_MB bigint,logused_mb bigint,logavailable_MB bigint,
	user_access varchar(20),owner varchar(100),collation varchar(30),recoverymodel varchar(20),compatibilitylevel tinyint,ismirroringenabled bit,mirroringrole varchar(30)
	,mirroringrolesequence bigint,createdate smalldatetime,lastbackupdate smalldatetime,lastdifferentialbackupdate smalldatetime,lastlogbackupdate smalldatetime,
	fulltext bit,autoclose bit,pageverifyoption varchar(20),read_only bit,logreusewaitstatus varchar(30),autoshrink bit,
	autocreatestatisticsenabled bit, autoupdatestatisticsenabled bit,standby bit,cleanly_shutdown bit
	)

if @srv is null 
	BEGIN
	insert into @inst
		select id,server as sqlname,node as servername,instance from dbo.mon_Instance
		where 1=1
		and isnull(node,'xx') not in ('xx')
		and ISNULL(controle,1) =1
		and LEN(server) >1
	END
If @srv is not null
	BEGIN
	insert into @inst
			select id,server as sqlname,node as servername,instance from dbo.mon_Instance
		where 1=1
		and server = @srv
	END


Select  @idmax =COUNT(*) from @inst
WHILE @id <= @idmax
BEGIN
BEGIN TRY
	Select  @iid=iid,@srv = name, @ins=ins, @sname = sname from @inst
	where Id =@id
	set @id =@id+1

	print @srv 
IF EXISTS (select name from sys.servers where name = @srv)
	BEGIN
	EXEC master.dbo.sp_dropserver @server=@srv, @droplogins='droplogins'
	END
EXEC master.dbo.sp_addlinkedserver @server = @srv, @srvproduct=N'SQL Server'

	set @srvs=@srv
	EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @srvs, @locallogin = NULL , @useself = N'True'
	exec sp_serveroption @server=@srvs, @optname='rpc', @optvalue='true'  
	exec sp_serveroption @server=@srvs, @optname='rpc out', @optvalue='true'  
	--Read more: http://sqlsolace.blogspot.com/2009/09/server-dev-02-is-not-configured-for-rpc.html#ixzz2o0yzLBWx

--==============
-- extract databasenames and ids from instance
--==============
BEGIN TRY
	create table #dbs (name varchar(300),id int,mirrorrol int, state_desc varchar(20))
END TRY
BEGIN CATCH
	truncate table #dbs
END CATCH
--get the databases and their status from the specified server; doesnt work on sql2000!
set @qry = '
	SELECT
	name,a.database_id,
	mirroring_role, a.state_desc
	FROM
	sys.databases A
	INNER JOIN sys.database_mirroring B
	ON A.database_id=B.database_id
	WHERE (a.database_id > 4 or a.database_id = 2 or a.database_id = 3)
	ORDER BY A.NAME
	'
select @date = convert(varchar(100),GETDATE(),120)


--Execute several statements on the linked server.
set @qry2= 'select * from openquery(['+ @srvs +'],'''+@qry +''')'

insert into #dbs
EXEC ( @qry2)
set @did =0
select @dmaxid = max(id)  from #dbs

--itereate through all databases on the instance and get the properties
while @did < @dmaxid
BEGIN
BEGIN TRY
	select @did = MIN(id)  from #dbs where id >@did
	set @dbid = @did
	select @dbname = name,@mirror =isnull(mirrorrol,1),@dbstatus = state_desc from #dbs where id =@dbid
IF (@mirror =1 and @dbstatus in ('ONLINE'))
BEGIN

	set @qry =''
	set @qry2 =''
	if @alternative =0 --use msdtc to get the full set of options
		BEGIN
		set @qry = 
		'
			select 
			--getdate() as datum,
			--serverproperty(''''machinename'''') as server,
			--isnull(serverproperty(''''instancename''''),''''MSSQLSERVER'''') as instance,
			CONVERT(VARCHAR(300), DB.name) AS dbName,
			database_id,
			CONVERT(VARCHAR(30), DATABASEPROPERTYEX(DB.name, ''''status'''')) as status ,
			state_desc,
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS DataFiles,
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name ) AS [size],
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
			--(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Dataused MB],
			(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataSpaceUsage],
			(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [SpaceAvailable],
			--(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataAvailable_MB],
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS LogFiles,
			--(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [Log MB],
			(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logUsedMB],
			(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logAvailable_MB],
			--sum(case when type = 0 then CONVERT(decimal(12,2),round(fileproperty(name,''''SpaceUsed'''')/128.000,2)) else 0 end)
			user_access_desc AS [User access],
			SUSER_SNAME(owner_sid) as owner,
			collation_name as collation,
			recovery_model_desc AS [Recoverymodel],
			compatibility_level as compatibilitylevel,
			(select case when mirroring_role is null then 0 else 1 end from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as ismirroringenabled,
			(select mirroring_role_desc from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as mirroringrole,
			(select mirroring_role_sequence from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as MirroringRoleSequence,
			--CONVERT(VARCHAR(20), create_date, 103) + '''' '''' + CONVERT(VARCHAR(20), create_date, 108) AS createdate,
			create_date AS createdate,
			--(select top 1 CONVERT(VARCHAR(20), backup_start_date, 103) + '''' '''' + CONVERT(VARCHAR(20), backup_start_date, 108) FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''I'''' ORDER BY backup_set_id DESC) as LastDifferentialBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''L'''' ORDER BY backup_set_id DESC) as LastLogBackupDate,
			is_fulltext_enabled AS [fulltext],
			is_auto_close_on AS [autoclose],
			page_verify_option_desc AS PageVerifyOption,
			is_read_only AS [read_only],
			log_reuse_wait_desc AS LogReuseWaitStatus,
			is_auto_shrink_on AS [autoshrink],
			is_auto_create_stats_on AS AutoCreateStatisticsEnabled,
			is_auto_update_stats_on AS AutoUpdateStatisticsEnabled,
			is_in_standby  AS [standby],
			is_cleanly_shutdown AS [cleanly_shutdown]
			FROM sys.databases DB
			where database_id = db_id()
			ORDER BY database_id DESC, NAME
		' 
	--Execute several statements on the linked server.

		set @qry2= 'exec ( ''USE ['+ @dbname +']; '+ @qry +''') AT ['+ @srvs +']'
		insert into #temp1
		EXEC ( @qry2)
	END -- @alternative =0

	if @alternative =1 --no MSDTC can be used, use the simple set
	BEGIN
			--Alternate query for servers where MSDTC is not correctly configured (execute AT not possible)

		set @qry = 
		'
			select 
			CONVERT(VARCHAR(300), DB.name) AS dbName,
			database_id,
			CONVERT(VARCHAR(50), DATABASEPROPERTYEX(DB.name, ''''status'''')) as status ,
			state_desc,
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS DataFiles,
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name ) AS [size],
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
			--(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Dataused MB],
			(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataSpaceUsage],
			(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [SpaceAvailable],
			--(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataAvailable_MB],
			(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS LogFiles,
			--(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
			(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [Log MB],
			(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logUsedMB],
			(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logAvailable_MB],
			--sum(case when type = 0 then CONVERT(decimal(12,2),round(fileproperty(name,''''SpaceUsed'''')/128.000,2)) else 0 end)
			user_access_desc AS [User access],
			SUSER_SNAME(owner_sid) as owner,
			collation_name as collation,
			recovery_model_desc AS [Recoverymodel],
			compatibility_level as compatibilitylevel,
			(select case when mirroring_role is null then 0 else 1 end from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as ismirroringenabled,
			(select mirroring_role_desc from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as mirroringrole,
			(select mirroring_role_sequence from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as MirroringRoleSequence,
			--CONVERT(VARCHAR(20), create_date, 103) + '''' '''' + CONVERT(VARCHAR(20), create_date, 108) AS createdate,
			create_date AS createdate,
			--(select top 1 CONVERT(VARCHAR(20), backup_start_date, 103) + '''' '''' + CONVERT(VARCHAR(20), backup_start_date, 108) FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''I'''' ORDER BY backup_set_id DESC) as LastDifferentialBackupDate,
			(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''L'''' ORDER BY backup_set_id DESC) as LastLogBackupDate,
			is_fulltext_enabled AS [fulltext],
			is_auto_close_on AS [autoclose],
			page_verify_option_desc AS PageVerifyOption,
			is_read_only AS [read_only],
			log_reuse_wait_desc AS LogReuseWaitStatus,
			is_auto_shrink_on AS [autoshrink],
			is_auto_create_stats_on AS AutoCreateStatisticsEnabled,
			is_auto_update_stats_on AS AutoUpdateStatisticsEnabled,
			is_in_standby  AS [standby],
			is_cleanly_shutdown AS [cleanly_shutdown]
			FROM sys.databases DB
			--where database_id = db_id()
			ORDER BY database_id DESC, NAME
		' 
		set @qry2= 'select * from openquery(['+ @srvs +'],'''+@qry +''') where dbName = '''+ @dbname+ ''''
		insert into #temp1
		EXEC ( @qry2)
		set @alternative =1
	END --end alternative =1
END --end principal/non-mirrored databases
ELSE
BEGIN --mirror of offline dbs
if @alternative =0
	BEGIN
	print @dbname + '; ' + case when @mirror <>1 then 'deze db is een mirror' else 'deze db is niet online maar heeft status ['+ @dbstatus +']' end
	set @qry = 
		'
	select 
			db_name(db.database_id) AS dbName,
			db.database_id,
			 state_desc as status,
			 state_desc,
			null AS DataFiles,
			null AS [size],
			null AS [Data MB],
			null AS [DataSpaceUsage],
			null AS [SpaceAvailable],
			null AS LogFiles,
			null AS [Log MB],
			null AS [logUsedMB],
			null AS [logAvailable_MB],
			user_access_desc AS [User access],
			SUSER_SNAME(owner_sid) as owner,
			collation_name as collation,
			recovery_model_desc AS [Recoverymodel],
			compatibility_level as compatibilitylevel,
			case when mirroring_role is null then 0 else 1 end  as ismirroringenabled,
			mirroring_role_desc as mirroringrole,
			isnull(mirroring_role_sequence,0) as MirroringRoleSequence,
			create_date AS createdate,
			null as LastBackupDate,
			null as LastDifferentialBackupDate,
			null as LastLogBackupDate,
			is_fulltext_enabled AS [fulltext],
			is_auto_close_on AS [autoclose],
			page_verify_option_desc AS PageVerifyOption,
			is_read_only AS [read_only],
			log_reuse_wait_desc AS LogReuseWaitStatus,
			is_auto_shrink_on AS [autoshrink],
			is_auto_create_stats_on AS AutoCreateStatisticsEnabled,
			is_auto_update_stats_on AS AutoUpdateStatisticsEnabled,
			is_in_standby  AS [standby],
			is_cleanly_shutdown AS [cleanly_shutdown]
			FROM sys.databases DB
			INNER JOIN sys.database_mirroring B
			ON db.database_id=B.database_id
			where db.database_id = '+ cast(@dbid as varchar(3)) + '
			ORDER BY db.database_id DESC, NAME
	'

		--Execute several statements on the linked server.

		set @qry2= 'exec ( '''+ @qry +''') AT ['+ @srvs +']'
		insert into #temp1
		EXEC ( @qry2)
	END --end alternative <>1
	if @alternative =1
	BEGIN
	--Alternate query for servers where MSDTC is not correctly configured (execute AT not possible)

	set @qry = 
	'
	select 
			db_name(db.database_id) AS dbName,
			db.database_id,
			 state_desc as status,
			 state_desc,
			null AS DataFiles,
			null AS [size],
			null AS [Data MB],
			null AS [DataSpaceUsage],
			null AS [SpaceAvailable],
			null AS LogFiles,
			null AS [Log MB],
			null AS [logUsedMB],
			null AS [logAvailable_MB],
			user_access_desc AS [User access],
			SUSER_SNAME(owner_sid) as owner,
			collation_name as collation,
			recovery_model_desc AS [Recoverymodel],
			compatibility_level as compatibilitylevel,
			case when mirroring_role is null then 0 else 1 end  as ismirroringenabled,
			mirroring_role_desc as mirroringrole,
			isnull(mirroring_role_sequence,0) as MirroringRoleSequence,
			create_date AS createdate,
			null as LastBackupDate,
			null as LastDifferentialBackupDate,
			null as LastLogBackupDate,
			is_fulltext_enabled AS [fulltext],
			is_auto_close_on AS [autoclose],
			page_verify_option_desc AS PageVerifyOption,
			is_read_only AS [read_only],
			log_reuse_wait_desc AS LogReuseWaitStatus,
			is_auto_shrink_on AS [autoshrink],
			is_auto_create_stats_on AS AutoCreateStatisticsEnabled,
			is_auto_update_stats_on AS AutoUpdateStatisticsEnabled,
			is_in_standby  AS [standby],
			is_cleanly_shutdown AS [cleanly_shutdown]
			FROM sys.databases DB
			INNER JOIN sys.database_mirroring B
			ON db.database_id=B.database_id
			--where db.database_id = '+ cast(@dbid as varchar(3)) + '
			ORDER BY db.database_id DESC, NAME
	' 
set @qry2= 'select * from openquery(['+ @srvs +'],'''+@qry +''') where dbName = '''+ @dbname+ ''''
	insert into #temp1
	EXEC ( @qry2)
	set @alternative =1
	END
	END --end mirrordbs

END TRY
BEGIN CATCH
set @error = @@error
Print 'error opgetreden: errornr ' + cast(error_number() as varchar(20)) + '; '+ error_message()
--Alternate query for servers where MSDTC is not correctly configured (execute AT not possible); 
--this script is triggered when @alternative =0 but an error occurs

set @qry = 
	'
		select 
		CONVERT(VARCHAR(300), DB.name) AS dbName,
		database_id,
		CONVERT(VARCHAR(30), DATABASEPROPERTYEX(DB.name, ''''status'''')) as status ,
		state_desc,
		(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS DataFiles,
		(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name ) AS [size],
		(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
		--(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Dataused MB],
		(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataSpaceUsage],
		(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [SpaceAvailable],
		--(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [DataAvailable_MB],
		(SELECT COUNT(1) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS LogFiles,
		--(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''rows'''') AS [Data MB],
		(SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [Log MB],
		(SELECT SUM((fileproperty(name,''''SpaceUsed'''')*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logUsedMB],
		(SELECT SUM(((Size-fileproperty(name,''''SpaceUsed''''))*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = ''''log'''') AS [logAvailable_MB],
		--sum(case when type = 0 then CONVERT(decimal(12,2),round(fileproperty(name,''''SpaceUsed'''')/128.000,2)) else 0 end)
		user_access_desc AS [User access],
		SUSER_SNAME(owner_sid) as owner,
		collation_name as collation,
		recovery_model_desc AS [Recoverymodel],
		compatibility_level as compatibilitylevel,
		(select case when mirroring_role is null then 0 else 1 end from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as ismirroringenabled,
		(select mirroring_role_desc from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as mirroringrole,
		(select mirroring_role_sequence from sys.database_mirroring where DB_NAME(database_id) = DB.name ) as MirroringRoleSequence,
		--CONVERT(VARCHAR(20), create_date, 103) + '''' '''' + CONVERT(VARCHAR(20), create_date, 108) AS createdate,
		create_date AS createdate,
		--(select top 1 CONVERT(VARCHAR(20), backup_start_date, 103) + '''' '''' + CONVERT(VARCHAR(20), backup_start_date, 108) FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
		(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''D'''' ORDER BY backup_set_id DESC) as LastBackupDate,
		(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''I'''' ORDER BY backup_set_id DESC) as LastDifferentialBackupDate,
		(select top 1 backup_start_date  FROM msdb..backupset BK WHERE BK.database_name = DB.name and TYPE = ''''L'''' ORDER BY backup_set_id DESC) as LastLogBackupDate,
		is_fulltext_enabled AS [fulltext],
		is_auto_close_on AS [autoclose],
		page_verify_option_desc AS PageVerifyOption,
		is_read_only AS [read_only],
		log_reuse_wait_desc AS LogReuseWaitStatus,
		is_auto_shrink_on AS [autoshrink],
		is_auto_create_stats_on AS AutoCreateStatisticsEnabled,
		is_auto_update_stats_on AS AutoUpdateStatisticsEnabled,
		is_in_standby  AS [standby],
		is_cleanly_shutdown AS [cleanly_shutdown]
		FROM sys.databases DB
		--where database_id = db_id()
		ORDER BY database_id DESC, NAME
	' 
set @qry2= 'select * from openquery(['+ @srvs +'],'''+@qry +''') where dbName = '''+ @dbname+ ''''
	insert into #temp1
	EXEC ( @qry2)
	set @alternative =1
set @error =''
END CATCH

END --END DB

	
insert into #temp2
select @date,@sname,@ins,@iid,* from #temp1
truncate table #temp1
	
	Set @qry =''
	Set @qry2 =''	
	EXEC master.dbo.sp_dropserver @server=@srvs, @droplogins='droplogins'
	set @alternative = @alternative_default --connect to the next server using the default msdtc-option
--	update mon_Instance 
--set Remarks =  '', CheckDate= @date
--where id = @iid

END TRY
BEGIN CATCH
set @error = @@error
Print 'error opgetreden: errornr ' + cast(error_number() as varchar(20)) + '; '+ error_message()
--update Instances 
--set Remarks =  'Error ' + cast(error_number() as varchar(20)) + '; '+ error_message(),
--CheckDate= @date
--where id = @iid
	Set @qry =''
	Set @qry2 =''	
	EXEC master.dbo.sp_dropserver @server=@srvs, @droplogins='droplogins'

END CATCH
END --END INSTANCE
--select * from #temp2
drop table #dbs

INSERT INTO [DatabasePropsStatic]
           ([Date]
           ,[SERVER]
           ,[Instance]
           ,[Instance_id]
           ,[Db]
           ,[DbId]
           ,[AutoClose]
           ,[AutoShrink]
           ,[Owner]
           ,[Status]
           ,[CompatibilityLevel]
           ,[CreateDate]
           ,[AutoCreateStatisticsEnabled]
           ,[AutoUpdateStatisticsEnabled]
           ,[Collation]
           ,[RecoveryModel]
           ,[IsMirroringEnabled]
           ,[rank]
           ,[PageVerifyOption])
 select [Date]
           ,[SERVER]
           ,[Instance]
           ,iid
           ,dbname
           ,[DbId]
           ,[AutoClose]
           ,[AutoShrink]
           ,[Owner]
           ,[Status]
           ,[CompatibilityLevel]
           ,[CreateDate]
           ,[AutoCreateStatisticsEnabled]
           ,[AutoUpdateStatisticsEnabled]
           ,[Collation]
           ,[RecoveryModel]
           ,[IsMirroringEnabled]
           ,0
           ,[PageVerifyOption]  from #temp2
 
 
 INSERT INTO [DatabasePropsDynamic]
           ([date]
           ,[instance_id]
           ,[dbid]
		   ,[db]
           ,[Size]
           ,[SpaceAvailable]
           ,[DataSpaceUsage]
           ,[IndexSpaceUsage]
           ,[LastBackupDate]
           ,[LastDifferentialBackupDate]
           ,[LastLogBackupDate]
           ,[LogReuseWaitStatus]
           ,[MirroringRoleSequence]
           ,[rank]
           ,[Status]
           ,[MirroringRole]) 
           
Select [date]
           ,iid
           ,[dbid]
		   ,dbname
           ,[Size]
           ,[SpaceAvailable]
           ,[DataSpaceUsage]
           ,null
           ,isnull([LastBackupDate],'1980-01-01 00:00:00')
      ,isnull([LastDifferentialBackupDate],'1980-01-01 00:00:00')
      ,isnull([LastLogBackupDate],'1980-01-01 00:00:00')
      ,[LogReuseWaitStatus]
      ,isnull([MirroringRoleSequence],0)
           ,0
           ,[Status]
           ,[MirroringRole]        
           from #temp2 
           
 
--===================
-- update checkdate for known and still existing databases

Update TBL_Databases
set Date_checked = a.date
--select * 
from TBL_Databases t inner join 
(
select max([Date]) date
           ,iid
           ,DbId
		   ,dbname,createdate
           from #temp2
  group by iid,dbid,dbname,createdate
  ) a
  on a.iid =t.Instance_id and a.dbid=t.dbid and a.dbname=t.db and a.createdate=t.date_created 
  where date_deleted is null
  and Date_checked <> a.date

--===================
-- update deleted and recreated databases where the dbid stays the same (restores etc)

Update TBL_Databases
set Date_deleted = a.createdate
--select * 
from TBL_Databases t inner join 
(
select max([Date]) date
           ,iid
           ,DbId
		   ,dbname,createdate
           from #temp2
  group by iid,dbid,dbname,createdate
  ) a
  on a.iid =t.Instance_id and a.dbid=t.dbid and a.dbname=t.db --and a.createdate=t.date_created 
  where date_deleted is null
  and  a.createdate<>t.date_created

--===================
-- insert new/modified databases
 
insert into TBL_Databases  (Instance_id, dbid, db, date_created, Date_checked)
select		iid
--,dbo.udf_instname(iid)
           ,a.DbId
           ,a.dbname
           ,a.createDate
           ,a.date  
from TBL_Databases t
right outer join
	(select  iid
           ,DbId
           ,dbname
           ,[CreateDate]
           ,max([Date]) date
           from #temp2
  group by iid,dbid,dbname,createdate
  ) a
 on a.iid =t.Instance_id and a.dbid=t.dbid and a.dbname=t.db and a.createdate=t.date_created
  where t.Instance_id is null

--==================
-- update deleted databases

update TBL_Databases
set date_deleted = getdate() , Date_checked =  getdate()
--select dbo.udf_instname(instance_id),* 
from TBL_Databases t
left outer join
	(select  iid
           ,DbId
           ,dbname
           ,[CreateDate]
           ,max([Date]) date
           from #temp2
  group by iid,dbid,dbname,createdate
  ) a
  on a.iid =t.Instance_id and a.dbid=t.dbid and a.dbname=t.db and a.createdate=t.date_created
  where a.Iid is null
and t.date_deleted is null
and t.Instance_id in (select distinct iid from #temp2)
   
   drop table #temp1
   drop table #temp2        
END



