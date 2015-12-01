CREATE      PROC [dbo].[sp_create_maintjobs] 
				@plandb NVARCHAR(128)= NULL,  -- = databasenaam
				@backuptijd INT = NULL, 
				@trnstarttijd INT = NULL, 
				@trninterval INT = NULL,
				@reorgtijd INT = NULL, 
				@integertijd INT = NULL,
				@DelFullBack varchar(10) = '72',
				@DelLogBack varchar(10) = '72'

AS 

-- ================================================================
-- 25-08-2010 A vd Berg
-- bij ontbreken van benodigde sp's voor reorganisatie wordt de reorganisatiejob gedisabled aangemaakt
-- ================================================================



SET NOCOUNT ON 
DECLARE @planname NVARCHAR(128), 
		@trneindtijd INT , 
		@trndagen INT , 
		@reorgdag INT , 
		@reorgschedule_active INT,
		@integerdag INT  

DECLARE @RC INT   -- Resultcode 
DECLARE @plancommand NVARCHAR(3200), @planstepname NVARCHAR(128) 
DECLARE @planjob VARCHAR(128), @outputjob_id uniqueidentifier, @plandesc NVARCHAR(512) 
DECLARE @planschedulename NVARCHAR(128),
	 @planfreqtype INT,
	 @planfreqinterval INT,
	 @planfreqsubdays INT,
	 @planfreqsubinterval INT, @Planfreq_relative_interval INT, @planreoccur INT, @plands VARCHAR(128), @def_backupdir VARCHAR(500), @regset varchar(500)
DECLARE @servernaam VARCHAR (128)
DECLARE @enable INT
DECLARE @jobcat VARCHAR(50)
DECLARE @EmOp VARCHAR(50)
DECLARE @JobOwn VARCHAR(50)
DECLARE @dbtype varchar(1)

DECLARE @LogDir nvarchar(255) 

EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'ErrorLogFile', @param = @LogDir OUTPUT 
SET @LogDir = SUBSTRING(@LogDir,1,CHARINDEX('SQLAGENT.OUT',@LogDir) -1 ) 
SET @servernaam = CONVERT (VARCHAR (128),SERVERPROPERTY ('ServerName'))
SET @jobcat = 'ICTRO SQL-Beheer' 
SET @EmOp = 'DBA'
SET @JobOwn = 'sa'
--------------------------------------------------------------------------------------------------- 
-- Backup tijd moet gevuld zijn 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(UPPER(@plandb),'HELP') = 'HELP' 
BEGIN 
        PRINT 'Parameters van deze stored procedure zijn' 
        PRINT '@plandb         De naam van de database die gebackup wordt' 
        PRINT '                   Indien leeg dan meot @Indtype gevuld zijn' 
        PRINT '@Backuptijd     Tijd waarop full backup start' 
        PRINT '                   Indien niet gevuld betekent dat geen Full Backup gewenst is' 
        PRINT '                   Een bestaande Full backup wordt verwijderd!' 
        PRINT '                   Indien gevuld dan moet deze een waarde van HHMMSS bevatten' 
        PRINT '                   0 is dus 00:00:00, 100 is 00:01:00, 10000 is 1:00:00' 
        PRINT '                   Mogelijke waarden liggen tussen 0 en 235959' 
        PRINT '@trnstarttijd   Geeft de starttijd van de transactielog backup aan' 
        PRINT '                   Indien niet gevuld betekent dat geen Transactie log Backup gewenst is' 
        PRINT '                   Een bestaande Transactie backup wordt verwijderd!' 
        PRINT '                   Indien gevuld dan moet deze een waarde van HHMMSS bevatten' 
        PRINT '                   0 is dus 00:00:00, 100 is 00:01:00, 10000 is 1:00:00' 
        PRINT '                   Mogelijke waarden liggen tussen 0 en 235959' 
        PRINT '@trninterval    Geeft het aantal minuten tussen de transactielog backups aan' 
        PRINT '                   Wordt alleen gebruikt als @trnstarttijd gevuld is' 
        PRINT '                   Indien gevuld dan moet deze een waarde kleiner dan  bevatten' 
        PRINT '                   Indien niet geuld en @trnstarttijd is gevuld wordt deze 15'        
        PRINT '                   Indien groter dan 60 dan wordt het naar beneden afgerond op uren' 
        PRINT '@reorgtijd      Geeft de tijd aan waarop de reoganisatie start' 
        PRINT '                   Indien niet gevuld betekent dat geen reorganisatie is' 
        PRINT '                   Een bestaande reorganisatie wordt verwijderd!' 
        PRINT '                   Indien gevuld dan moet deze een waarde van HHMMSS bevatten' 
        PRINT '                   0 is dus 00:00:00, 100 is 00:01:00, 10000 is 1:00:00' 
        PRINT '                   Mogelijke waarden liggen tussen 0 en 235959' 
        PRINT '@integertijd    Geeft de tijd aan waarop de integriteitscheck start' 
        PRINT '                   Indien niet gevuld betekent dat geen integriteitscheck is gewenst' 
        PRINT '                   Een bestaande intergriteitscheck wordt verwijderd!' 
        PRINT '                   Indien gevuld dan moet deze een waarde van HHMMSS bevatten' 
        PRINT '                   0 is dus 00:00:00, 100 is 00:01:00, 10000 is 1:00:00' 
        PRINT '                   Mogelijke waarden liggen tussen 0 en 235959' 
		PRINT '@DelFullBack		Geeft aan na hoeveel uur de Full backupbestanden verwijderd worden, default 72 uur = 3 dagen'
		PRINT '					Voor systemdatabases wordt deze termijn later in het script verhoogd naar 186 uur = 1 week'
		PRINT '@DelLogBack		Geeft aan na hoeveel uur de Tlog backupbestanden verwijderd worden, default 72 uur = 3 dagen'
        PRINT '' 
        PRINT 'Aanroep voorbeeld:' 
        PRINT ' exec sp_create_maintjobs ''Test'' , 220000, 070000, 15,10500, 000500, 72, 24' 
        PRINT '   Maakt maintenancejobs aan voor de aangeven database waarbij:' 
        PRINT '         Full Backup om 22 uur start, dagelijks' 
        PRINT '         Transactie log Backup van 7 uur tot 23:59:59 (default) iedere 15 minuten ' 
        PRINT '         Reorganisatie om 1:05 uur op zondag (default) start' 
        PRINT '         Integrity check om 0:05 uur op zondag (default) start'
		PRINT '			Full backups na 72 uur verwijderd'
		PRINT '			TLOG backups na 24 uur verwijderd' 
        RETURN(1) 
END 
--------------------------------------------------------------------------------------------------- 
-- Stap 1:  Voorwaarden checken, bij probleem direct stoppen 
--------------------------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------------------------- 
-- Backup tijd moet gevuld zijn 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(@backuptijd,0) > 235959 
BEGIN 
        PRINT '@backuptijd bevat een waarde groter dan 235959' 
        RETURN(1) 
END 
--------------------------------------------------------------------------------------------------- 
-- Transactie log backup starttijd moet gevuld zijn 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(@trnstarttijd,0) > 235959 
BEGIN 
        PRINT '@trnstarttijd bevat een waarde groter dan 235959' 
        RETURN(1) 
END 
--------------------------------------------------------------------------------------------------- 
-- Transactie interval 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(@trninterval,15) > 1440 
BEGIN 
        PRINT '@trninterval mag de 24 uur niet overschrijden' 
        RETURN(1) 
END 
SET @trninterval = ISNULL(@trninterval,15) 
--------------------------------------------------------------------------------------------------- 
-- Reorganisatie tijd moet kleiner dan 235959 zijn 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(@reorgtijd,0) > 235959 
BEGIN 
        PRINT '@reorgtijd bevat een waarde groter dan 235959' 
        RETURN(1) 
END 

--------------------------------------------------------------------------------------------------- 
-- Integrity check tijd moet kleiner dan 235959 zijn 
--------------------------------------------------------------------------------------------------- 
IF ISNULL(@integertijd,0) > 235959 
BEGIN 
        PRINT '@integertijd bevat een waarde groter dan 235959' 
        RETURN(1) 
END 

-----------------------------------
--  Defaults 
----------------------------------
set @dbtype = 'u' --userdb
if @plandb in ('master','msdb','model','tempdb') set @dbtype = 's' --systemdb

if @dbtype = 's'  --default backupbewaartermijn systeemdbs wordt aangepast 
	set @DelFullBack = '168' -- 1 week = 168 uur

SET @planname = 'Maintenanceplan db '+ @plandb
SET @trneindtijd = 235959
SET @trndagen = 7 
SET @reorgdag = 7 
SET @integerdag = 7 

--------------------------------------------------------------------------------------------------- 
-- Mail operator ophalen 
--------------------------------------------------------------------------------------------------- 
DECLARE @mailoper int 
IF (SELECT COUNT(*) FROM msdb.dbo.sysoperators WHERE name = @EmOp ) = 0 
BEGIN 
        PRINT 'DBA operator bestaat niet, wordt nu aangemaakt' 
        EXEC @RC = msdb.dbo.sp_add_operator @EmOp, 1, 'test' 
END             
SELECT @mailoper = [id] FROM msdb.dbo.sysoperators WHERE name = @EmOp 
---------------------------------------------------------------------------------------------------  -- Categories aanmaken 
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = @jobcat ) = 0 
BEGIN 
        EXEC @RC = [msdb].[dbo].[sp_add_category] @name = @jobcat 
        IF @RC != 0 RETURN(1) 
END             
--------------------------------------------------------------------------------------------------- 
-- Einde voorwaarden 
--------------------------------------------------------------------------------------------------- 


BEGIN TRANSACTION


--------------------------------------------------------------------------------------------------- 
-- Stap 2:  Plan aanmaken 
--------------------------------------------------------------------------------------------------- 

--------------------------------------------------------------------------------------------------- 
-- Plan aanmaken als dit nog niet bestaat. Bestaat het dan de uniqueidentifier ophalen 
--------------------------------------------------------------------------------------------------- 
DECLARE   @dbplanid UNIQUEIDENTIFIER 
IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplans WHERE plan_name= @planname) = 0 
        EXECUTE  msdb..sp_add_maintenance_plan @planname ,@plan_id= @dbplanid OUTPUT 
ELSE 
        SELECT @dbplanid = plan_id FROM msdb.dbo.sysdbmaintplans WHERE plan_name= @planname 

--------------------------------------------------------------------------------------------------- 
-- Eerst alle databases verwijderen van maintence plan databases link . 
--------------------------------------------------------------------------------------------------- 
DELETE FROM msdb.dbo.sysdbmaintplan_databases WHERE plan_id = @dbplanid 
--------------------------------------------------------------------------------------------------- 
-- Combinatie van maintenance plan en database aanmaken 
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_databases WHERE plan_id = @dbplanid AND database_name = @plandb  ) = 0 AND @plandb IS NOT NULL

BEGIN 
        EXEC @RC = [msdb].[dbo].sp_add_maintenance_plan_db  @dbplanid, @plandb 
        IF @RC != 0 RETURN(1) 
END             
--------------------------------------------------------------------------------------------------- 
-- Combinatie van maintenance plan en All user database aanmaken 
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_databases WHERE plan_id = @dbplanid ) < 1 
BEGIN 
        INSERT msdb.dbo.sysdbmaintplan_databases (plan_id, database_name) VALUES (@dbplanid, @plands) 
END 
PRINT   'Maintenance plan ''' + @planname + ''' created. The id for the maintenance plan is: '+convert(varchar(256),@dbplanid) 
--------------------------------------------------------------------------------------------------- 
-- Bepaal de backupdirectory naam
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM master..sysservers WHERE srvid = 0  and srvname LIKE '%' + '\' +'%' ) > 0
      SET @regset = 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer'
ELSE
	SET @regset = 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer'
IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE name LIKE '#tmp_TrueFalse%') 
BEGIN
      DROP TABLE #tmp_TrueFalse
END
CREATE TABLE #tmp_TrueFalse
(
      IND     INT
)
CREATE TABLE #tmp_instance_regread
(
      Value           VARCHAR(500),
      Data            VARCHAR(500)
)
INSERT INTO #tmp_TrueFalse  EXEC master..xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\BackupDirectory'
IF ( SELECT 1 FROM #tmp_TrueFalse WHERE IND = 0 ) IS NOT NULL
BEGIN
      INSERT INTO #tmp_instance_regread (Value, Data)
      EXEC master..xp_instance_regread N'HKEY_LOCAL_MACHINE', @regset, N'BackupDirectory'
END
SELECT @def_backupdir = '"' +  SUBSTRING(LTRIM(RTRIM(Data)),1,LEN(Data)) + '"'  from #tmp_instance_regread
--------------------------------------------------------------------------------------------------- 
-- You dont want to use -UseDefDir inc ase of an upgrade of a cluster service the backup dierectory is
-- reset to the default SQL installation and the regstry setting is gone. In taht case the backups do not
-- go to the correct directory
-- THe following statement is used in case of no setting
--------------------------------------------------------------------------------------------------- 
IF @def_backupdir IS NULL SET @def_backupdir = '-UseDefDir'
if right(@def_backupdir,1) = '\'  set @def_backupdir = substring(@def_backupdir,1,len(@def_backupdir)-1)


--------------------------------------------------------------------------------------------------- 
-- Stap 3:  Full backup aanmaken 
--------------------------------------------------------------------------------------------------- 
SET @outputjob_id = NULL        -- Initialiseren 
--------------------------------------------------------------------------------------------------- 
-- Kijk of backup job bestaat in het maintenance plan 
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id in ( SELECT job_id FROM msdb.dbo.sysjobsteps WHERE command like '%-BkUpDB%' )  ) > 0 

BEGIN 
        SELECT @outputjob_id = job_id FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id in ( SELECT job_id FROM msdb.dbo.sysjobsteps WHERE command like '%-BkUpDB%' )
END             

--------------------------------------------------------------------------------------------------- 
-- Job voor Full backup bekijken 
--------------------------------------------------------------------------------------------------- 
IF ( @backuptijd IS NOT NULL ) 
BEGIN 
        SET @planjob = 'Backup DB ''' + ISNULL(@plandb, @plands) + '''' 
        SET @plandesc = 'Full Backup van ' +  ISNULL(@plandb, @plands) + ' aangemaakt vanuit database beheerscript'

        ------------------------------------------------------------------------------------------- 
        -- Job voor Full backup aanmaken 
        ------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NULL ) 
        BEGIN 
                IF (SELECT COUNT(*) FROM msdb.dbo.sysjobs WHERE name = @planjob  ) = 0 
                BEGIN 
                        EXEC msdb.dbo.sp_add_job  @job_name = @planjob , 
                                 @enabled = 1, 
                                 @description =  @plandesc, 
                                 @start_step_id = 1 , 
                                 @category_name = @jobcat , 
                                 @owner_login_name = @JobOwn , 
                                 @notify_level_eventlog = 2 , 
                                 @notify_level_email =2, 
                                 @notify_email_operator_name = @EmOp , 
                                 @delete_level = 0 , 
                                 @job_id =  @outputjob_id OUTPUT  
                        EXECUTE @RC = msdb.dbo.sp_add_jobserver @job_id = @outputjob_id, @server_name = @servernaam
                        IF @outputjob_id IS NULL RETURN(1) 
                END             
                ELSE 
                        SELECT @outputjob_id = job_id FROM msdb.dbo.sysjobs WHERE name = @planjob 
        END 
        ------------------------------------------------------------------------------------------- 
        -- Job voor Full backup aanpassen zodat de optie goed staan 
        ------------------------------------------------------------------------------------------- 
        EXEC msdb.dbo.sp_update_job  @job_id = @outputjob_id, 
                        @new_name = @planjob , 
                        @enabled = 1, 
                        @description =  @plandesc, 
                        @start_step_id = 1 , 
                        @category_name = @jobcat , 
                        @owner_login_name = @JobOwn , 
                        @notify_level_eventlog = 2 , 
                        @notify_level_email =2, 
                        @notify_email_operator_name = @EmOp , 
                        @delete_level = 0 
        ------------------------------------------------------------------------------------------- 
    -- Koppelen van de job aan het maintenance plan 
        ------------------------------------------------------------------------------------------- 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id = @outputjob_id ) = 0 
 		BEGIN
	                EXEC @RC = msdb.dbo.sp_add_maintenance_plan_job @dbplanid, @outputjob_id 
        	        IF @RC != 0 RETURN(1) 
        END             

	    SET @plancommand = 'EXECUTE master.dbo.xp_sqlmaint N''-PlanID ' + LTRIM(RTRIM(convert(varchar(36),@dbplanid)))+ ' -Rpt "'+ @LogDir + @planname + '4.txt" -DelTxtRpt 4WEEKS -WriteHistory  -VrfyBackup -BkUpMedia DISK -BkUpDB ' + @def_backupdir + ' -DelBkUps ' + @DelFullBack + 'HOURS -CrBkSubDir -BkExt "BAK"'''
        set @planstepname = 'Full Backup step van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobsteps WHERE job_id = @outputjob_id and step_id = 1  ) = 0 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_add_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        ELSE 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_update_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        IF @RC != 0 RETURN(1) 


        --------------------------------------------------------------------------------------------------- 
        -- Jobschedule backup aanmaken of wijzigen 
        --------------------------------------------------------------------------------------------------- 
        SET @planschedulename = 'Full Backup schedule van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobschedules WHERE job_id = @outputjob_id ) = 0 

        BEGIN 
				if @dbtype = 'u'
                EXEC @RC = msdb.dbo.sp_add_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = 4, 
                        @freq_interval = 1, 
                        @freq_subday_type = 0, 
                        @freq_subday_interval = 0, 
                        @active_start_time = @backuptijd, 
						@freq_recurrence_factor=1
				if @dbtype = 's' --systemdb
                EXEC @RC = msdb.dbo.sp_add_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = 8,			--wekelijks
                        @freq_interval = 1, 
                        @freq_subday_type = 1,	--zondag 
                        @freq_subday_interval = 0, 
                        @active_start_time = @backuptijd ,
						@freq_recurrence_factor=1
        END 
        ELSE 
        BEGIN 
				if @dbtype = 'u'
                EXEC @RC = msdb.dbo.sp_update_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = 4, 
                        @freq_interval = 1, 
                        @freq_subday_type = 0, 
                        @freq_subday_interval = 0, 
                        @active_start_time = @backuptijd ,
						@freq_recurrence_factor =1

				if @dbtype = 's'
                EXEC @RC = msdb.dbo.sp_update_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = 8, 
                        @freq_interval = 1, 
                        @freq_subday_type = 1, 
                        @freq_subday_interval = 0, 
                        @active_start_time = @backuptijd ,
						@freq_recurrence_factor =1
        END 
        IF @RC != 0 RETURN(1) 
END 
ELSE 
BEGIN 
        --------------------------------------------------------------------------------------------------- 
        -- Job verwijderen als die mocht bestaan 
        --------------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NOT NULL ) 
        BEGIN 
                ------------------------------------------------------------------------------------------- 
                -- Job verwijderen, niet vergeten om het maintenance plan job te verwijderen                  ------------------------------------------------------------------------------------------- 
                EXEC msdb..sp_delete_job @job_id = @outputjob_id                
                SET @outputjob_id = NULL 
        END 
END 
PRINT  'Job '''+ @planjob + ''' created. The job_id for full backup = '+ ISNULL(convert(varchar(256),@outputjob_id),'Niet van toepassing') 
--------------------------------------------------------------------------------------------------- 
-- Stap 4:  Transactielog backup aanmaken 
--------------------------------------------------------------------------------------------------- 
SET @outputjob_id = NULL        -- Initialiseren 
--------------------------------------------------------------------------------------------------- 
-- Kijk of backup job bestaat in het maintenance plan 
--------------------------------------------------------------------------------------------------- 
IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id in ( SELECT job_id FROM msdb.dbo.sysjobsteps WHERE command like '%-BkUpLog%' )  ) > 0 

BEGIN 
        SELECT @outputjob_id = job_id FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id in ( SELECT job_id FROM msdb.dbo.sysjobsteps WHERE command like '%-BkUpLog%' )

END             

--------------------------------------------------------------------------------------------------- 
-- Job voor Transactie log backup bekijken 
--------------------------------------------------------------------------------------------------- 
IF ( @trnstarttijd IS NOT NULL ) 
BEGIN 
        SET @planjob = 'Backup TXN ''' + ISNULL(@plandb, @plands) + '''' 
        SET @plandesc = 'Transactie log backup van ' +  ISNULL(@plandb, @plands) + ' aangemaakt door database beheerscript'

	IF DATABASEPROPERTYEX(@plandb,'Recovery') = 'SIMPLE' 
	BEGIN 
	SET @enable = 0
	PRINT 'Recovery model voor Database %s  is SIMPLE. Transaction Log backup job wordt disabled'
	END
	ELSE  
		IF @dbtype = 's'
		BEGIN 
		SET @enable = 0
		PRINT @plandb + ' is een systeemdatabase. Transaction Log backup job wordt disabled'
		END
		ELSE
		SET @enable = 1

        ------------------------------------------------------------------------------------------- 
        -- Job voor Full backup aanmaken 
        ------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NULL ) 
        BEGIN 
                IF (SELECT COUNT(*) FROM msdb.dbo.sysjobs WHERE name = @planjob  ) = 0 
                BEGIN 
                        EXEC msdb.dbo.sp_add_job  @job_name = @planjob , 
                                 @enabled = @enable, 
                                 @description =  @plandesc, 
                                 @start_step_id = 1 , 
                                 @category_name = @jobcat , 
                                 @owner_login_name = @JobOwn , 
                                 @notify_level_eventlog = 2 , 
                                 @notify_level_email =2, 
                                 @notify_email_operator_name = @EmOp , 
                                 @delete_level = 0 , 
                                 @job_id =  @outputjob_id OUTPUT  
                        EXECUTE @RC = msdb.dbo.sp_add_jobserver @job_id = @outputjob_id, @server_name = @servernaam 
                        IF @outputjob_id IS NULL RETURN(1) 
                END             
                ELSE 
                        SELECT @outputjob_id = job_id FROM msdb.dbo.sysjobs WHERE name = @planjob 
        END 
        ------------------------------------------------------------------------------------------- 
        -- Job voor Full backup aanpassen zodat de opties goed staan 
        ------------------------------------------------------------------------------------------- 
        EXEC msdb.dbo.sp_update_job  @job_id = @outputjob_id, 
                        @new_name = @planjob , 
                        @enabled = @enable, 
                        @description =  @plandesc, 
                        @start_step_id = 1 , 
                        @category_name = @jobcat , 
                        @owner_login_name = @JobOwn , 
                        @notify_level_eventlog = 2 , 
                        @notify_level_email =2, 
                        @notify_email_operator_name = @EmOp , 
                        @delete_level = 0 
        ------------------------------------------------------------------------------------------- 
        -- Koppelen van de job aan het maintenance plan 
	-- Indien de job via sqlbackup extended stored procedure wordt gemaakt de job niet aan het maintenance plan koppelen
        ------------------------------------------------------------------------------------------- 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysdbmaintplan_jobs WHERE plan_id = @dbplanid AND job_id = @outputjob_id ) = 0 
        BEGIN 
		if ( select count(*) from master..sysobjects where name = 'sqlbackup' and xtype = 'X' and @plandb IS NOT NULL ) = 0 
		BEGIN
	                EXEC @RC = msdb.dbo.sp_add_maintenance_plan_job @dbplanid, @outputjob_id 
        	        IF @RC != 0 RETURN(1) 
		END
        END             
        ------------------------------------------------------------------------------------------- 
        -- Jobstep backup aanmaken en wijzigen 
        --------------------------------------------------------------------------------------------------- 
	    SET @plancommand = 'EXECUTE master.dbo.xp_sqlmaint N''-PlanID ' + LTRIM(RTRIM(convert(varchar(36),@dbplanid)))+ ' -Rpt "'+ @LogDir + @planname + '6.txt" -DelTxtRpt 4WEEKS -WriteHistory  -VrfyBackup -VrfyBackup -BkUpMedia DISK -BkUpLog ' + @def_backupdir + ' -DelBkUps ' + @DelLogBack + 'HOURS -CrBkSubDir -BkExt "TRN"'''

        set @planstepname = 'Transactie log Backup step van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobsteps WHERE job_id = @outputjob_id and step_id = 1  ) = 0 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_add_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        ELSE 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_update_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        IF @RC != 0 RETURN(1) 
        --------------------------------------------------------------------------------------------------- 
        -- Jobschedule backup aanmaken of wijzigen 
        --------------------------------------------------------------------------------------------------- 
        --------------------------------------------------------------------------------------------------- 
        -- Fequency type goed zetten (dagen goed zetten) 
        --------------------------------------------------------------------------------------------------- 
        IF ISNULL(@trndagen,7) = 7 
        BEGIN 
                SET @planfreqtype = 4 
                SET @planfreqinterval = 1 
                SET @planreoccur = 1 
        END 
        ELSE 
        BEGIN 
                SET @planfreqtype = 8 
                IF @trndagen = 5 
                        SET @planfreqinterval = 62 
                ELSE 
                        SET @planfreqinterval = 126 
                
                SET @planreoccur = 1 
        END 
        SET @planreoccur = 1 
        --------------------------------------------------------------------------------------------------- 
        -- Fequency type goed zetten (herhaling binnen een dag goed zetten) 
        --------------------------------------------------------------------------------------------------- 
        IF ISNULL(@trninterval,15) < 60 
        BEGIN 
                SET @planfreqsubdays = 0x4 
                SET @planfreqsubinterval = ISNULL(@trninterval,15) 
        END 
        ELSE 
        BEGIN 
                SET @planfreqsubdays = 0x8 
                SET @planfreqsubinterval = CEILING(@trninterval/60) 
        END 
        --------------------------------------------------------------------------------------------------- 
        -- Schedule aanmaken 
        --------------------------------------------------------------------------------------------------- 
        SET @planschedulename = 'Transactie log Backup schedule van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobschedules WHERE job_id = @outputjob_id ) = 0 

        BEGIN 
                EXEC @RC = msdb.dbo.sp_add_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = @planfreqtype, 
                        @freq_interval = @planfreqinterval, 
                        @freq_subday_type = @planfreqsubdays, 
                        @freq_subday_interval = @planfreqsubinterval, 
                        @active_start_time = @trnstarttijd, 
                        @active_end_time = @trneindtijd, 
                        @freq_recurrence_factor = @planreoccur 
        END 
        ELSE 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_update_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = @planfreqtype, 
                        @freq_interval = @planfreqinterval, 
                        @freq_subday_type = @planfreqsubdays, 
                        @freq_subday_interval = @planfreqsubinterval, 
                        @active_start_time = @trnstarttijd, 
                        @active_end_time = @trneindtijd, 
                        @freq_recurrence_factor = @planreoccur 
        END 
        IF @RC != 0 RETURN(1) 
END 
ELSE 
BEGIN 
        --------------------------------------------------------------------------------------------------- 
        -- Job verwijderen als die mocht bestaan 
        --------------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NOT NULL ) 
        BEGIN 
                ------------------------------------------------------------------------------------------- 
                -- Job verwijderen, niet vergeten om het maintenance plan job te verwijderen 
                ------------------------------------------------------------------------------------------- 
                EXEC msdb..sp_delete_job @job_id = @outputjob_id                
                SET @outputjob_id = NULL 
        END 
END 
PRINT  'Job '''+ @planjob + ''' created. The job_id for transaction log backup = '+ ISNULL(convert(varchar(256),@outputjob_id),'Niet van toepassing') 

--------------------------------------------------------------------------------------------------- 
-- Stap 5:  Reorganisatie job aanmaken 
--------------------------------------------------------------------------------------------------- 
SET @outputjob_id = NULL        -- Initialiseren 
SET @reorgschedule_active = 1	-- default = 1, wordt op 0 gezet als benodigde sp's niet aanwezig zijn.

--------------------------------------------------------------------------------------------------- 
-- Job voor Reorganisatie bekijken 
--------------------------------------------------------------------------------------------------- 
IF ( @reorgtijd IS NOT NULL ) 
BEGIN 
   	SET @planjob = 'Reorganization DB ''' + ISNULL(@plandb, @plands) + '''' 
    SET @plandesc = 'Reorganisatie van ' +  ISNULL(@plandb, @plands) + ' aangemaakt vanuit database beheerscript'


	SELECT  @outputjob_id=job_id     
	FROM   msdb.dbo.sysjobs    
	WHERE (name = @planjob)         

	------------------------------------------------------------------------------------------- 
	-- Job voor Reorganisatie aanmaken 
	------------------------------------------------------------------------------------------- 
	IF ( @outputjob_id IS NULL ) 
	BEGIN 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobs WHERE name = @planjob  ) = 0 
            BEGIN 
                    EXEC msdb.dbo.sp_add_job  @job_name = @planjob , 
                             @enabled = 1, 
                             @description =  @plandesc, 
                             @start_step_id = 1 , 
                             @category_name = @jobcat , 
                             @owner_login_name = @JobOwn , 
                             @notify_level_eventlog = 2 , 
                             @notify_level_email =2, 
                             @notify_email_operator_name = @EmOp , 
                             @delete_level = 0 , 
                             @job_id =  @outputjob_id OUTPUT  
                    EXECUTE @RC = msdb.dbo.sp_add_jobserver @job_id = @outputjob_id, @server_name = @servernaam 
                    IF @outputjob_id IS NULL RETURN(1) 
            END             
            ELSE 
                    SELECT @outputjob_id = job_id FROM msdb.dbo.sysjobs WHERE name = @planjob 
    END 
    ------------------------------------------------------------------------------------------- 
    -- Job voor Reorganisatie aanpassen zodat de optie goed staan 
    ------------------------------------------------------------------------------------------- 
    EXEC msdb.dbo.sp_update_job  @job_id = @outputjob_id, 
                    @new_name = @planjob , 
                    @enabled = 1, 
                    @description =  @plandesc, 
                    @start_step_id = 1 , 
                    @category_name = @jobcat , 
                    @owner_login_name = @JobOwn , 
                    @notify_level_eventlog = 2 , 
                    @notify_level_email =2, 
                    @notify_email_operator_name = @EmOp , 
                    @delete_level = 0 

    --------------------------------------------------------------------------------------------------- 
    -- Jobstep Reorganisatie aanmaken en wijzigen 
    --------------------------------------------------------------------------------------------------- 
	/* If Server version is 2000 */
	IF CAST(Serverproperty ('Productversion') as char(1)) in('7','8' )
	BEGIN
		IF  OBJECT_ID('master.dbo.sp_Check_RebuildIndexes_SQL2000') IS NULL
		BEGIN 
			PRINT 'Stored procedure master.dbo.sp_Check_RebuildIndexes_SQL2000 does not exist'
			SET @plancommand = '--Stored procedure master.dbo.sp_Check_RebuildIndexes_SQL2000 does not exist, Exec  sp_Check_RebuildIndexes_SQL2000'
			SET @reorgschedule_active = 0
		END 
		ELSE
		BEGIN
			SET @plancommand = 'Exec  sp_Check_RebuildIndexes_SQL2000'
		END
	END

	/* If Server version is 2005 */
	IF CAST(Serverproperty ('Productversion') as char(1)) in ('9' ,'1')
	BEGIN
		IF  OBJECT_ID('master.dbo.sp_Check_RebuildIndexes_SQL2005') IS NULL
		BEGIN 
			PRINT 'Stored procedure master.dbo.sp_Check_RebuildIndexes_SQL2005 does not exist'
			SET @plancommand = '--Stored procedure master.dbo.sp_Check_RebuildIndexes_SQL2005 does not exist, Exec  sp_Check_RebuildIndexes_SQL2005'
			SET @reorgschedule_active = 0
		END 
		ELSE
		BEGIN
			SET @plancommand = 'Exec  sp_Check_RebuildIndexes_SQL2005'
		END
	END

	set @planstepname = 'Reorganisatie step van ' + ISNULL(@plandb, @plands) 
	IF (SELECT COUNT(*) FROM msdb.dbo.sysjobsteps WHERE job_id = @outputjob_id and step_id = 1  ) = 0 
	BEGIN 
			EXEC @RC = msdb.dbo.sp_add_jobstep 
					@job_name = @planjob, 
					@step_id =1, 
					@step_name = @planstepname, 
					@subsystem = 'TSQL', 
					@command = @plancommand , 
					@cmdexec_success_code = 0, 
					@on_success_action = 1, 
					@on_fail_action = 2, 
					@database_name = @plandb, 
					@retry_attempts = 0, 
					@retry_interval = 0 
	END 
	ELSE 
	BEGIN 
			EXEC @RC = msdb.dbo.sp_update_jobstep 
					@job_name = @planjob, 
					@step_id =1, 
					@step_name = @planstepname, 
					@subsystem = 'TSQL', 
					@command = @plancommand , 
					@cmdexec_success_code = 0, 
					@on_success_action = 1, 
					@on_fail_action = 2, 
					@database_name = @plandb, 
					@retry_attempts = 0, 
					@retry_interval = 0 
	END 
		IF @RC != 0 RETURN(1) 
	--------------------------------------------------------------------------------------------------- 
	-- Jobschedule Reorganisatie aanmaken of wijzigen 
	--------------------------------------------------------------------------------------------------- 
	--------------------------------------------------------------------------------------------------- 
	-- Fequency type goed zetten (dagen goed zetten) 
	--------------------------------------------------------------------------------------------------- 
	if @dbtype = 'u' 
		BEGIN
		SET @planfreqtype = 8  -- wekelijks
		SET @Planfreq_relative_interval=0
		END
	if @dbtype = 's' 
		BEGIN
		SET @planfreqtype = 32 -- maandelijks
		SET @Planfreq_relative_interval=1
		END
	IF ISNULL(@reorgdag,7) = 7 
	BEGIN 
			SET @planfreqinterval = 1 
	END 
	ELSE 
	BEGIN 
			IF @reorgdag = 5 
					SET @planfreqinterval = 32 
			ELSE 
					SET @planfreqinterval = 64 
	END 
	SET @planreoccur = 1 
    --------------------------------------------------------------------------------------------------- 
    -- Schedule aanmaken 
    --------------------------------------------------------------------------------------------------- 
    SET @planschedulename = 'Reorganisatie schedule van ' + ISNULL(@plandb, @plands) 
    IF (SELECT COUNT(*) FROM msdb.dbo.sysjobschedules WHERE job_id = @outputjob_id  ) = 0 

    BEGIN 
            EXEC @RC = msdb.dbo.sp_add_jobschedule 
                     @job_name = @planjob, 
                     @name = @planschedulename, 
                     @enabled = @reorgschedule_active, 
                     @freq_type = @planfreqtype, 
                     @freq_interval = @planfreqinterval, 
                     @active_start_time = @reorgtijd, 
                     @freq_recurrence_factor = @planreoccur,
				 	 @freq_relative_interval = @Planfreq_relative_interval 
    END 
    ELSE 
    BEGIN 
            EXEC @RC = msdb.dbo.sp_update_jobschedule 
                    @job_name = @planjob, 
                    @name = @planschedulename, 
                    @enabled = @reorgschedule_active, 
                    @freq_type = @planfreqtype, 
                    @freq_interval = @planfreqinterval, 
                    @active_start_time = @reorgtijd, 
                    @freq_recurrence_factor = @planreoccur, 
				 	@freq_relative_interval = @Planfreq_relative_interval 
    END 
    IF @RC != 0 RETURN(1) 
END
--END
ELSE 
BEGIN 
        --------------------------------------------------------------------------------------------------- 
        -- Job verwijderen als die mocht bestaan 
        --------------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NOT NULL ) 
        BEGIN 
                ------------------------------------------------------------------------------------------- 
                -- Job verwijderen, niet vergeten om het maintenance plan job te verwijderen 
                ------------------------------------------------------------------------------------------- 
                EXEC msdb..sp_delete_job @job_id = @outputjob_id                
                SET @outputjob_id = NULL 
        END 
END 
PRINT  'Job ''' + @planjob + ''' created. The job_id for reorganization = '+ ISNULL(convert(varchar(256),@outputjob_id),'Niet van toepassing') 


--------------------------------------------------------------------------------------------------- 
-- Stap 6:  Integrity check aanmaken 
--------------------------------------------------------------------------------------------------- 
SET @outputjob_id = NULL        -- Initialiseren 
--------------------------------------------------------------------------------------------------- 
-- Job voor Integrity check backup bekijken 
--------------------------------------------------------------------------------------------------- 
IF ( @integertijd IS NOT NULL ) 
BEGIN 
        SET @planjob = 'Check DB ''' + ISNULL(@plandb, @plands) + '''' 
        SET @plandesc = 'Integriteitscheck van ' +  ISNULL(@plandb, @plands) + ' aangemaakt vanuit database beheerscript'

	SELECT  @outputjob_id=job_id     
	FROM   msdb.dbo.sysjobs    
	WHERE (name = @planjob)         
	
        ------------------------------------------------------------------------------------------- 
        -- Job voor Integrity check aanmaken 
        ------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NULL ) 
        BEGIN 
                IF (SELECT COUNT(*) FROM msdb.dbo.sysjobs WHERE name = @planjob  ) = 0 
                BEGIN 
                        EXEC msdb.dbo.sp_add_job  @job_name = @planjob , 
                                 @enabled = 1, 
                                 @description =  @plandesc, 
                                 @start_step_id = 1 , 
                                 @category_name = @jobcat , 
                                 @owner_login_name = @JobOwn , 
                                 @notify_level_eventlog = 2 , 
                                 @notify_level_email =2, 
                                 @notify_email_operator_name = @EmOp , 
                                 @delete_level = 0 , 
                                 @job_id =  @outputjob_id OUTPUT  
                        EXECUTE @RC = msdb.dbo.sp_add_jobserver @job_id = @outputjob_id, @server_name = @servernaam 
                        IF @outputjob_id IS NULL RETURN(1) 
                END             
                ELSE 
                        SELECT @outputjob_id = job_id FROM msdb.dbo.sysjobs WHERE name = @planjob 
        END 
        ------------------------------------------------------------------------------------------- 
        -- Job voor Integrity check aanpassen zodat de optie goed staan 
        ------------------------------------------------------------------------------------------- 
        EXEC msdb.dbo.sp_update_job  @job_id = @outputjob_id, 
                        @new_name = @planjob , 
                        @enabled = 1, 
                        @description =  @plandesc, 
                        @start_step_id = 1 , 
                        @category_name = @jobcat , 
                        @owner_login_name = @JobOwn , 
                        @notify_level_eventlog = 2 , 
                        @notify_level_email =2, 
                        @notify_email_operator_name = @EmOp , 
                        @delete_level = 0 
            
        --------------------------------------------------------------------------------------------------- 
        -- Jobstep Integrity check aanmaken en wijzigen 
        --------------------------------------------------------------------------------------------------- 
        SET @plancommand = 'DBCC CHECKDB ('+ QuoteName( @plandb,CHAR(39))  + ') WITH ALL_ERRORMSGS, PHYSICAL_ONLY '

        set @planstepname = 'Integriteitscheck step van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobsteps WHERE job_id = @outputjob_id and step_id = 1  ) = 0 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_add_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        ELSE 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_update_jobstep 
                        @job_name = @planjob, 
                        @step_id =1, 
                        @step_name = @planstepname, 
                        @subsystem = 'TSQL', 
                        @command = @plancommand , 
                        @cmdexec_success_code = 0, 
                        @on_success_action = 1, 
                        @on_fail_action = 2, 
                        @database_name = 'master', 
                        @retry_attempts = 0, 
                        @retry_interval = 0 
        END 
        IF @RC != 0 RETURN(1) 
	--------------------------------------------------------------------------------------------------- 
        -- Fequency type goed zetten (dagen goed zetten) 
        --------------------------------------------------------------------------------------------------- 
		if @dbtype = 'u' 
			BEGIN
			SET @planfreqtype = 8  -- wekelijks
			SET @Planfreq_relative_interval=0
			END
		if @dbtype = 's' 
			BEGIN
			SET @planfreqtype = 32 -- maandelijks
			SET @Planfreq_relative_interval=1
			END

        IF ISNULL(@integerdag,7) = 7 
        BEGIN 
                SET @planfreqinterval = 1 
        END 
        ELSE 
        BEGIN 
                IF @integerdag = 5 
                        SET @planfreqinterval = 32 
                ELSE 
                        SET @planfreqinterval = 64 
        END 
        SET @planreoccur = 1 
        --------------------------------------------------------------------------------------------------- 
        -- Schedule aanmaken 
        --------------------------------------------------------------------------------------------------- 
        SET @planschedulename = 'Integriteitscheck schedule van ' + ISNULL(@plandb, @plands) 
        IF (SELECT COUNT(*) FROM msdb.dbo.sysjobschedules WHERE job_id = @outputjob_id ) = 0 

        BEGIN 
                EXEC @RC = msdb.dbo.sp_add_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = @planfreqtype, 
                        @freq_interval = @planfreqinterval, 
                        @active_start_time = @integertijd, 
                        @freq_recurrence_factor = @planreoccur, 
						@freq_relative_interval = @Planfreq_relative_interval
        END 
        ELSE 
        BEGIN 
                EXEC @RC = msdb.dbo.sp_update_jobschedule 
                        @job_name = @planjob, 
                        @name = @planschedulename, 
                        @enabled = 1, 
                        @freq_type = @planfreqtype, 
                        @freq_interval = @planfreqinterval, 
                        @active_start_time = @integertijd, 
                        @freq_recurrence_factor = @planreoccur, 
						@freq_relative_interval = @Planfreq_relative_interval
        END 
        IF @RC != 0 RETURN(1) 
END 
ELSE 
BEGIN 
        --------------------------------------------------------------------------------------------------- 
        -- Job verwijderen als die mocht bestaan 
        --------------------------------------------------------------------------------------------------- 
        IF ( @outputjob_id IS NOT NULL ) 
        BEGIN 
                ------------------------------------------------------------------------------------------- 
                -- Job verwijderen, niet vergeten om het maintenance plan job te verwijderen 
                ------------------------------------------------------------------------------------------- 
                EXEC msdb..sp_delete_job @job_id = @outputjob_id                
                SET @outputjob_id = NULL 
        END 
END 
PRINT   'Job '''+ @planjob + ''' created. The job_id for Integriteitscheck = '+ ISNULL(convert(varchar(256),@outputjob_id),'Niet van toepassing') 

IF (@@ERROR <> 0)  ROLLBACK TRAN
COMMIT TRANSACTION

