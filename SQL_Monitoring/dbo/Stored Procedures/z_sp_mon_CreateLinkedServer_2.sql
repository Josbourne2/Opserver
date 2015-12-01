
CREATE PROCEDURE [dbo].[z_sp_mon_CreateLinkedServer_2] (@server  varchar(60),@error int OUTPUT, @version int =9) AS


-- create linked server dba_ictro-account
declare @sql 	varchar(2000)
declare @sql1 	varchar(2000)
declare @qry 	varchar(2000)
declare @sqlqry 	varchar(2000)
declare @sqlstring 	varchar(2000)
-- Drop bestaande linked server met dezelfde naam
if  exists (select srvname from master.dbo.sysservers where srvname = @server)
BEGIN
	EXEC sp_dropserver @server,'droplogins'
END

-- create linked server en gebruik dba_ictro-account

--check connectie

	set @qry = 'osql -S' + @server + ' -dmaster -Udba_ictro' + ' -PH!25oepj$' + ' -Q "'
		set @SQLQry = 'SELECT Name FROM sysdatabases'
		set @SQLString = @qry + @SQLQry + '"'
		CREATE TABLE #db ( dbname varchar(2000) NULL ); 
		INSERT #db 
		EXEC master..xp_cmdshell @SQLString;

IF EXISTS(SELECT dbname FROM #db WHERE LTRIM(RTRIM(dbname)) = N'master') 
	BEGIN

	-- controle sqlversie
	if @version >=8 -- sql 2000 en hoger
		BEGIN
		--connectie ok, linked server maken
			if not exists (select srvname from master.dbo.sysservers where srvname = @server)
			BEGIN
				Set @sql = 'EXEC sp_addlinkedserver '''+ @server + ''', N''SQL Server'''
				exec (@sql)

				set @sql1 =  'EXEC sp_addlinkedsrvlogin '''+ @server + ''', ''false'', NULL, ''dba_ictro'', ''H!25oepj$'''
				exec (@sql1)
			END
		END
	if @version <8 --sql 7 en lager
		BEGIN
			if not exists (select srvname from master.dbo.sysservers where srvname = @server)
			BEGIN
				Set @sql = 'EXEC  master.dbo.sp_addlinkedserver @server = '''+ @server + ''', @srvproduct = '''', @provider = ''MSDASQL'', @provstr = ''DRIVER={SQL Server};SERVER=' + @server + ';UID=dba_ictro;PWD=H!25oepj$;'''
				print @sql
				exec (@sql)
--EXEC master.dbo.sp_addlinkedserver 
--@server = 'ALKSMS01', 
--@srvproduct = '',
--@provider = 'MSDASQL',
--@provstr = 'DRIVER={SQL Server};SERVER=ALKSMS01;UID=dba_ictro;PWD=H!25oepj$;'
--EXEC sp_addlinkedserver @server = 'ALKSMS01', @srvproduct = '', @provider = 'MSDASQL', @provstr = 'DRIVER={SQL Server};SERVER=ALKSMS01;UID=dba_ictro;PWD=H!25oepj$;'

				set @sql1 =  'EXEC sp_addlinkedsrvlogin '''+ @server + ''', ''false'', NULL, ''dba_ictro'', ''H!25oepj$'''
				exec (@sql1)
			END
		END
						print @sql

	END
else
BEGIN
--connectie niet ok, errornr meegeven
	set @error =1
END


