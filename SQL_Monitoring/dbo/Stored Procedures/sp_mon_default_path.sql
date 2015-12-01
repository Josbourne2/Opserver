-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_mon_default_path]
 @DefPathLog varchar(500) OUT,
 @DefPathBackup varchar(500) OUT,
 @DefPathData varchar(500) OUT,
 @ver varchar(30) OUT


AS
BEGIN
	SET NOCOUNT ON;

	--=================================================
	--backuppad uit serverparameters ophalen
	--
	-- geen onderscheid tussen sql2005 en 2000
	--=================================================

--	declare @ver varchar(30)
--	DECLARE @DefPathLog varchar(500)
--	DECLARE @DefPathBackup varchar(500)
--	DECLARE @DefPathData varchar(500)
	CREATE TABLE #Key (KeyValue Varchar(500), KeyData VarChar(500))

--	select @ver= left(cast(SERVERPROPERTY('productversion') as varchar(30)),2)  
	select @ver= cast(SERVERPROPERTY('productversion') as varchar(30))  
--	select @ver
	--set @DefPathLog = ''
	BEGIN
--		print 'versie 2005/2008'
			INSERT into	#KEY 
			EXECUTE master..xp_instance_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', 'BackupDirectory'
			SELECT @DefPathBackup = KeyData  from #Key -- backuppad uit serverparameters
--		select @DefPathBackup as backupfolder
			delete from #KEY
			INSERT into	#KEY 
			EXECUTE master..xp_instance_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', 'DefaultData'
			SELECT @DefPathData = KeyData  from #Key -- backuppad uit serverparameters
--		select @DefPathData as datafolder
			delete from #KEY
			INSERT into	#KEY 
			EXECUTE master..xp_instance_regread 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', 'DefaultLog'
			SELECT @DefPathLog = KeyData  from #Key -- backuppad uit serverparameters
--SET @DefPathLog = @DefPathLog
--		select @ver as version, @DefPathBackup as backupfolder, @DefPathLog as logfolder,@DefPathBackup as backupfolder
	END

	DROP TABLE #Key


END

