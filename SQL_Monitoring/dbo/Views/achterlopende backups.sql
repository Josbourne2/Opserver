
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[achterlopende backups]
AS
SELECT     TOP (100) PERCENT MAX(mb.backup_datum) AS datum_laatste_backup, MAX(md.dbname) AS dbname, MAX(mi.server) AS server, mi.id AS instance_id, 
                      mi.domein, MAX(mb.db_type) AS db_type, MAX(ISNULL(mb.datum, GETDATE())) AS datum
FROM         dbo.Mon_Backups AS mb RIGHT OUTER JOIN
                      dbo.Mon_DB AS md ON mb.instance_id = md.instance_id AND mb.dbid = md.dbid INNER JOIN
                      dbo.Mon_Instance AS mi ON md.instance_id = mi.id
WHERE     (ISNULL(mi.te_bewaken, 1) = 1) AND (md.deldate IS NULL) AND (ISNULL(mb.type, N'D') IN ('D')) AND (md.dbid <> 2) AND (mi.editie NOT IN ('express', 
                      'MSDE')) AND (md.status & 512 <> 512) AND (mi.Controle = 1) AND (mi.server NOT IN ( 'ROS39', 'ZMPAS048.RECHTSPRAAK.MINJUS.NL'))
GROUP BY mi.id, md.dbid, mb.db_type, mb.type, mi.domein
HAVING      (mb.db_type = 'u') AND (MAX(mb.backup_datum) < MAX(mb.datum) - 1.5) OR
                      (mb.db_type = 's') AND (MAX(mb.backup_datum) <= MAX(mb.datum) - DATEPART(dw, MAX(mb.datum)) - 1) OR
                      (mb.type IS NULL)
ORDER BY server, dbname, datum_laatste_backup



GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[23] 4[29] 2[21] 3) )"
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
         Begin Table = "mb"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 4
         End
         Begin Table = "md"
            Begin Extent = 
               Top = 6
               Left = 484
               Bottom = 114
               Right = 651
            End
            DisplayFlags = 280
            TopColumn = 6
         End
         Begin Table = "mi"
            Begin Extent = 
               Top = 6
               Left = 250
               Bottom = 114
               Right = 446
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
      Begin ColumnWidths = 9
         Width = 284
         Width = 1830
         Width = 3165
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1800
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 2475
         Alias = 2130
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'achterlopende backups';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'achterlopende backups';

