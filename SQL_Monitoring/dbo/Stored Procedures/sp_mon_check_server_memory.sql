





CREATE PROCEDURE [dbo].[sp_mon_check_server_memory]
AS BEGIN
	
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'xp_cmdshell', 1;
	RECONFIGURE;

	SET XACT_ABORT OFF
	SET NOCOUNT ON
	DECLARE @id INT
	DECLARE @FullServer VARCHAR(255)
	DECLARE @srvr VARCHAR(255)
	DECLARE @inst VARCHAR(50)
	DECLARE @SQLQry NVARCHAR(MAX)
	DECLARE @CheckDate DATETIME2(0) = SYSDATETIME();
	DECLARE @SystemType VARCHAR(255);

	DECLARE @serverproperties TABLE (
	total_physical_memory_kb INT, available_physical_memory_kb INT,
	[total_page_file_kb] int,
	[available_page_file_kb] int,
	 [system_memory_state_desc] varchar(255))

	DECLARE @VERSIONTBL TABLE (VERSION VARCHAR(MAX));

	DECLARE @osinfo TABLE(cpu_count INT);

	declare node_cursor Cursor For
	SELECT ms.[id]
      ,ms.[server]     
	  ,mi.Instance
  FROM [dbo].[Mon_Server] ms
  cross apply (SELECT TOP(1) Instance
				FROM dbo.Mon_Instance mi
				WHERE mi.Mon_Server_Id = ms.id
				and controle=1 AND te_bewaken = 1) mi
	WHERE ms.te_bewaken = 1
	--and ms.server like 'zmpdb018%'
	
	open node_cursor

	Fetch Next from node_cursor into @id,@srvr, @inst

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		BEGIN TRY

			SET @FullServer = @srvr + COALESCE('\' + isnull(@inst,''),'');
			SELECT @FullServer
			/* Create linked server */
			EXEC dbo.sp_mon_CreateLinkedServer @server = @FullServer, @error = 0
		
			/* Get server properties */
			SET @SQLQry = '';
			SET @SQLQry =  'SELECT * FROM OPENQUERY([' + @FullServer +'],
		   ''SELECT total_physical_memory_kb, available_physical_memory_kb,[total_page_file_kb]
           ,[available_page_file_kb]
           ,[system_memory_state_desc]
			FROM sys.dm_os_sys_memory;'')'

			--PRINT(@SQLQRy);

			INSERT INTO @serverproperties
			EXEC(@SQLQry)


			SET @SQLQry = 'SELECT VERSION FROM OPENQUERY([' + @FullServer +'],
		   ''SELECT @@VERSION AS VERSION'')'

		    INSERT INTO @VERSIONTBL
			EXEC(@SQLQry)

			IF EXISTS (SELECT * FROM @VERSIONTBL WHERE VERSION LIKE '%HYPERVISOR%' OR VERSION LIKE '%(VM)%')
			BEGIN
				
				SET @SystemType = 'VM'

			END
			ELSE
			BEGIN

				SET @SystemType = 'Fysiek'

			END

			SET @SQLQry =  'SELECT * FROM OPENQUERY([' + @FullServer +'],
		   ''SELECT cpu_count
				FROM sys.dm_os_sys_info;'')'

			--PRINT(@SQLQRy);

			INSERT INTO @osinfo
			EXEC(@SQLQry)





			UPDATE dbo.Mon_Server
			SET system_type = @SystemType, cpu_count = (SELECT cpu_count FROM @osinfo)
			WHERE id = @id

			INSERT INTO dbo.Mon_Server_Memory ([total_physical_memory_kb]
           ,[available_physical_memory_kb]
           ,[total_page_file_kb]
           ,[available_page_file_kb]
           ,[system_memory_state_desc]
           ,[Datum]
           ,[Mon_Server_Id])
			SELECT 
		  [total_physical_memory_kb]
		  ,[available_physical_memory_kb]
		  ,[total_page_file_kb]
		  ,[available_page_file_kb]
		  ,[system_memory_state_desc]
		  ,@CheckDate
		  ,@id AS [Mon_Server_Id]
		FROM @serverproperties

			


			/* Drop linked server */
			EXEC master.dbo.sp_dropserver @server=@FullServer, @droplogins='droplogins';


		END TRY
		BEGIN CATCH

			print ERROR_MESSAGE();
			UPDATE dbo.Mon_Server
			SET system_type = 'ONBEKEND'
			WHERE id = @id

			/* If linked server exists, drop linked server */
			IF EXISTS(SELECT * FROM SYS.servers WHERE name = @FullServer)
			BEGIN
				EXEC master.dbo.sp_dropserver @server=@FullServer, @droplogins='droplogins';
			END


		END CATCH
	

		DELETE FROM @ServerProperties;
		DELETE FROM @VERSIONTBL;
		DELETE FROM @osinfo;
		SET @SystemType = '';
		Fetch Next from node_cursor into @id,@srvr, @inst

	END
	CLOSE node_cursor
	DEALLOCATE node_cursor

	


	
	EXEC sp_configure 'xp_cmdshell', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	END








