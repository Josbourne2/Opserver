CREATE PROCEDURE [dbo].[sp_mon_generate_configurations_script] @server nvarchar(255)
AS
BEGIN

	DECLARE @BASESQL NVARCHAR(MAX) = 
	'EXEC sys.sp_configure N''show advanced options'', N''1''  
	RECONFIGURE WITH OVERRIDE
	EXEC sys.sp_configure N''[1]'', N''[2]''
	RECONFIGURE WITH OVERRIDE
	EXEC sys.sp_configure N''show advanced options'', N''0'' 
	RECONFIGURE WITH OVERRIDE
	'
	DECLARE @SQLCMD NVARCHAR(MAX) = N'';
	DECLARE @ConfigName NVARCHAR(MAX);
	DECLARE @ConfigValue NVARCHAR(MAX);

	DECLARE C_SERVERS CURSOR FAST_FORWARD FOR
	SELECT c.name, N'' + CAST(c.value AS NVARCHAR(50)) + N''
	FROM [dbo].[Mon_Configurations] C
		INNER JOIN [dbo].[Mon_Instance] I
		ON C.instance_id  = I.id
	WHERE I.te_bewaken = 1
		AND I.Controle = 1
		AND C.push_config = 1
		AND i.server = @server

	OPEN C_SERVERS;

	FETCH NEXT FROM C_SERVERS INTO @ConfigName, @ConfigValue;


	WHILE(@@FETCH_STATUS = 0)
	BEGIN

		SET @SQLCMD = @SQLCMD + REPLACE(REPLACE(@BASESQL, '[1]', @ConfigName),'[2]', @ConfigValue);



		FETCH NEXT FROM C_SERVERS INTO @ConfigName, @ConfigValue;

	END

	SELECT @SQLCMD;

	CLOSE C_SERVERS;
	DEALLOCATE C_SERVERS;
	--EXEC( @SQL)



END



