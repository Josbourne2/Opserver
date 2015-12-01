
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[Logins_met_sysadminrechten2]
AS
SELECT     mi.server, mi.versie, ml.name, ml.instance_id, ml.dbname, ml.language, ml.denylogin, ml.hasaccess, ml.isntname, ml.isntgroup, ml.isntuser, 
                      ml.sysadmin, ml.securityadmin, ml.serveradmin, ml.setupadmin, ml.processadmin, ml.diskadmin, ml.dbcreator, ml.bulkadmin, ml.loginname, 
                      ml.controle_datum, ml.del_datum
FROM         (SELECT     name, instance_id, dbname, language, denylogin, hasaccess, isntname, isntgroup, isntuser, sysadmin, securityadmin, serveradmin, 
                                              setupadmin, processadmin, diskadmin, dbcreator, bulkadmin, loginname, MAX(controle_datum) AS controle_datum, MAX(deletedate) 
                                              AS del_datum
                       FROM          dbo.Mon_Logins
                       WHERE      (sysadmin = - 1) AND (name NOT IN ('dba_ictro', 'sa'))
                       GROUP BY name, instance_id, dbname, language, denylogin, hasaccess, isntname, isntgroup, isntuser, sysadmin, securityadmin, serveradmin, 
                                              setupadmin, processadmin, diskadmin, dbcreator, bulkadmin, loginname) AS ml INNER JOIN
                      dbo.Mon_Instance AS mi ON ml.instance_id = mi.id


