


CREATE VIEW [dbo].[Current_Monitored_Databases]
AS
SELECT     mi.Node, mi.Instance, mi.id AS instance_id, mi.eigenaar, mi.opmerkingen, mi.build,db.dbname, db.Applicatie AS db_applicatie, db.Contact AS db_contact,
 

      db.[eigenaar] AS db_eigenaar
      ,db.[contactpersoon] AS db_contactpersoon
      ,db.[dienst] AS db_dienst

  ,SUM(dbf.size_kb) AS size_kb
FROM dbo.Mon_Instance mi
	INNER JOIN dbo.Mon_DB db
		ON mi.id = db.instance_id
	LEFT JOIN dbo.Mon_DB_Files dbf
		ON db.instance_id = dbf.instance_id
		AND db.dbid = dbf.dbid   
WHERE     (mi.Controle = 1) AND (ISNULL(mi.te_bewaken, 1) = 1) AND (db.deldate IS NULL)

GROUP BY mi.Node, mi.Instance, mi.id,mi.eigenaar, mi.opmerkingen, mi.build, db.dbname, db.Applicatie, db.Contact, db.[eigenaar], db.contactpersoon, db.dienst
--HAVING      (db.dbname IS NOT NULL) AND (mi.Node IS NOT NULL)




