CREATE VIEW [Documentation].[vwShowAllDatabases]
	AS SELECT D.[DatabaseID],
			  L.[Location],
			  E.[Environment],
			  S.[Server],
			  S.[DNS],
			  D.[Name],
			  CASE CHARINDEX('1', CAST(ISNULL([IsPublished], 0) AS CHAR(1)) + CAST(ISNULL([IsMergePublished], 0) AS CHAR(1)))
				WHEN 0 THEN ''
				ELSE 'Yes'
			  END AS [Published]
	   FROM [Documentation].[Databases] D
       LEFT OUTER JOIN [Lookup].[Locations] L ON D.LocationID = L.LocationID
       LEFT OUTER JOIN [Lookup].[Environments] E ON D.EnvironmentID = E.EnvironmentID
       LEFT OUTER JOIN [Lookup].[Servers] S ON D.ServerID = S.ServerID