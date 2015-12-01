


CREATE PROCEDURE [dbo].[sp_mon_DB_appcontact]
AS
BEGIN

/* First, create all linked servers */


CREATE TABLE #AllExtendedProperties (servername VARCHAR(255), dbname NVARCHAR(255), name NVARCHAR(255), value NVARCHAR(255))

DECLARE @Server NVARCHAR(255); 

DECLARE NODE_CURSOR CURSOR FAST_FORWARD FOR
SELECT server
FROM dbo.Mon_Instance
WHERE controle = 1 AND te_bewaken = 1;

OPEN NODE_CURSOR;

FETCH NEXT FROM NODE_CURSOR INTO @Server;

WHILE(@@FETCH_STATUS = 0)
BEGIN
	
	EXEC dbo.sp_mon_CreateLinkedServer @Server,0;

	FETCH NEXT FROM NODE_CURSOR INTO @Server;
END

CLOSE NODE_CURSOR;
DEALLOCATE NODE_CURSOR;


/* Find users that own a schema, but shouldnt. (system schemas should be owned by system roles, for instance,
	the db_owner schema should be owned by the db_owner role, not by a database user
*/


DECLARE @SQLCMDSRC1 NVARCHAR(MAX)= 'SELECT ''server'' AS sname, ''dbname'' AS databasename, CAST(e.name AS NVARCHAR(255)) AS name, CAST(e.value AS NVARCHAR(255)) AS value
									FROM [server].[dbname].[sys].[extended_properties] e'
									

DECLARE @SQLCMD NVARCHAR(MAX);
DECLARE @DBName NVARCHAR(255);


DECLARE DB_CURSOR CURSOR FAST_FORWARD FOR
SELECT db.[server], dbname
FROM dbo.mon_db db
	INNER JOIN dbo.Mon_Instance I
		ON db.instance_id = I.id
WHERE i.te_bewaken = 1 AND i.Controle = 1
and db.deldate IS NULL;


OPEN DB_CURSOR

FETCH NEXT FROM DB_CURSOR INTO @Server, @DBName;

WHILE (@@FETCH_STATUS =0)
BEGIN

	SET @SQLCMD = REPLACE(@SQLCMDSRC1, 'server',@Server);
	SET @SQLCMD = REPLACE(@SQLCMD,'dbname', @DBName);
	PRINT @SQLCMD;
	
	BEGIN TRY

		INSERT INTO #AllExtendedProperties (servername, dbname, name, value)
		EXEC (@SQLCMD);

	END TRY
	BEGIN CATCH

	END CATCH

	FETCH NEXT FROM DB_CURSOR INTO @Server, @DBName;
END

CLOSE DB_CURSOR;

DEALLOCATE DB_CURSOR;

/* Update contactinformatie in Mon_DB */

;
WITH 
cte1 as 
(select * from #AllExtendedProperties where name = 'app'), 
cte2 as
(select * from #AllExtendedProperties where name = 'contact')
MERGE INTO dbo.Mon_DB AS TARGET
USING (SELECT d.dbname, d.server,c.value as Applicatie,c2.value as Contact 
	   FROM dbo.Mon_DB d --where dbname= 'armanagement69' order by 1,2
			INNER JOIN cte2 c2 
				ON d.dbname=c2.dbname
				AND d.server = c2.servername
			INNER JOIN cte1 c 
				ON d.dbname=c.dbname
				AND d.server = c.servername where d.deldate is null ) AS SOURCE
	ON TARGET.dbname = SOURCE.dbname
	AND TARGET.server = SOURCE.server
WHEN MATCHED 
THEN
	UPDATE SET TARGET.Applicatie = SOURCE.Applicatie,
				TARGET.Contact = SOURCE.Contact;

DROP TABLE #AllExtendedProperties


/* Remove all linked servers */




DECLARE NODE_CURSOR CURSOR FAST_FORWARD FOR
SELECT server
FROM dbo.Mon_Instance
WHERE controle = 1 AND te_bewaken = 1;

OPEN NODE_CURSOR;

FETCH NEXT FROM NODE_CURSOR INTO @Server;

WHILE(@@FETCH_STATUS = 0)
BEGIN
	
	EXEC sp_dropserver @Server ,'droplogins'

	FETCH NEXT FROM NODE_CURSOR INTO @Server;
END

CLOSE NODE_CURSOR;
DEALLOCATE NODE_CURSOR;




END



