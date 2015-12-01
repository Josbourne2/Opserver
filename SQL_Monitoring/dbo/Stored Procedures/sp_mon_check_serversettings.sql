







CREATE   PROCEDURE [dbo].[sp_mon_check_serversettings] AS
BEGIN
-- controle op toegankelijkheid en info van alle SQL-instanties uit de tabel mon_instance

-- 11-08-2010 A vd Berg
--		MSDE wordt ook weergegeven als 'desktop engine'
--		default aangegeven voor editie ('Niet gespecificeerd in script')

--  1-6-2010 A vd Berg 
--		domeinnaam en dns-suffix toevoegen dynamisch
--		backupdirectory uitlezen uit register
--		datadir en logdir uitlezen uit register



EXECUTE AS LOGIN='MonitoringAccount_OSQL'


SET XACT_ABORT OFF
SET NOCOUNT ON
declare @srvr nvarchar(50),@srvr2 nvarchar(50), @TLok nvarchar(50), @build nvarchar(50), @inst nvarchar(50), @SQLString varchar(256), @SQLQry varchar(256), @rset varchar(256), @ver varchar(256), @arch varchar(256), @edition varchar(50), @wpos int, @w_build varchar(50), @w_sp varchar(50), @qry varchar(256)
declare @errortekst varchar(4000), @clus int, @id int,@datadir varchar(600),@logdir varchar(600)
declare @system_instance_name varchar(300)	
DECLARE  @chvDomainName NVARCHAR(100)
DECLARE @serviceaccount varchar(600), @regkey varchar(600),@Backupdir varchar(600), @instancename varchar(255);

create table #regkeys (txt varchar(2000),id int identity(1,1))--,param varchar(30),value varchar(2000))

select getdate() as 'Gestart', count(*) as '# servers' from dbo.mon_instance
declare node_cursor Cursor For
	select  id,node, instance, versie from dbo.mon_instance 
	where (te_bewaken = '1' or te_bewaken is null)-- AND node like 'ZMPMG081%'  	
	order by node
	open node_cursor
	Fetch Next from node_cursor
	into @id,@srvr, @inst, @ver
WHILE @@FETCH_STATUS = 0
	BEGIN


		

		--set @srvr2 = ''
		if @inst <> ''  and @inst <> 'onbekend'  set @srvr2 = @srvr + '\' + @inst
		else  
			begin
			set @srvr2 = @srvr
			end	
		set @qry = 'osql -S' + @srvr2 + ' -dmaster -E' + ' -Q "'
		set @SQLQry = 'SELECT Name FROM sysdatabases where name = ''master'''
		set @SQLString = @qry + @SQLQry + '"'
		CREATE TABLE #logcontrole ( dbname varchar(2000) NULL ); 
		INSERT #logcontrole 
		EXEC master..xp_cmdshell @SQLString;
-- check sysadmin-role
		set @SQLQry = 'SELECT	cast(IS_SRVROLEMEMBER(''sysadmin'') as varchar(10)) + ''_sysadmin'''
		set @SQLString = @qry + @SQLQry + '"'
		INSERT #logcontrole 
		EXEC master..xp_cmdshell @SQLString;		
		
		
SELECT dbname FROM #logcontrole
		IF EXISTS(SELECT 1 FROM #logcontrole WHERE LTRIM(RTRIM(dbname)) = N'master') 
		BEGIN

			/* JM 20150803: Vul instancename variabele */
			SET @SQLQry = 'SELECT SERVERPROPERTY(''INSTANCENAME'') AS instancename'
			set @SQLString = @qry + @SQLQry + '" -s, -w256'
			CREATE TABLE #instancecontrole ( instancename nvarchar(4000) NULL )
	print @SQLString
			INSERT #instancecontrole
			EXEC master..xp_cmdshell @SQLString;


			select TOP(1) REPLACE(LTRIM(RTRIM(instancename)),'	','')
			 from #instancecontrole 
			 where instancename <> 'instancename'
			 and instancename <> '(1 row affected)'
			 and instancename <> ''
			 order by instancename desc
			select @instancename = (select  TOP(1) REPLACE(LTRIM(RTRIM(instancename)),'	','') from #instancecontrole 
			 where instancename <> 'instancename'
			 and instancename <> '(1 row affected)'
			 and instancename <> ''
			 order by instancename desc)


			SET @SQLQry = 'SELECT @@VERSION'
			set @SQLString = @qry + @SQLQry + '" -s, -w256'
			CREATE TABLE #versiecontrole ( productversion nvarchar(4000) NULL )
	--print @SQLString
			INSERT #versiecontrole
			EXEC master..xp_cmdshell @SQLString;
			IF EXISTS(SELECT productversion FROM #versiecontrole where productversion not like '%login failed%' and productversion not like '%[DBNETLIB]%' )
			BEGIN
				select * from #versiecontrole
				select @rset = (select * from #versiecontrole where productversion LIKE '%Microsoft SQL Server%')
				select @ver = ltrim(rtrim(substring(@rset, 22, 5)))
				select @build =  substring( @rset  , charindex('-',@rset,0) +2  , charindex('(',@rset,charindex('-',@rset,0)) - charindex('-',@rset,0) -2  )

				select @arch = rtrim(substring(@rset, 41, 9))
				select @rset = (select * from #versiecontrole where productversion LIKE '%(Build%')
				select @edition = 'Niet gespecificeerd in script'
				if (select PATINDEX('%Standard Edition%', @rset)) > 0
				begin
					select @edition = 'Standard'
				end
				if (select PATINDEX('%Enterprise Edition%', @rset)) > 0
				begin
					set @edition = 'Enterprise'
				end
				if (select PATINDEX('%Developer Edition%', @rset)) > 0
				begin
					set @edition = 'Developer'
				end
				if (select PATINDEX('%Express Edition%', @rset)) > 0
				begin
					set @edition = 'Express'
				end
				if (select PATINDEX('%MSDE%', @rset)) > 0
				begin
					set @edition = 'MSDE'
				end
				if (select PATINDEX('%Desktop Engine%', @rset)) > 0
				begin
					set @edition = 'MSDE'
				end

				select @rset = (select * from #versiecontrole where productversion LIKE '%(Build%')
				select @wpos = (select PATINDEX('%Build%', @rset))
				if (@wpos > 0)
				begin
					select @w_build = rtrim(substring(@rset, @wpos +6, 4))
					select @w_sp = rtrim(substring(@rset, @wpos +25, 1))
				end
				update dbo.mon_instance set dd_laatst_beschikbaar = getdate()  where id = @id;		
				update dbo.mon_instance set controle = '1', versie = @ver, build = @build, editie = @edition, w_build = @w_build, w_sp = @w_sp, controledatum = getdate(),reden_onbereikbaar = '' where id = @id;		
			END
		-- is clustered?	
			set @SQLQry = 'SELECT  SERVERPROPERTY(''isclustered'')'
			set @SQLString = @qry + @SQLQry + '" -s, -w256'
			--print @SQLString
			delete from  #versiecontrole
			INSERT #versiecontrole
			EXEC master..xp_cmdshell @SQLString;
			IF EXISTS(SELECT productversion FROM #versiecontrole where productversion not like '%login failed%' and productversion not like '%[DBNETLIB]%' )
			BEGIN
				select  @clus = productversion from #versiecontrole where productversion = '0' or  productversion = '1' 
				update dbo.mon_instance set isclustered = @clus, controledatum = getdate() where id = @id;		
			END
			
	
	
print 'domeinnaam'
-- domeinnaam en dns-suffix
	declare @keyname varchar(30)
	set @keyname = 'CachePrimaryDomain'
	

		set @SQLQry = 'EXEC master.dbo.xp_regread ''HKEY_LOCAL_MACHINE'',''SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'','''+ @keyname + ''''
--			   N''CachePrimaryDomain'''--,@chvDomainName OUTPUT'
		set @SQLString = @qry + @SQLQry + '"'
		--print @sqlstring
		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		--select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @chvDomainName = txt from #regkeys where txt not like @keyname
		print @chvDomainName --as domeinnaam -- domeinnaam OK
			truncate table #regkeys

		
			----IF @chvDomainName is not null 
			----	begin
			----		update dbo.mon_instance set domein = upper(@chvDomainName) where id = @id
			----	end
				
			set @chvDomainName = null
			

	set @keyname = 'Domain'

		set @SQLQry = 'EXEC master.dbo.xp_regread ''HKEY_LOCAL_MACHINE'',''System\ControlSet001\Services\Tcpip\Parameters'','''+ @keyname + ''''
		set @SQLString = @qry + @SQLQry + '"'
		--print @sqlstring
		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString;
			select * from #regkeys
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @chvDomainName = txt from #regkeys where txt not like @keyname
		select @chvDomainName as dnssuffix-- dns-suffix OK
			truncate table #regkeys
			
				----	IF @chvDomainName is not null 
				----begin
				----	update dbo.mon_instance set dns_suffix = upper(@chvDomainName) where id = @id
				----end
		
-- Interne instancenaam bepalen
print 'interne instantienaam'
print @ver
	set @system_instance_name = 'MSSQLSERVER'

if (@ver like '%7%' or @ver like '%2000%') 
	BEGIN
	set @system_instance_name = 'MSSQLSERVER'
	END
else
if (@ver >2000)
	BEGIN
	--set @system_instance_name = 'MSSQL.1'
	
		BEGIN
		set @keyname = coalesce(@instancename,'MSSQLSERVER')		
		
		SELECT @regkey = N'Software\Microsoft\\Microsoft SQL Server\\Instance Names\SQL'

		--EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL', @instance_name, @system_instance_name output;
			--print @system_instance_name

			set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
			set @SQLString = @qry + @SQLQry + '"'
			--EXEC master..xp_cmdshell @SQLString;
			--print @SQLString

			insert into #regkeys
				EXEC master..xp_cmdshell @SQLString;
				select * from #regkeys
			delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
			select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
			select @system_instance_name = txt from #regkeys where txt not like @keyname
			select @system_instance_name as system_instance_name-- service-account OK?
				truncate table #regkeys
		
		END
	END
	set @system_instance_name = ltrim(rtrim(@system_instance_name))
	--print @system_instance_name
	--print len(@system_instance_name)
	set @system_instance_name = REPLACE(@system_instance_name, CHAR(9),'') --leading tab eraf halen
	print @system_instance_name
	--print len(@system_instance_name)

-- serviceaccount
if @ver like '7%' goto geen_info --sql 7 heeft geen xp_instance_regread

	set @keyname = 'ObjectName'
print 'serviceaccount'
			IF (@inst IS NULL)
			BEGIN
				SELECT @regkey = N'SYSTEM\CurrentControlSet\Services\MSSQLServer'
			END
			ELSE
			BEGIN
				SELECT @regkey = N'SYSTEM\CurrentControlSet\Services\MSSQL$' + @instancename
			END
		
			set @Serviceaccount = null
		
		set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
		set @SQLString = @qry + @SQLQry + '"'
		--EXEC master..xp_cmdshell @SQLString;
		--print @SQLString

		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString;
			select * from #regkeys
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @Serviceaccount = txt from #regkeys where txt not like @keyname
		select @Serviceaccount as serviceaccount-- service-account OK?
			truncate table #regkeys
		
		
			--Display the Service Account
			SELECT @srvr, @Serviceaccount as serviceaccount
			----IF @Serviceaccount is not null 
				begin
					update dbo.mon_instance set serviceaccount = @Serviceaccount where id = @id
				end
			
--print @Serviceaccount

-- backupdir

	set @keyname = 'BackupDirectory'
print 'backupdir'
		set @Backupdir = null
		
		if @ver like '%2000%' or @ver like '%7%'
		begin
			SELECT @regkey = N'Software\Microsoft\MSSQLServer\MSSQLServer'
		end

		else
		if @ver >2000
		Begin
			SELECT @regkey = N'Software\Microsoft\\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer'
		End
		
		set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
		set @SQLString = @qry + @SQLQry + '"'
		--EXEC master..xp_cmdshell @SQLString;
		--print @SQLString

		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString;
			select * from #regkeys
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @Backupdir = txt from #regkeys where txt not like @keyname
		select @Backupdir as backupdir-- backupdir OK?
			truncate table #regkeys
	--print @Backupdir	
	
			----IF @Backupdir is not null 
				begin
					update dbo.mon_instance set backup_dir = @Backupdir where id = @id
				end

--	datadir uitlezen uit register


	set @keyname = 'Defaultdata'
print 'defaultdata'
		set @Datadir = null
		
		if @ver like '%2000%' or @ver like '%7%'
		begin
			SELECT @regkey = N'Software\Microsoft\MSSQLServer\MSSQLServer'
		end

		else
		if @ver >2000
		Begin
			SELECT @regkey = N'Software\Microsoft\\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer'
		End
		
		set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
		set @SQLString = @qry + @SQLQry + '"'
		--EXEC master..xp_cmdshell @SQLString;
		--print @SQLString

		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString;
			select * from #regkeys
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @Datadir = txt from #regkeys where txt not like @keyname
		select @Datadir as Datadir-- backupdir OK?
		truncate table #regkeys
	--print @Datadir	
	
	-- datadir-key bestaat niet, defaultpad gebruiken
	IF @Datadir  like '%specified%'
	begin
		set @logdir = null

		set @keyname = 'SQLdataroot'
			print 'defaultdata_dataroot'
		set @Datadir = null
		
		if @ver like '%2000%' or @ver like '%7%'
		begin
			SELECT @regkey = N'Software\Microsoft\MSSQLServer\setup'
		end

		else
		if @ver >2000 -- gebeurt nooit
		Begin
			SELECT @regkey =  N'Software\Microsoft\\Microsoft SQL Server\' + @system_instance_name + '\Setup'
		End
		
		set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
		set @SQLString = @qry + @SQLQry + '"'
		--EXEC master..xp_cmdshell @SQLString;
		--print @SQLString

		insert into #regkeys
			EXEC master..xp_cmdshell @SQLString;
			select * from #regkeys
		delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
		select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
		select @Datadir = txt from #regkeys where txt not like @keyname
		select @Datadir as Datadir-- backupdir OK?
		truncate table #regkeys
	--print @Datadir	
	set @logdir = @datadir --dan nl ook geen logdir apart in register vermeld
	end
	
	
		begin
			update dbo.mon_instance set data_dir = @Datadir where id = @id
		end

-- logdir uitlezen uit register
	if @logdir = @datadir 
		Begin
		print 'default pad als logdir'
		end
	else
		begin-- 
			set @keyname = 'Defaultlog'
		print 'defaultlog'

				set @Logdir = null
				
				if @ver like '%2000%' or @ver like '%7%'
				begin
					SELECT @regkey = N'Software\Microsoft\MSSQLServer\MSSQLServer'
				end

				else
				if @ver >2000
				Begin
					SELECT @regkey = N'Software\Microsoft\\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer'
				End
				
				set @SQLQry = 'EXECUTE master.dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'','''+ @regkey + ''','''+ @keyname+ ''''
				set @SQLString = @qry + @SQLQry + '"'
				--EXEC master..xp_cmdshell @SQLString;
				--print @SQLString

				insert into #regkeys
					EXEC master..xp_cmdshell @SQLString;
					select * from #regkeys
				delete from #regkeys where txt is null or txt like '%-----%' or len(ltrim(rtrim(txt)))<2 or txt like '%(%)%'
				select rtrim(ltrim(txt)) txt,id from #regkeys where  id>6
				select @Logdir = txt from #regkeys where txt not like @keyname
				select @Logdir as Logdir-- backupdir OK?
				truncate table #regkeys
			--print @Logdir
			----IF @Logdir is not null 
		End
		begin
			update dbo.mon_instance set log_dir = @Logdir where id = @id
		end
goto verder

geen_info:
print 'SQL 7 heeft geen xp_instance_regread'
			update dbo.mon_instance set serviceaccount = null where id = @id
			update dbo.mon_instance set backup_dir = null where id = @id
			update dbo.mon_instance set data_dir = null where id = @id
			update dbo.mon_instance set log_dir = null where id = @id
			
verder: 			
			DROP TABLE #versiecontrole
			DROP TABLE #instancecontrole
-- check if user is sysadmin			
			IF EXISTS(SELECT 1 FROM #logcontrole WHERE LTRIM(RTRIM(dbname)) = N'0_sysadmin') 
				BEGIN
				update dbo.mon_instance set dd_laatst_beschikbaar = case when controle ='0' then dd_laatst_beschikbaar when controle = '1' then  controledatum end  where id = @id;		
				update dbo.mon_instance set controle = '0', controledatum = getdate(),reden_onbereikbaar = 'ERROR -- Monitoring-account geen sysadmin' where id = @id
			print @srvr2 + ';  ERROR -- Monitoring-account geen sysadmin'

				END
		END
		ELSE
		BEGIN
		-- probleem met connectie; reden komt in veld reden_onbereikbaar
			SELECT top 1 @errortekst = dbname FROM #logcontrole --where ltrim(rtrim(dbname)) like 'login failed%' or ltrim(rtrim(dbname))  like '[DBNETLIB]%'  
				update dbo.mon_instance set dd_laatst_beschikbaar = case when controle ='0' then dd_laatst_beschikbaar when controle = '1' then  controledatum end  where id = @id;		
				update dbo.mon_instance set controle = '0', controledatum = getdate(),reden_onbereikbaar = @errortekst where id = @id
			print @srvr2 + ';  ' + @errortekst
		END 
		set @srvr2 = ''
		DROP TABLE #logcontrole
	Fetch Next from node_cursor
	into @id,@srvr, @inst, @ver

	End
Close node_cursor
Deallocate node_cursor

drop table #regkeys

END









