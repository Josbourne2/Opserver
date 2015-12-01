CREATE VIEW [dbo].[Mon_Instance_Databases]
AS
SELECT
      [Node]
      ,[Instance]
    , md.*
  FROM [dbo].[Mon_Instance] mi
  OUTER APPLY ( SELECT instance_id, SUM(CASE WHEN dbid > 5 THEN 1 else 0 END) as aantal_user_dbs
FROM [dbo].[Mon_DB] md
WHERE md.instance_id = mi.id
GROUP BY instance_id) md
	
	
	
  
