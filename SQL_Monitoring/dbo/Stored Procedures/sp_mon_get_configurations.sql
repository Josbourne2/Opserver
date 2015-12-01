





CREATE PROCEDURE [dbo].[sp_mon_get_configurations]
AS BEGIN
	
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'xp_cmdshell', 1;
	RECONFIGURE;

	SET XACT_ABORT OFF
	SET NOCOUNT ON
	declare @srvr nvarchar(255),@FullServer nvarchar(255)
	-- @inst nvarchar(50), @SQLString varchar(256), @SQLQry nvarchar(max), @rset varchar(256), @ver varchar(256), @arch varchar(256), @edition varchar(50), @wpos int, @w_build varchar(50), @w_sp varchar(50), @qry varchar(256)
	--declare @errortekst varchar(4000), @clus int, @id int,@datadir varchar(600),@logdir varchar(600)
	--declare @system_instance_name varchar(300)	
	--DECLARE  @chvDomainName NVARCHAR(100)
	--DECLARE @serviceaccount varchar(600), @regkey varchar(600),@Backupdir varchar(600)
	CREATE TABLE #Configurations(		
	[configuration_id] [int] NOT NULL,
	[name] [nvarchar](35) NOT NULL,
	[value] [sql_variant] NULL,
	[minimum] [sql_variant] NULL,
	[maximum] [sql_variant] NULL,
	[value_in_use] [sql_variant] NULL,
	[description] [nvarchar](255) NOT NULL,
	[is_dynamic] [bit] NOT NULL,
	[is_advanced] [bit] NOT NULL	
) 
	DECLARE @instance_id int;
	DECLARE @server NVARCHAR(255);
	DECLARE @SQLQry NVARCHAR(MAX);

		
	select getdate() as 'Gestart', count(*) as '# servers' from dbo.mon_instance;

	declare node_cursor Cursor For
	select  id,server
	from dbo.mon_instance 
	where ((te_bewaken = '1' AND Controle = 1) or te_bewaken is null)  order by node

	open node_cursor

	Fetch Next from node_cursor into @instance_id, @server;

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		BEGIN TRY

			
			--SELECT @server
			/* Create linked server */
			EXEC dbo.sp_mon_CreateLinkedServer @server = @server, @error = 0

		
			/* Get server properties */
			SET @SQLQry = '';
			SET @SQLQry =  'SELECT * FROM OPENQUERY([' + @server +'], 
			''SELECT configuration_id, name, value, minimum,maximum,value_in_use,description,is_dynamic,is_advanced 
			FROM sys.configurations'')';

			--PRINT(@SQLQRy);

			INSERT INTO #Configurations
			EXEC(@SQLQry)

			--UPDATE Mon_Instance
			--SET ResourceLastUpdateDateTime = (SELECT CAST(KeyValue AS DATETIME2(0)) FROM @ServerProperties WHERE KeyName = 'ResourceLastUpdateDateTime'),
			--	ResourceVersion = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'ResourceVersion'),
			--	max_server_memory_value = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'max_server_memory_value'),
			--	max_server_memory_value_in_use = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'max_server_memory_value_in_use')
			--WHERE node = @srvr AND ISNULL(instance,'DEFAULT') = ISNULL(@inst,'DEFAULT');

			--/* Get default directories */

			MERGE dbo.Mon_Configurations AS TRG
			USING #Configurations AS SRC
				ON (SRC.configuration_id = TRG.configuration_id
					AND TRG.instance_id = @instance_id
					AND TRG.push_config = 0 )
			WHEN MATCHED THEN UPDATE
				SET TRG.[value]				= SRC.[value]				
				  ,TRG.[minimum]			= SRC.[minimum]			
				  ,TRG.[maximum]			= SRC.[maximum]			
				  ,TRG.[value_in_use]		= SRC.[value_in_use]
				  ,TRG.[checkdate]			= SYSDATETIME()
			WHEN NOT MATCHED THEN INSERT (	[instance_id]
										  ,[configuration_id]
										  ,[name]
										  ,[value]
										  ,[minimum]
										  ,[maximum]
										  ,[value_in_use]
										  ,[description]
										  ,[is_dynamic]
										  ,[is_advanced]
										  ,[checkdate])
										  values( @instance_id 
										  ,SRC.[configuration_id]
										  ,SRC.[name]
										  ,SRC.[value]
										  ,SRC.[minimum]
										  ,SRC.[maximum]
										  ,SRC.[value_in_use]
										  ,SRC.[description]
										  ,SRC.[is_dynamic]
										  ,SRC.[is_advanced]
										  ,SYSDATETIME());
  

			DELETE #Configurations;

			/* Drop linked server */
			EXEC master.dbo.sp_dropserver @server=@server, @droplogins='droplogins';


		END TRY
		BEGIN CATCH

			print ERROR_MESSAGE();
			/* If linked server exists, drop linked server */
			IF EXISTS(SELECT * FROM SYS.servers WHERE name = @FullServer)
			BEGIN
				EXEC master.dbo.sp_dropserver @server=@FullServer, @droplogins='droplogins';
			END


		END CATCH
	

		DELETE FROM #Configurations;	
		Fetch Next from node_cursor into @instance_id, @server;

	END
	CLOSE node_cursor
	DEALLOCATE node_cursor

	


	
	EXEC sp_configure 'xp_cmdshell', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	END





