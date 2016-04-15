WITH DefaultConnectionString AS
(
SELECT N'Data Source=$ServerName$;Initial Catalog=master;Integrated Security=SSPI;' AS defaultConnectionString
)
SELECT defaultConnectionString,
(	SELECT Name AS "@name", 20 AS "refreshIntervalSeconds",
		(
			SELECT I.node AS "@name"
			FROM dbo.Mon_Instance I
			WHERE I.mon_cluster_id = c.id
			for xml path ('name'),root ('nodes'),type
			)
	FROM OpManager.Mon_Clusters c
	for xml path ('name') ,root('clusters') , type
)
FROM DefaultConnectionString
FOR XML PATH ('SqlSettings')--, root('SqlSettings'), type