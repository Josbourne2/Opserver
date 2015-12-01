






CREATE PROCEDURE [dbo].[sp_mon_check_serversettings_2008]
AS BEGIN
	


	SET XACT_ABORT OFF
	SET NOCOUNT ON
	declare @srvr nvarchar(255),@FullServer nvarchar(255), @TLok nvarchar(50), @build nvarchar(50), @inst nvarchar(50), @SQLString varchar(256), @SQLQry nvarchar(max), @rset varchar(256), @ver varchar(256), @arch varchar(256), @edition varchar(50), @wpos int, @w_build varchar(50), @w_sp varchar(50), @qry varchar(256)
	declare @errortekst varchar(4000), @clus int, @id int,@datadir varchar(600),@logdir varchar(600)
	declare @system_instance_name varchar(300)	
	DECLARE  @chvDomainName NVARCHAR(100)
	DECLARE @serviceaccount varchar(600), @regkey varchar(600),@Backupdir varchar(600)

	DECLARE @ServerProperties TABLE (KeyName VARCHAR(128), KeyValue VARCHAR(128));

	create table #regkeys (txt varchar(2000),id int identity(1,1))--,param varchar(30),value varchar(2000))

	select getdate() as 'Gestart', count(*) as '# servers' from dbo.mon_instance;

	declare node_cursor Cursor For
	select  id,node, instance, versie from dbo.mon_instance where ((te_bewaken = '1' AND Controle = 1) or te_bewaken is null)  order by node

	open node_cursor

	Fetch Next from node_cursor into @id,@srvr, @inst, @ver

	WHILE @@FETCH_STATUS = 0
	BEGIN
	
		BEGIN TRY

			SET @FullServer = @srvr + COALESCE('\' + @inst,'');
			SELECT @FullServer
			/* Create linked server */
			EXEC dbo.sp_mon_CreateLinkedServer @server = @FullServer, @error = 0

		
			/* Get server properties */
			SET @SQLQry = '';
			SET @SQLQry =  'SELECT * FROM OPENQUERY([' + @FullServer +'],
		   ''SELECT ''''ResourceLastUpdateDateTime'''', CONVERT(VARCHAR(198),SERVERPROPERTY(''''ResourceLastUpdateDateTime''''),121)
			 UNION ALL
			 SELECT ''''ResourceVersion'''', CONVERT(VARCHAR(198),SERVERPROPERTY(''''ResourceVersion''''))
			 UNION ALL
			 SELECT ''''max_server_memory_value'''', CONVERT(VARCHAR(198),value) FROM sys.configurations WHERE name = ''''max server memory (MB)''''
			 UNION ALL
			 SELECT ''''max_server_memory_value_in_use'''', CONVERT(VARCHAR(198),value_in_use) FROM sys.configurations WHERE name = ''''max server memory (MB)'''''')'

			 PRINT(@SQLQRy);

			INSERT INTO @ServerProperties
			EXEC(@SQLQry)

			UPDATE Mon_Instance
			SET ResourceLastUpdateDateTime = (SELECT CAST(KeyValue AS DATETIME2(0)) FROM @ServerProperties WHERE KeyName = 'ResourceLastUpdateDateTime'),
				ResourceVersion = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'ResourceVersion'),
				max_server_memory_value = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'max_server_memory_value'),
				max_server_memory_value_in_use = (SELECT KeyValue FROM @ServerProperties WHERE KeyName = 'max_server_memory_value_in_use')
			WHERE node = @srvr AND ISNULL(instance,'DEFAULT') = ISNULL(@inst,'DEFAULT');

			/* Get default directories */


			/* Drop linked server */
			EXEC master.dbo.sp_dropserver @server=@FullServer, @droplogins='droplogins';


		END TRY
		BEGIN CATCH

			print ERROR_MESSAGE();
			/* If linked server exists, drop linked server */
			IF EXISTS(SELECT * FROM SYS.servers WHERE name = @FullServer)
			BEGIN
				EXEC master.dbo.sp_dropserver @server=@FullServer, @droplogins='droplogins';
			END


		END CATCH
	

		DELETE FROM @ServerProperties;
		Fetch Next from node_cursor into @id,@srvr, @inst, @ver

	END
	CLOSE node_cursor
	DEALLOCATE node_cursor

	drop table #regkeys


	end
	





