/*GETDATE()-1
order by sqlname,db,left(fname,10) + '...' + RIGHT(fname, 4),datestart
GO*/
CREATE VIEW [dbo].[vw_script_autogrow_aanpassen_ori]
AS
SELECT     MIN(d.date) AS datestart, MAX(d.date) AS laatste_check, i.server AS sqlname, td.db, CASE WHEN len(fname) > 15 THEN LEFT(fname, 10) + '...' + RIGHT(fname, 4) 
                      ELSE fname END AS filenm, d.Filesize_MB, d.growth, d.growthperc, d.fileid, 
                      MAX('sqlcmd -S ' + i.server + ' -E -Q "ALTER DATABASE [' + td.db + '] MODIFY FILE (NAME = N''' + d.fname + ''', FILEGROWTH = ' + CASE WHEN Filesize_MB BETWEEN
                       200 AND 499 THEN '100' WHEN Filesize_MB BETWEEN 500 AND 999 THEN '200' WHEN Filesize_MB < 200 THEN '50' ELSE '300' END + 'MB)' + '"') AS cmd
FROM         (SELECT     instance_id, dbid, name AS fname, fileid, filename, filegroup, size_kb / 1024 AS Filesize_MB, maxsize_kb, usage, controle_datum AS date, 
                                              CASE WHEN [growth] LIKE '%KB' THEN (replace(growth, ' KB', '') / 1024) WHEN [growth] LIKE '%MB' THEN replace(growth, ' MB', '') 
                                              WHEN [growth] LIKE '%[%]' THEN (replace(growth, '%', '')) END AS growth, CASE WHEN [growth] LIKE '%[%]' THEN 1 ELSE 0 END AS growthperc
                       FROM          dbo.Mon_DB_Files) AS d INNER JOIN
                      dbo.TBL_Databases AS td ON td.Instance_id = d.instance_id AND td.dbid = d.dbid INNER JOIN
                      dbo.Mon_Instance AS i ON i.id = d.instance_id INNER JOIN
                      dbo.Mon_DB AS db ON td.Instance_id = db.instance_id AND td.db = db.dbname
WHERE     (ISNULL(i.Controle, 1) = 1) AND (NOT (db.dbid = 2) OR
                      NOT (d.Filesize_MB = 1024) OR
                      NOT (d.growth = 100) OR
                      NOT (d.growthperc = 0)) AND (NOT (512 & db.status = 512)) AND (NOT (32 & db.status = 32)) AND (NOT (64 & db.status = 64)) AND (NOT (128 & db.status = 128)) AND 
                      (NOT (256 & db.status = 256)) AND (NOT (512 & db.status = 512)) AND (NOT (1024 & db.status = 1024)) AND (NOT (2048 & db.status = 2048)) AND 
                      (NOT (4096 & db.status = 4096)) AND (d.date > GETDATE() - 7) AND (d.growthperc = 1 AND d.growth > 0 OR
                      d.growthperc = 0 AND (d.growth < 50 AND d.growth > 0 OR
                      d.Filesize_MB > 1000 AND d.growth < 300 OR
                      d.Filesize_MB BETWEEN 200 AND 499 AND d.growth <> 100 OR
                      d.Filesize_MB BETWEEN 500 AND 999 AND d.growth <> 200))
GROUP BY i.Node, i.Instance, i.server, td.db, d.fname, d.Filesize_MB, d.growth, d.growthperc, d.fileid
HAVING      (MAX(d.date) >
                          (SELECT     MAX(controle_datum) - 1 AS Expr1
                            FROM          dbo.Mon_DB_Files AS Mon_DB_Files_1))


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "td"
            Begin Extent = 
               Top = 6
               Left = 243
               Bottom = 114
               Right = 410
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "i"
            Begin Extent = 
               Top = 114
               Left = 38
               Bottom = 222
               Right = 304
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "db"
            Begin Extent = 
               Top = 222
               Left = 38
               Bottom = 330
               Right = 209
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "d"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 205
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 11
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1590
         Alias = 2610
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 6900
         Or = 1350
         Or = 1350
        ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_script_autogrow_aanpassen_ori';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N' Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_script_autogrow_aanpassen_ori';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'vw_script_autogrow_aanpassen_ori';

