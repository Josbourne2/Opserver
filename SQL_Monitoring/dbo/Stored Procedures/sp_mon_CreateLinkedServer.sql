







CREATE PROCEDURE [dbo].[sp_mon_CreateLinkedServer] (@server  varchar(60),@error int OUTPUT, @version int =9, @ERROR_MESSAGE VARCHAR(255) ='' OUTPUT ) AS


declare @sql 	varchar(2000)
set @ERROR_MESSAGE = '';

-- Drop bestaande linked server met dezelfde naam
if  exists (select srvname from master.dbo.sysservers where srvname = @server)
BEGIN
	EXEC sp_dropserver @server,'droplogins'
END


BEGIN TRY

	Set @sql = 'EXEC sp_addlinkedserver '''+ @server + ''', N''SQL Server'''
	exec (@sql)

	set @sql =  'EXEC sp_addlinkedsrvlogin @rmtsrvname=N''' + @server + ''',@useself=N''True'',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL'
	exec (@sql)
	
	--set @sql = 'EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'''+@server + ''', @locallogin = NULL , @useself = N''True'''
	--exec (@sql)

	set @sql = 'SELECT TOP(1) 1 FROM ['+@SERVER+'].master.sys.databases; '
	EXEC (@sql);

END TRY
BEGIN CATCH

	SELECT @ERROR_MESSAGE =  ERROR_MESSAGE();

END CATCH





