
CREATE VIEW [dbo].[filegroei aanpassen grote dbs]
AS
SELECT      dbo.InstName(mf.instance_id) AS Expr1, mf.instance_id, mf.dbid, md.dbname, mf.name, mf.fileid, mf.filename, mf.filegroup, mf.size_kb, 
                      mf.size_kb / 1024 AS size_MB, mf.maxsize_kb, mf.growth, mf.usage, mf.date, 
                      'sqlcmd.exe -E -S ' + dbo.InstName(mf.instance_id) 
                      + ' -Q "ALTER DATABASE  [' + md.dbname + ']  MODIFY FILE ( NAME = N''' + RTRIM(LTRIM(mf.name)) + ''', FILEGROWTH = 307200KB )"' AS Expr2
FROM         dbo.Mon_DB_Files AS mf LEFT OUTER JOIN
                      dbo.Mon_Instance AS mi ON mf.instance_id = mi.id INNER JOIN
                      dbo.Mon_DB AS md ON mf.dbid = md.dbid AND mf.instance_id = md.instance_id
WHERE     (1 = 1) AND (mf.dbid > 4) AND (mf.size_kb > 3000000) AND (mf.growth <> '0%') AND (ISNULL(mi.te_bewaken, 1) = 1) AND (mi.Controle = 1)

union all

SELECT      dbo.InstName(mf.instance_id) AS Expr1, mf.instance_id, mf.dbid, md.dbname, mf.name, mf.fileid, mf.filename, mf.filegroup, mf.size_kb, 
                      mf.size_kb / 1024 AS size_MB, mf.maxsize_kb, mf.growth, mf.usage, mf.date
      ,'sqlcmd.exe -E -S ' + [dbo].InstName(mf.instance_id) +' -Q "ALTER DATABASE  ['+ dbname + ']  MODIFY FILE ( NAME = N'''+ rtrim(ltrim(name)) + ''', FILEGROWTH = 204800KB )"'
  FROM [dbo].[Mon_DB_Files] mf
  left outer join [dbo].mon_instance mi on mf.instance_id = mi.id 
  inner join [dbo].Mon_DB md on mf.dbid = md.dbid and mf.instance_id = md.instance_id
  where 1=1
  and isnull(te_bewaken,1) =1 and controle=1
  and mf.dbid >4
  and [size_kb] between 2000000 and 3000000
  and growth <> '0%'
  and (right(growth,1)='%' 
	or 	(right(growth,2) = ('KB') and (left(growth, len(growth) -3) > 204800 ))
	or (right(growth,2) = ('KB') and (left(growth, len(growth) -3) <200000)) 
  )



GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[4] 2[25] 3) )"
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
         Begin Table = "mf"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 189
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "md"
            Begin Extent = 
               Top = 6
               Left = 227
               Bottom = 114
               Right = 378
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
      Begin ColumnWidths = 16
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 16515
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
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
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'filegroei aanpassen grote dbs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'VIEW', @level1name = N'filegroei aanpassen grote dbs';

