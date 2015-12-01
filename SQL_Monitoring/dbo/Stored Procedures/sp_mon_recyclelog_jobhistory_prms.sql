
CREATE PROC [dbo].[sp_mon_recyclelog_jobhistory_prms]
AS
BEGIN
print 'Updaten jobdata in monitoringsysteem - SQL 7 en SQL2000'
EXEC	 [dbo].[sp_mon_Jobs_7_2000]

print 'Updaten jobdata in monitoringsysteem - SQL2005 en hoger'
EXEC	 [dbo].[sp_mon_Jobs_2005]


DECLARE @cmd varchar(4000), @script varchar(4000)

if exists (select name from sys.tables where name = 'Temp_recyclelog_jobhistory_prms')
	BEGIN
	DROP TABLE Temp_recyclelog_jobhistory_prms
	END

CREATE TABLE Temp_recyclelog_jobhistory_prms(
	server varchar(100),versie char(4),cmd varchar(4000))


set @script='
USE MASTER;EXEC xp_instance_regwrite N''HKEY_LOCAL_MACHINE'', N''Software\Microsoft\MSSQLServer\MSSQLServer'', N''NumErrorLogs'', REG_DWORD, 13;
USE [msdb];EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000, 	@jobhistory_max_rows_per_job=500


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' 
AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', 
@name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
DECLARE @jobId BINARY(16)
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N''SQL_Mon_Recycle SQL Server Error Logs'', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=0, 
@notify_level_netsend=0, 
@notify_level_page=0, 
@delete_level=0, 
@description=N''This job will Recycle SQL Server Error Logs'', 
@category_name=N''[Uncategorized (Local)]'', 
@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, 
@step_name=N''Recycle SQL Server Error Log'', 
@step_id=1, 
@cmdexec_success_code=0, 
@on_success_action=1, 
@on_success_step_id=0, 
@on_fail_action=2, 
@on_fail_step_id=0, 
@retry_attempts=0, 
@retry_interval=0, 
@os_run_priority=0, @subsystem=N''TSQL'', 
@command=N''EXEC dbo.sp_cycle_errorlog'', 
@database_name=N''msdb'', 
@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Wekelijks recycle errorlog'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20120806, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

'
--'sqlcmd -S ' + server + 
set @cmd =' -E -Q "' + @script +'"'
--select @script
--select @cmd

insert into Temp_recyclelog_jobhistory_prms (server, versie,cmd)
select server, versie,'sqlcmd -S ' + server +' '+  @cmd
 from Mon_Instance 
where id not in (select  instance_id from mon_jobs
	where jobname like 'SQL_Mon_Recycle SQL Server Error Logs')
and Controle = 1
and versie not like '7.00'
order by server

END

