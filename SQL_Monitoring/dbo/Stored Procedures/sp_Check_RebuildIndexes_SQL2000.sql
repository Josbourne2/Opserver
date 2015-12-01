CREATE       PROCEDURE [dbo].[sp_Check_RebuildIndexes_SQL2000]
(
	@TableName		varchar(255)	= NULL,
	@ScanDensity 		INT		= 90,
	@Period			INT		= 7,
	@MaxStart INT	= 48		
)
AS


SET NOCOUNT ON
SET ARITHABORT ON

--Check status db

DECLARE @Database varchar(250)
DECLARE @SQL varchar(500)

SET @Database = DB_NAME() 	-- current database

CREATE TABLE #fraglist (
   ObjectName CHAR (255),
   ObjectId INT,
   IndexName CHAR (255),
   IndexId INT,
   Lvl INT,
   CountPages INT,
   CountRows INT,
   MinRecSize INT,
   MaxRecSize INT,
   AvgRecSize INT,
   ForRecCount INT,
   Extents INT,
   ExtentSwitches INT,
   AvgFreeBytes INT,
   AvgPageDensity INT,
   ScanDensity DECIMAL,
   BestCount INT,
   ActualCount INT,
   LogicalFrag DECIMAL,
   ExtentFrag DECIMAL)


IF DATABASEPROPERTYEX(@Database,'IsInStandBy')= 1 
OR CAST(DATABASEPROPERTYEX(@Database,'Status') AS VARCHAR(25)) <> CAST('ONLINE' AS VARCHAR(25))
OR DATABASEPROPERTY	(@Database,'IsReadOnly') = 1
	BEGIN
		RAISERROR('Database %s is in a state which does not allow reindexing', 16, 1, @Database)
		RETURN
	END

 
IF @ScanDensity NOT BETWEEN 1 AND 100
	BEGIN
		RAISERROR('Value supplied:%i is not valid. @ScanDensity is a percentage. Please supply a value for Scan Density between 1 and 100.', 16, 1, @ScanDensity)
		RETURN
	END
 
 -- Find all the tables in the database
 
 if @tablename is null  
	BEGIN
		SET @SQL = 'DECLARE tables CURSOR FOR '
		SET @SQL = @SQL + 'SELECT TABLE_SCHEMA + ''.'' + TABLE_NAME'
		SET @SQL = @SQL + ' FROM ' + @Database + '.INFORMATION_SCHEMA.TABLES '
		SET @SQL = @SQL + 'WHERE TABLE_TYPE = ''BASE TABLE'''
print @sql
	exec (@SQL)
	END
	
-- Use only a single specified table	
 if @tablename is not null  
	BEGIN
		DECLARE tables CURSOR FOR
		SELECT @tablename
	END
 
 -- Open the cursor
OPEN tables

-- Loop through all the tables in the database
FETCH NEXT
   FROM tables
   INTO @tablename
print @tablename
WHILE @@FETCH_STATUS = 0
BEGIN


	IF @TableName IS NOT NULL 
		BEGIN
			IF OBJECTPROPERTY(object_id(@TableName), 'IsUserTable') = 0 
				BEGIN
					RAISERROR('Object: %s exists but is NOT a User-defined Table. This procedure only accepts valid table names to process for index rebuilds.', 16, 1, @TableName)
					RETURN
				END
			ELSE
				BEGIN
					IF OBJECTPROPERTY(object_id(@TableName), 'IsTable') IS NULL
						BEGIN
							RAISERROR('Object: %s does not exist within this database. Please check the table name and location (which database?). This procedure only accepts existing table names to process for index rebuilds.', 16, 1, @TableName)
							RETURN
						END
				END
		END

	DECLARE @TableID int
	SET @TableID  = OBJECT_ID(@TableName)	

	-- Haal defragmentatiedata op

	   INSERT INTO #fraglist 
	   EXEC ('DBCC SHOWCONTIG (''' + @tablename + ''')   WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS')


	SELECT ObjectName, IndexName--, Max(TimeStamp) AS MaxTime
	INTO #Temp2
	FROM #fraglist 
	WHERE	--DatabaseName = DB_NAME() and
			(ObjectName LIKE '%' + @TableName OR @TableName IS NULL)
	GROUP BY ObjectName, IndexName


	DECLARE 	@DatabaseName			sysname,
				@DatabaseId			int,
				@ObjectName			sysname,
				@ObjectId			int,
				@IndexName			sysname,
				@QIndexName			nvarchar(258),
				@IndexId			int,
				@ActualScanDensity		numeric(10,2),
				@InformationalOutput		nvarchar(4000),
				@Table			 	sysname,
				@Command			nvarchar(2000),
				@Start				datetime



	DECLARE TableIndexList CURSOR FAST_FORWARD FOR 
		SELECT sc.ObjectName, ObjectId, sc.IndexName, IndexId, ScanDensity 
		FROM #fraglist AS sc
		INNER JOIN sysobjects AS so 
		ON sc.ObjectId = so.[id] 
		WHERE sc.ScanDensity <= @ScanDensity 
			AND OBJECTPROPERTY(sc.ObjectId, 'IsUserTable') = 1 
			AND so.status > 0
			AND sc.IndexId BETWEEN 1 AND 250 
			AND sc.ObjectName NOT IN ('dbo.dtproperties')
			AND sc.CountPages > 10 	-- Small indexes can be neglected  

			--  Here you can list large tables you do not WANT rebuilt.
			--  scandensity first in order by, most fragmented indexes will be treated first 
		ORDER BY sc.ScanDensity,sc.ObjectName, sc.IndexId

	OPEN TableIndexList

	FETCH NEXT FROM TableIndexList 
		INTO @ObjectName, @ObjectId, @IndexName, @IndexId, @ActualScanDensity

	WHILE (@@fetch_status = 0)
	BEGIN

		IF (SELECT COUNT(*) FROM sysobjects WHERE id = @ObjectId) > 0
		BEGIN	

			BEGIN
				
				SELECT @Table = @ObjectName
				SELECT @TableID = @ObjectId
				SELECT @QIndexName = QUOTENAME(@IndexName, ']')
				SELECT @InformationalOutput = 'Processing Table: ' + RTRIM(@Table) 
								+ ' Rebuilding Index: ' + RTRIM(@QIndexName) 

				SET @Start = GETDATE()

				IF @IndexId = 1 
--				Clustered index
				BEGIN
				SET @Command = (SELECT 'DBCC DBREINDEX(' + CHAR(39)+ @Table + CHAR(39)+ ', ' + @QIndexName + ') WITH NO_INFOMSGS')
					EXEC sp_executesql @Command
				END

				ELSE
--				Non-clustered index
				BEGIN
					SET @Command = (SELECT 'DBCC DBREINDEX(' + CHAR(39)+ @Table + CHAR(39)+ ', ' + @QIndexName + ') WITH NO_INFOMSGS')
					print @Command
					EXEC sp_executesql @Command
				END
				PRINT ' '

			END		
		END

		FETCH NEXT FROM TableIndexList 
			INTO @ObjectName, @ObjectId, @IndexName, @IndexId, @ActualScanDensity
	END

	CLOSE TableIndexList 
	DEALLOCATE TableIndexList 


	DROP TABLE #Temp2

	FETCH NEXT
      FROM tables
      INTO @tablename
END
select * FROM #fraglist
	drop TABLE #fraglist

-- Close and deallocate the cursor
CLOSE tables
DEALLOCATE tables

