


CREATE VIEW [dbo].[Servers zonder recente userdbbackupinfo]
AS
--SELECT      mb.type, MAX(mb.backup_datum) AS datum_laatste_backup_userdb, mi.Node, mi.instance, MAX(mb.datum) AS datum_controle,
--                       mb.db_type, mi.Controle, mi.opmerkingen
--FROM         dbo.Mon_Backups AS mb INNER JOIN
--                      dbo.Mon_Instance AS mi ON mb.instance_id = mi.id
--WHERE     (mb.type IN ('D','L','I')) AND (ISNULL(mi.te_bewaken, 1) = 1) AND (mb.db_type = 'u') and (mi.Controle = '1')
--GROUP BY mi.instance, mi.Node, mb.type, mb.db_type, mi.Controle, mi.opmerkingen
--HAVING      (MAX(mb.datum) < GETDATE() - 3)
----ORDER BY datum_laatste_backup_userdb



--GO


select * from(
		SELECT      case mb.type when 'D' then 'FULL' else 'DIFF' end as type, mb.backup_datum AS datum_laatste_backup_userdb, mi.Node, mi.instance, (mb.datum) AS datum_controle,
							   mb.db_type, mi.Controle, mi.opmerkingen, rank() over ( partition by mi.node,mi.instance order by mb.datum desc,database_name) as rank
		FROM         dbo.Mon_Backups AS mb 
					INNER JOIn
					 dbo.Mon_Instance AS mi ON mb.instance_id = mi.id
		WHERE     (mb.type IN ('D','I')) AND (ISNULL(mi.te_bewaken, 1) = 1) AND (mb.db_type = 'u')
		and mi.Controle = '1'
	) a
--GROUP BY mi.instance, mi.Node, mb.type, mb.db_type, mi.Controle, mi.opmerkingen
--HAVING      (mi.Controle = '1') AND
where rank=1 and  datum_controle < GETDATE() - 3
--ORDER BY datum_laatste_backup_userdb



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
         Begin Table = "mb"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 304
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 0
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
         Width = 1500
         Width = 3645
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Servers zonder recente userdbbackupinfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Servers zonder recente userdbbackupinfo';

