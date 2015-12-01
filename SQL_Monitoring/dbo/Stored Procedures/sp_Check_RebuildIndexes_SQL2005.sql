
CREATE PROCEDURE [dbo].[sp_Check_RebuildIndexes_SQL2005]

AS
BEGIN

DECLARE 	@Table				varchar(255)	
DECLARE 	@cmd				nvarchar(2000)
DECLARE 	@tableid			int
DECLARE	 	@object_id  	 	int
DECLARE		@Command			nvarchar(1000)
DECLARE 	@Database			varchar(255)
DECLARE 	@TableName			varchar(255)
DECLARE		@Fragmentation 		INT	,
			@Fragmentation_rb  	INT	,
			@Period				INT		
DECLARE 	@DatabaseName		sysname,
			@DatabaseID			bigint,
			@ObjectName			sysname,
			@ObjectID			bigint,
			@IndexName			sysname,
			@IndexID			tinyint,
			@ActualScanDensity	numeric(10,2),
			@PartitionCount		smallint,
			@PartitionNum		smallint,
			@Blob				tinyint,
			@Start				Datetime,
			@result				tinyint,	
			@partition			tinyint	
	
SET @TableName = null
SET @Fragmentation =10
SET @Fragmentation_rb =30
SET @Period=7


/************************************************************************************************** 
** This script does maintenance of all indexes on a database or table.
** If no tablename is provided then all tables in the current database are examined.
** First sys.dm_db_index_physical_stats is used in SAMPLED mode to determine the index fragmentation.
** Depending on the level of fragmention either no action is taken (0% - 10%), the index is reorganized (10% - 30%) or 
** the index is rebuild (> 30%, @Fragmentation_rb).
** If an index rebuild is necessary a check takes place if a online rebuild is possible.
** Tables with less than 8 pages are ignored.
** Partitioned indexes can be treated by partition
** Reorganizing for indexes where page locks are disallowed will be ignored
** If table contains column(s) of type text, ntext, image, xml, varchar(Max),nvarchar(Max)or varbinary(Max) then rebuild offline
**
** Parameters: TableName, Period (default 7 days) and Fragmentationlimits (@Fragmentation default 10%, @Fragmentation_rb default 30%)
**	
**					
*****************************************************************************************************/

--Check status db

SET @Database = DB_NAME()

IF DATABASEPROPERTYEX(@Database,'IsInStandBy')= 1 
OR CAST(DATABASEPROPERTYEX(@Database,'Status') AS VARCHAR(25)) <> CAST('ONLINE' AS VARCHAR(25))
OR DATABASEPROPERTY	(@Database,'IsReadOnly') = 1
	BEGIN
		RAISERROR('Database %s is in a state which does not allow reindexing', 16, 1, @Database)
		RETURN
	END

--Check if a valid table name has been supplied 
IF @TableName IS NOT NULL
	BEGIN
		SELECT @object_id = id FROM sysobjects where @TableName like '%' + name + '%' AND  type in (N'U')
		IF OBJECTPROPERTY(@object_id, 'IsUserTable') = 0 
			BEGIN
				RAISERROR('Object: %s exists but is NOT a User-defined Table. This procedure only accepts valid table names to process for index rebuilds.', 16, 1, @TableName)
				RETURN
			END
		ELSE
			BEGIN
				IF OBJECTPROPERTY(@object_id, 'IsTable') IS NULL
					BEGIN
						RAISERROR('Object: %s does not exist within this database. Please check the table name and location (which database?). This procedure only accepts existing table names to process for index rebuilds.', 16, 1, @TableName)
						RETURN
					END
			END
		
    END


-- Create a temporary table to hold the index statistics
CREATE TABLE #IndexDefrag
(
	DatabaseId			smallint,
	DatabaseName		varchar(255),
	ObjectName			varchar(255),
	ObjectId			bigint,
	IndexName			varchar(255),
	IndexId				tinyint,
	page_count			int,
	record_count		bigint,
	Fragmentation		numeric(10,2),
	PartitionNum		smallint,
	PartitionCount		smallint,
	Blob				tinyint
)  


SET @DatabaseID = DB_ID(@Database)
IF  @TableName IS NOT NULL --tablename provided
	BEGIN
	-- Get information about the physical statistics for the index(es) of one table
			SET @cmd = 'USE [' + @Database + ']' + CHAR(10) +
			' INSERT INTO #IndexDefrag 
			SELECT DISTINCT database_id 
			,''' + @Database + 
			''', ''['' + sch.name + ''].[''+o.name + '']'' as objectName
			, ips.[object_id] as objectId 
			, i.name as IndexName
			, ips.index_id as IndexId
			, page_count, record_count
			, avg_fragmentation_in_percent as Fragmentation
			, partition_number AS PartitionNum
			, PartitionCount
			, l.blob
			FROM sys.dm_db_index_physical_stats (' + CAST(@DatabaseID AS VARCHAR(5)) + ',' + CAST(@tableid AS VARCHAR(15)) + ' ,NULL,NULL,''SAMPLED'') ips
			JOIN sys.indexes i 
			ON ips.index_id =i.index_id
			AND ips.object_id=i.object_id
			JOIN sys.objects o
			ON ips.object_id = o.object_id
			JOIN sys.schemas sch
			ON o.schema_id = sch.schema_id
			JOIN (SELECT object_id, count(*)as PartitionCount FROM sys.partitions  GROUP BY object_id,index_id) as p
			ON ips.object_id = p.object_id
			JOIN 	(SELECT object_id as o_id, 
			CASE WHEN (Select Count(*)FROM sys.columns c2 WHERE c1.object_id  = c2.object_id AND (max_length = -1 OR system_type_id IN (34,35, 99, 241))) > 0 THEN 1
			ELSE 0
			END as blob
			FROM sys.columns c1				
			GROUP BY object_id) AS l
			ON o.object_id = l.o_id
			WHERE  i.index_id BETWEEN 1 AND 250
			AND i.is_disabled = 0
--			AND avg_fragmentation_in_percent >= 10 
			AND page_count > 10 '
	END
ELSE
	BEGIN		-- Get information about the physical statistics for the index(es) of all tables, no specific tablename provided
			SET @cmd = 'USE [' + @Database + ']' + CHAR(10) +
			' INSERT INTO #IndexDefrag 
			SELECT DISTINCT database_id 
			,''' + @Database + 
			''', ''['' + sch.name + ''].[''+o.name + '']'' as objectName
			, ips.[object_id] as objectId 
			, i.name as IndexName
			, ips.index_id as IndexId
			, page_count, record_count
			, avg_fragmentation_in_percent as Fragmentation
			, partition_number AS PartitionNum
			, PartitionCount				
			, l.blob
			FROM sys.dm_db_index_physical_stats (' + CAST(@DatabaseID AS VARCHAR(5)) + ',NULL,NULL,NULL,''SAMPLED'') ips
			JOIN sys.indexes i 
			ON ips.index_id =i.index_id
			AND ips.object_id=i.object_id
			JOIN sys.objects o
			ON ips.object_id = o.object_id
			JOIN sys.schemas sch
			ON o.schema_id = sch.schema_id
			JOIN (SELECT object_id, count(*)as PartitionCount FROM sys.partitions  GROUP BY object_id, index_id) as p
			ON ips.object_id = p.object_id
			JOIN 				(SELECT object_id as o_id, 
			CASE WHEN (Select Count(*)FROM sys.columns c2 WHERE c1.object_id  = c2.object_id AND (max_length = -1 OR system_type_id IN (34,35, 99, 241))) > 0 THEN 1
			ELSE 0
			END as blob
			FROM sys.columns c1				
			GROUP BY object_id) AS l
			ON o.object_id = l.o_id
			WHERE  i.index_id BETWEEN 1 AND 250
			AND i.is_disabled = 0
--			AND avg_fragmentation_in_percent >= 10 
			AND o.type = ''U'' AND o.object_id > 1000
			AND page_count > 10
			AND o.name <> ''sysdiagrams'''
	
	END

EXECUTE sp_executesql @cmd

select * from #IndexDefrag
-- Make subselection of the fragmentation-data

SELECT DatabaseName, ObjectName, IndexName
INTO #Temp2
FROM #IndexDefrag 
WHERE	DatabaseName = @Database
AND		(ObjectName LIKE '%' + @TableName + '%' OR @TableName IS NULL)

GROUP BY DatabaseName, ObjectName, IndexName


-- start reorganizing/rebuilding indexes based on provided index-statistics



CREATE TABLE #teller (aantal int)

	DECLARE TableIndexList CURSOR FAST_FORWARD FOR 
		SELECT id.DatabaseName, id.DatabaseId, id.ObjectName, id.ObjectId, id.IndexName, id.IndexId	, id.Fragmentation, id.PartitionNum, id.PartitionCount, id.Blob
		FROM  #IndexDefrag id
		INNER JOIN #Temp2 t
		ON  id.DatabaseName = t.DatabaseName
		AND id.ObjectName = t.ObjectName
		AND id.IndexName = t.IndexName
		WHERE id.Fragmentation > @Fragmentation 

	OPEN TableIndexList

	FETCH NEXT FROM TableIndexList 
		INTO @DatabaseName,	@DatabaseID, @ObjectName, @ObjectID, @IndexName, @IndexID, @ActualScanDensity,@PartitionNum, @PartitionCount, @Blob

	WHILE (@@fetch_status = 0)
		BEGIN

		TRUNCATE TABLE #teller
		SET @Command = 'USE [' + @DatabaseName + ']' + CHAR(10)+ 'SELECT COUNT(*) FROM sys.objects WHERE object_id = ' +  CAST(@ObjectID AS VARCHAR(10))
		INSERT INTO #teller EXEC (@Command)

		IF (SELECT top 1 aantal 
		FROM #teller) > 0
		BEGIN		

			SET @Start = GETDATE()
			TRUNCATE TABLE #teller
			SET @Command = 'USE [' + @DatabaseName + ']' + CHAR(10)+ 'SELECT INDEXPROPERTY(' + CAST(@ObjectID AS VARCHAR(15)) + ',''' + @IndexName + ''',''IsPageLockDisallowed'')'
			INSERT INTO #teller EXEC (@Command)
			SELECT @result = aantal FROM #teller

			--check whether partitions exist
			Set @partition = 0
			TRUNCATE TABLE #teller
			SET @Command = 'USE [' + @DatabaseName + ']' + CHAR(10)+ 'SELECT count(*) from sys.partitions where object_id = ' + CAST(@ObjectID AS VARCHAR(15)) + ' and index_id = ' +  CAST(@IndexID AS VARCHAR(15))  + ' and partition_number = ' + CAST(@PartitionNum AS VARCHAR(15))
			INSERT INTO #teller EXEC (@Command)
			SELECT @partition = ISNULL(aantal,0) FROM #teller

			IF @ActualScanDensity < @Fragmentation_rb  -- If fragmentation between 10% (= parameter @Fragmentation) and 30% (= parameter @Fragmentation_rb) then reorganizing the index is sufficient
			AND @result = 0 			--REORGANIZE is not possible if Page locks are disallowed
				BEGIN
				SET @Command = (SELECT 'ALTER INDEX ['+ @IndexName + '] ON [' + @DatabaseName + '].'+ @ObjectName + ' REORGANIZE')
					IF @PartitionCount > 1 and @partition > 0 and @PartitionNum > 1
					 SELECT @Command = @Command + ' PARTITION =' + CONVERT (CHAR, @PartitionNum);
				EXEC sp_executesql @Command
				PRINT @Command
				END
		-- Higher fragmentation (>Fragmentation_rb %) , so rebuild index needed
			ELSE	-- If Server Edition is not Enterprise, Enterprise Evaluation or Developer then Offline rebuild
			IF  SERVERPROPERTY('EngineEdition')<> 3
				BEGIN 
				SET @Command = (SELECT 'ALTER INDEX ['+ @IndexName + '] ON [' + @DatabaseName + '].'+ @ObjectName + ' REBUILD')
					IF @PartitionCount > 1 and @partition > 0 and @PartitionNum > 1
					 SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @PartitionNum);
				EXEC sp_executesql @Command
				PRINT @Command
				END
				ELSE	-- If table contains column(s) of type text, ntext, image, xml, varchar(Max),nvarchar(Max)or varbinary(Max) rebuild offline
--				IF @IndexID  = 1  AND @Blob = 1 -- alleen clustered indexes?! 
				IF  @Blob = 1 -- ook non-clustered indexes! 
								
					BEGIN 
						SET @Command = (SELECT 'ALTER INDEX ['+ @IndexName + '] ON [' + @DatabaseName + '].'+ @ObjectName + ' REBUILD')
						IF @PartitionCount > 1 and @partition > 0 and @PartitionNum > 1
						 SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @PartitionNum);
					EXEC sp_executesql @Command
					PRINT @Command
					END
				ELSE	
--				else online rebuild
					BEGIN 
						SET @Command = (SELECT 'ALTER INDEX ['+ @IndexName + '] ON [' + @DatabaseName + '].'+ @ObjectName + ' REBUILD')
						IF @PartitionCount > 1 and @partition > 0 and @PartitionNum > 1
							BEGIN
							SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @PartitionNum);
							END
						ELSE
							BEGIN
							SELECT @Command = @Command + ' WITH (ONLINE = ON )';
							END
					EXEC sp_executesql @Command
					PRINT @Command
					END

		
			END

			FETCH NEXT FROM TableIndexList 
				INTO @DatabaseName,	@DatabaseID, @ObjectName, @ObjectID, @IndexName, @IndexID, @ActualScanDensity,@PartitionNum,@PartitionCount, @Blob

	END
	CLOSE TableIndexList
	DEALLOCATE TableIndexList


DROP TABLE #Temp2
DROP TABLE #teller
DROP TABLE #IndexDefrag







END


