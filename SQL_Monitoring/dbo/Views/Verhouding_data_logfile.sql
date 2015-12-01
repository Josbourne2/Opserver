CREATE VIEW [dbo].[Verhouding_data_logfile]
AS
SELECT     TOP (100) PERCENT c.server, c.instance, c.Versie, MAX(c.datum) AS meetdatum, mb.dbname, SUM(CAST(c.DAT_size AS decimal(38, 1))) AS data_MB, 
                      SUM(CAST(c.LOG_size AS decimal(38, 1))) AS log_MB, CASE WHEN SUM(LOG_size) > SUM(dat_size) THEN 'erg grote log' WHEN SUM(LOG_size) 
                      > (SUM(DAT_size) / 2) THEN 'grote log' END AS alarm, c.Instance_id
FROM         (SELECT     server, instance, dbid, Versie, datum, CASE WHEN b.filetype IN ('DAT', 'ROW') THEN size_MB ELSE 0 END AS DAT_size, 
                                              CASE WHEN b.filetype = 'LOG' THEN size_MB ELSE 0 END AS LOG_size, Instance_id
                       FROM          (SELECT     mfs.Instance_id, MAX(mi.Node) AS server, MAX(mi.Instance) AS instance, mfs.Versie, mfs.filetype, mfs.dbid, SUM(mfs.size_MB) 
                                                                      AS size_MB, MAX(mfs.date) AS datum
                                               FROM          dbo.Mon_FileSizes AS mfs INNER JOIN
                                                                          (SELECT     Instance_id, dbid, filetype, MAX(date) AS date
                                                                            FROM          dbo.Mon_FileSizes
                                                                            GROUP BY Instance_id, dbid, filetype) AS f ON mfs.Instance_id = f.Instance_id AND mfs.dbid = f.dbid AND 
                                                                      mfs.filetype = f.filetype AND mfs.date = f.date INNER JOIN
                                                                      dbo.Mon_Instance AS mi ON mfs.Instance_id = mi.id
                                               GROUP BY mfs.Instance_id, mfs.Versie, mfs.dbid, mfs.filetype) AS b) AS c INNER JOIN
                      dbo.Mon_Instance AS mi ON c.Instance_id = mi.id INNER JOIN
                          (SELECT     instance_id, dbid, dbname
                            FROM          dbo.Mon_DB
                            WHERE      (deldate IS NULL)) AS mb ON mb.instance_id = c.Instance_id AND mb.dbid = c.dbid
WHERE     (mi.te_bewaken = 1)
GROUP BY c.server, c.instance, c.Instance_id, c.Versie, mb.dbname
ORDER BY c.server, mb.dbname


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[18] 4[17] 2[36] 3) )"
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
         Begin Table = "mi"
            Begin Extent = 
               Top = 6
               Left = 243
               Bottom = 114
               Right = 447
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 205
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mb"
            Begin Extent = 
               Top = 6
               Left = 485
               Bottom = 99
               Right = 652
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
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
         Width = 630
         Width = 1665
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
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Verhouding_data_logfile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Verhouding_data_logfile';

