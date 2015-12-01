/*====*/
CREATE VIEW [dbo].[Mon_Failed_Jobs]
AS
SELECT     TOP (100) PERCENT f.instance_id, dbo.InstName(f.instance_id) AS instance, mi.versie, mj.jobname, CASE WHEN f.laatste_failed > isnull(s.laatste_succ,
                       dateadd(d, - 1, f.laatste_failed)) THEN 'failed' ELSE 'success' END AS laatste_status, f.failed, f.aantal_failed, f.laatste_failed, s.success, s.aantal_succ, 
                      s.laatste_succ, mj.deldate
FROM         (SELECT     instance_id, MIN(rundate) AS eerste_failed, MAX(rundate) AS laatste_failed, status AS failed, COUNT(status) AS aantal_failed, job_id
                       FROM          dbo.Mon_Job_History AS mjh
                       WHERE      (rundate > GETDATE() - 45)
                       GROUP BY instance_id, status, job_id
                       HAVING      (status LIKE 'failed%')) AS f LEFT OUTER JOIN
                          (SELECT     mjh.instance_id, MIN(mjh.rundate) AS eerste_succ, MAX(mjh.rundate) AS laatste_succ, mjh.status AS success, COUNT(mjh.status) 
                                                   AS aantal_succ, mj.job_id
                            FROM          dbo.Mon_Job_History AS mjh INNER JOIN
                                                   dbo.mon_jobs AS mj ON mjh.job_id = mj.job_id
                            WHERE      (mjh.rundate > GETDATE() - 45)
                            GROUP BY mjh.instance_id, mjh.status, mj.job_id, mj.jobname
                            HAVING      (mjh.status LIKE 'suc%')) AS s ON f.instance_id = s.instance_id AND f.job_id = s.job_id INNER JOIN
                      dbo.mon_jobs AS mj ON f.job_id = mj.job_id INNER JOIN
                      dbo.Mon_Instance AS mi ON f.instance_id = mi.id
WHERE     (1 = 1) AND (CASE WHEN f.laatste_failed > isnull(s.laatste_succ, dateadd(d, - 1, f.laatste_failed)) THEN 'failed' ELSE 'success' END = 'failed') AND 
                      (f.laatste_failed > GETDATE() - 10) AND (mj.deldate IS NULL) AND (mj.job_enabled = 1) AND (mi.te_bewaken = 1)
ORDER BY mi.Instance


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
         Top = -96
         Left = 0
      End
      Begin Tables = 
         Begin Table = "f"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 189
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 227
               Bottom = 114
               Right = 378
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mj"
            Begin Extent = 
               Top = 160
               Left = 493
               Bottom = 268
               Right = 659
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mi"
            Begin Extent = 
               Top = 6
               Left = 416
               Bottom = 114
               Right = 604
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
      Begin ColumnWidths = 13
         Width = 284
         Width = 1605
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
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 2430
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
 ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Mon_Failed_Jobs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane2', @value = N'        Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Mon_Failed_Jobs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 2, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'Mon_Failed_Jobs';

