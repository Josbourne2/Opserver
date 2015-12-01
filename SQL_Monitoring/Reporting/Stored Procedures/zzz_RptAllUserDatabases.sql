

CREATE PROCEDURE [Reporting].[zzz_RptAllUserDatabases] 
@nodes AS VARCHAR(MAX) = NULL
AS
BEGIN

	SET NOCOUNT ON;

	SELECT MI.node, MI.instance,
      MDB.[dbname]
      ,MDB.[dbid]
      ,MDB.[mode]
      ,MDB.[status]
      ,MDB.[status2]
      ,MDB.[crdate]    
      ,MDB.cmptlevel
      ,MDB.[filename]
      ,MDB.[version]
      ,MDB.[id]
      ,MDB.[datum]
      ,MDB.[deldate]
      ,MDB.[instance_id]
      ,MDB.[creator]
	  ,MDBF.size_kb /1024.0 AS data_file_size_MB
	  ,MDBLF.size_kb / 1024.0 AS log_file_size_MB
  FROM  dbo.Mon_Instance MI
	LEFT JOIN  [dbo].[Mon_DB] MDB
		ON MI.id = MDB.instance_id
	---- Get log file size
	OUTER APPLY (	SELECT size_kb 
					FROM dbo.Mon_DB_Files MDF
					WHERE MDB.dbid = MDF.dbid 
						AND mdb.instance_id = MDF.instance_id
					AND usage = 'log only'
				) MDBLF
	OUTER APPLY (	SELECT SUM(size_kb) AS size_kb
					FROM dbo.Mon_DB_Files MDF
					WHERE MDB.dbid = MDF.dbid 
						AND mdb.instance_id = MDF.instance_id
					AND usage = 'data only'
				)MDBF
  WHERE MDB.dbid > 4
	AND MI.te_bewaken = 1 and MI.Controle = 1 AND MDB.deldate IS NULL
	AND ( MI.Node IN (SELECT VALUE FROM dbo.SPLIT(',',@nodes)) 
		OR
		 @nodes IS NULL)

END


