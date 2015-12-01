
　
　
CREATE VIEW [dbo].[vw_script_autoclose_autoshrink_aanpassen]
AS
SELECT DISTINCT 
sqlname, db,date as date_checked, AutoShrink, AutoClose,AutoCreateStatisticsEnabled,AutoupdateStatisticsEnabled ,
'sqlcmd -S ' + sqlname + ' -E -Q "ALTER DATABASE [' + db + '] SET ' + CASE 
WHEN AutoClose =1 then 'AUTO_CLOSE OFF " ' 
WHEN autoshrink = 1 THEN 'AUTO_SHRINK OFF "' 
WHEN AutoCreateStatisticsEnabled = 0 then 'AUTO_CREATE_STATISTICS ON "'
when AutoUpdateStatisticsEnabled =0 then 'AUTO_UPDATE_STATISTICS ON "'
END AS cmd
FROM 
(
SELECT -- *
date
,d.Instance_id
,i.server as sqlname
,d.db
,d.DbId
,AutoClose
,AutoShrink
,AutoCreateStatisticsEnabled
,AutoUpdateStatisticsEnabled
,status
,i.CONTROLE
, RANK() OVER (partition BY d.instance_id,d.db
ORDER BY DATE DESC) rank1
FROM [DatabasePropsStatic] d
inner join mon_Instance i on i.id = d. Instance_id
inner join dbo.TBL_Databases t on d.Instance_id=t.Instance_id and d.Db = t.db and d.Dbid = t.dbid
where t.date_deleted is null
) a
WHERE 
rank1 =1
and isnull(a.controle,1) =1

and status = 'ONLINE' and (AutoShrink = 1 or AutoClose = 1
or AutoCreateStatisticsEnabled =0 or AutoUpdateStatisticsEnabled =0
) 
and (
Instance_id not in (select Instance_id from TBL_Databases where db like 'sharepoint%' or db like 'sp_content%'
or db like '%_AdminContentDB' or db like '%_ConfigDB' or db like 'WSS_Content%'
or db like '%ContentDB%' or db like '%ProfileDB%' or db like '%SocialDB%' OR DB IN('BizTalkMsgBoxDb')) --sharepoint EN BIZTALK regelt het zelf
OR
AutoCreateStatisticsEnabled=1 and AutoUpdateStatisticsEnabled =0
)

