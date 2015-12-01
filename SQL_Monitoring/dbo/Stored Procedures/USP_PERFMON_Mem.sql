CREATE PROC [dbo].[USP_PERFMON_Mem] (@server varchar(150)=NULL,@instancename varchar(150) = NULL)
AS
-- =============================================
-- Author:		Anja vd Berg
-- Create date: 12-2-2013
-- Description:	Deze SP verzamelt gegevens over memory-performancecounters van de aangegeven server en bewaart die in de tabel in de monitoringdb
-- Voorbeeld: exec USP_PERFMON_Mem 'zmpdb026.rechtspraak.minjus.nl',NULL

-- =============================================

SET NOCOUNT ON;
--

/********************************************************************

  File Name:    sp_PerformanceCounters.sql

  Applies to:   SQL Server 2005
                SQL Server 2008
                SQL Server 2008 R2
                
  Purpose:      To aggregate overall performance data since SQL 
                Server was last started. The data is pulled from
                sys.dm_os_performance_counters. The code was adapted 
                from material taken from http://goo.gl/czeyC. 
                Written by Kevin Kline (MVP) with Brent Ozar (MCM, MVP) 
                and contributions by Christian Bolton (MCM, MVP), 
                Bob Ward (Microsoft), Rod Colledge (MVP), and Raoul Illyaos.

  Author:       Patrick Keisler

  Version:      1.0.0
  
  Date:         01/20/2013

  Help:         http://www.patrickkeisler.com/
  
  License:      (C) 2013 Patrick Keisler
                sp_PerformanceCounters is free to download and use for 
                personal, educational, and internal corporate purposes, 
                provided that this header is preserved. Redistribution 
                or sale sp_PerformanceCounters in whole or in part, 
                is prohibited without the author's express written consent.

********************************************************************/


--SET NOCOUNT ON;
--SET ARITHABORT ON;

IF @server is null 
BEGIN
PRINT 'UITLEG voor deze sp:'
PRINT 'Geef de servernaam in en daarna indien van toepassing de instantienaam'
PRINT 'De verzamelde data wordt direct toegevoegd aan tabel ''Mon_Perfcounter'' in de db SQL_Monitoring'
PRINT ''
PRINT 'Voorbeeld:'
PRINT 'exec USP_PERFMON_Mem ''zmpdb011.rechtspraak.minjus.nl'',''INST1'''
RETURN
END

DECLARE 
     --@InstanceName VARCHAR(100)
    @servername varchar(400)
    ,@SQLServerName VARCHAR(255)
    ,@TempValue1 DECIMAL(25,5)
    ,@TempValue2 DECIMAL(25,5)
    ,@CalcCntrValue DECIMAL(25,2)
    ,@StartDate DATETIME
    ,@UpTime DECIMAL(25,0)
    ,@UpTimeMs DECIMAL(25,0)
    ,@starttime varchar(200)
    ,@sql nvarchar(max)
 
DECLaRE   @PerformanceCounters table(
		 Id int IDENTITY(1,1)
		,server varchar(200)
		,PerformanceObject VARCHAR(128)
		,CounterName VARCHAR(128)
		,InstanceName VARCHAR(128)
		,TimeFrame VARCHAR(128)
		,ActualValue VARCHAR(128)
		,IdealValue  VARCHAR(128)
		,Description VARCHAR(1000)
	)

--set @server = 'zmpdb011.rechtspraak.minjus.nl';
--set @instancename = 'INST1'


-- Get the SQL Server instance name.
--SELECT @InstanceName = CONVERT(VARCHAR,SERVERPROPERTY('InstanceName'));


IF @InstanceName IS NOT NULL
BEGIN
    SET @SQLServerName = 'MSSQL$' + @InstanceName
    SET @Servername = @server +'\' + @InstanceName
    print @servername
END
ELSE
BEGIN
    SET @SQLServerName = 'SQLServer';
    SET @Servername = @server
    print @servername

END

exec sp_mon_CreateLinkedServer @servername,0; 

-- Create temp table to hold performance data.
--IF OBJECT_ID('tempdb..#PerformanceCounters') IS NOT NULL
--            DROP TABLE #PerformanceCounters;

--DECLARE ;


/******************************************
    SQL Server Uptime Header
******************************************/
-- Calculate SQL Server uptime in seconds.

--set @sql = 'SELECT  DATEDIFF(ss,sqlserver_start_time,CURRENT_TIMESTAMP)FROM ['+@server + '].master.sys.dm_os_sys_info'

SET @SQL = N'SELECT  @starttime= CONVERT(VARCHAR,sqlserver_start_time,109),@UpTime=DATEDIFF(ss,sqlserver_start_time,CURRENT_TIMESTAMP)FROM ['+ @servername+'].master.sys.dm_os_sys_info';

EXECUTE sp_executesql @SQL, N'@uptime int OUTPUT,@starttime varchar(100) OUTPUT',  @UpTime OUTPUT, @starttime OUTPUT;
--SELECT @UpTime;
--SELECT @starttime


-- Calculate SQL Server uptime in milliseconds.
SELECT @UpTimeMs = @UpTime * 1000



INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
SELECT @server,'SQL Server Startup Time:  '+@starttime,'','','','','',''
--FROM master.sys.dm_os_sys_info;
--select * from @PerformanceCounters

/******************************************
    Buffer Manager Section Header
******************************************/
-- Insert blank line.
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description) SELECT @server,'','','','','','','';

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
SELECT @server,'Buffer Manager & Memory Performance Counters','','','','','','';

-- Get Database Pages
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''See description''
    ,''Number of database pages in the buffer pool with database content.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Database Pages'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters


-- Get Target Pages
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''See description''
    ,''Ideal number of pages in the buffer pool based on the configured Max Server Memory in sp_configure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Target pages'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters

-- Get Free Pages
--INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''> 640''
    ,''Total number of pages available across all free list. A value less than 640 (5MB) may indicate physical memory pressure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Free pages'''
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters

-- Get Stolen Pages
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''See description''
    ,''Total number of page stolen from the buffer pool to satisfy other memory needs, such as plan cache and workspace memory.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Stolen pages'';'

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters


-- Get Total Server Memory (KB)
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''See description''
    ,''Total amount of dynamic memory that SQL is currently consuming. This value should grow until its equal to Target Server Memory.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Memory Manager''
AND counter_name = ''Total Server Memory (KB)'';'

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters

-- Get Target Server Memory (KB)
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''See description''
    ,''Total amount of dynamic memory that SQL is willing to consume based on the configured Max Server Memory in sp_configure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Memory Manager''
AND counter_name = ''Target Server Memory (KB)'';'

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200)',  @server,@SQLservername,@servername;
--select * from @PerformanceCounters

-- Get Memory Grants Pending
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''0''
    ,''Current number of processes waiting for memory. Anything above 0 for an extended period of time is an indicator of memory pressure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Memory Manager''
AND counter_name = ''Memory Grants Pending'';'

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
--EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200)',  @server,@SQLservername,@servername;
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;
--select * from @PerformanceCounters

-- Get Free list stalls/sec
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Avg since SQL startup''
    ,CONVERT(DECIMAL(25,2),(cntr_value/@UpTime))
    ,''< 2''
    ,''Number of requests per second where data requests wait for a free page in memory. Any value above 2 is an indicator of memory pressure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Free list stalls/sec'';'

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;
--select * from @PerformanceCounters

-- Get Lazy writes/sec
Set @sql = '
SELECT @server, 
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Avg since SQL startup''
    ,CONVERT(DECIMAL(25,2),(cntr_value/@UpTime))
    ,''< 20''
    ,''Number of buffers the Lazy Writer writes to disk to free up buffer space. Zero is ideal, but any value greater than 20 is an indicator of memory pressure.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
    WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Lazy writes/sec'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;

-- Get Checkpoint pages/sec
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Avg since SQL startup''
    ,CONVERT(DECIMAL(25,2),(cntr_value/@UpTime))
    ,''See description''
    ,''Number of dirty pages pages per second that are flushed by the checkpoint process. Checkpoint frequency controled by the Recovery Interval setting in sp_configure. High values for this counter is an indicator of memory pressure or that the recovery interval is set too high.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Checkpoint pages/sec'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;
--select * from @PerformanceCounters


-- Get Page life expectancy
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Current''
    ,CONVERT(VARCHAR,cntr_value)
    ,''> 300''
    ,''Number of seconds a data page to stay in the buffer pool without references.  A value under 300 may be an indicator of memory pressure; however index optimization may help.''
    FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Page life expectancy'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;

-- Get Page lookups / Batch Requests
Set @sql = 'SELECT @TempValue1 = cntr_value
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Page lookups/sec'';'
EXECUTE sp_executesql @SQL, N'@TempValue1 DECIMAL(25,5), @server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int', @TempValue1, @server,@SQLservername,@servername,@UpTime;

--SELECT @TempValue2 = cntr_value
--FROM sys.dm_os_performance_counters
--WHERE object_name = @SQLServerName+':SQL Statistics'
--AND counter_name = 'Batch Requests/sec';

Set @sql = 'SELECT @TempValue2 = cntr_value
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Batch Requests/sec'';'
EXECUTE sp_executesql @SQL, N'@TempValue2 DECIMAL(25,5), @server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int', @TempValue2, @server,@SQLservername,@servername,@UpTime;


IF @TempValue2 <> 0
    SET @CalcCntrValue = (@TempValue1/@TempValue2);
ELSE
    SET @CalcCntrValue = 0;



INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
SELECT @server,
     @SQLServerName+':Buffer Manager'
    ,'Page lookups / Batch Requests'
    ,''
    ,'Avg since SQL startup'
    ,CONVERT(VARCHAR,@CalcCntrValue)
    ,'< 100'
    ,'Number of batch requests to find a page in the buffer pool per batch request.  When this ratio exceeds 100, then you may have bad execution plans or too many adhoc queries.';

-- Get Page reads/sec
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Avg since SQL startup''
    ,CONVERT(DECIMAL(25,2),(cntr_value/@UpTime))
    ,''< 90''
    ,''Number of physical database page reads issued.  Values above 90 could be a result of poor indexing or is an indicator of memory pressure.''
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Page reads/sec'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;
--select * from @PerformanceCounters

-- Get Page writes/sec
--INSERT INTO @PerformanceCounters(PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
Set @sql = '
SELECT @server,
     RTRIM(object_name)
    ,RTRIM(counter_name)
    ,RTRIM(instance_name)
    ,''Avg since SQL startup''
    ,CONVERT(DECIMAL(25,2),(cntr_value/@UpTime))
    ,''< 90''
    ,''Number of physical database page writes issued. Values over 90 should be cross-checked with "Lazy writes/sec" and "Checkpoint" counters. If the other counters are also high, then it is an indicator of memory pressure.''
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Page writes/sec'';'
INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
EXECUTE sp_executesql @SQL, N'@server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int',  @server,@SQLservername,@servername,@UpTime;

-- Get Readahead pages / Page reads
Set @sql = 'SELECT @TempValue1 = cntr_value
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Readahead pages/sec'';'
EXECUTE sp_executesql @SQL, N'@TempValue1 DECIMAL(25,5), @server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int', @TempValue1, @server,@SQLservername,@servername,@UpTime;

Set @sql = 'SELECT @TempValue2 = cntr_value
FROM ['+@servername+'].master.sys.dm_os_performance_counters
WHERE object_name = @SQLServerName+'':Buffer Manager''
AND counter_name = ''Page reads/sec'';'
EXECUTE sp_executesql @SQL, N'@TempValue2 DECIMAL(25,5), @server varchar(100),@SQLservername varchar(200),@servername varchar(200),@UpTime int', @TempValue2, @server,@SQLservername,@servername,@UpTime;


IF @TempValue2 <> 0
    SET @CalcCntrValue = (@TempValue1/@TempValue2*100);
ELSE
    SET @CalcCntrValue = 0;

INSERT INTO @PerformanceCounters(server,PerformanceObject,CounterName,InstanceName,TimeFrame,ActualValue,IdealValue,Description)
SELECT
	@server,
     @SQLServerName+':Buffer Manager'
    ,'Readahead pages / Page reads'
    ,''
    ,'Avg since SQL startup'
    ,CONVERT(VARCHAR,@CalcCntrValue,0) + '%'
    ,'< 20%'
    ,'Percentage of page reads that were readahead reads.  High number of readahead reads for each page read could be an indicator of memory pressure.';

	EXEC sp_dropserver @servername ,'droplogins'
	
insert into dbo.mon_perfcounter (server 
		,PerformanceObject 
		,CounterName 
		,InstanceName 
		,TimeFrame 
		,ActualValue 
		,IdealValue 
		,Description)
select server 
		,PerformanceObject 
		,CounterName 
		,InstanceName 
		,TimeFrame 
		,ActualValue 
		,IdealValue  
		,Description  from @PerformanceCounters


