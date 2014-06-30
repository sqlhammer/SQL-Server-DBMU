/*					Original Version					*/
/* ------------------------------------------------------
 * Procedure:	dbo.usp_Maintenance_SelectiveReIndex
 * Author:		Fred Loud
 * Dates:		Created - 18 Jan 2011
 * Description:	Execute the ReIndexing of the indexes that are 
 *		necessary based on their fragmentation level
 * ------------------------------------------------------ */

/*		Modified for Utility Database Interfacing		*/
/*
PROCEDURE:		[IndexMaint].[usp_SelectiveReindex]
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure reads from an index statistics table and based on thresholds from configuration tables
				will REORGANIZE or REBUILD indexes selectively within a set time window.
PARAMETERS:		@debug BIT -- Setting this parameter to 1 will print what would have happened without executing the commands.
*/
/*
CHANGE HISTORY:

** Derik Hammer ** 10/01/2012 --	Altered the procedure to use sys.dm_db_index_physical_stats instead of DBCC SHOWCONTIG
									due to the deprecation of DBCC SHOWCONTIG in SQL 2012.

** Derik Hammer ** 10/04/2012 --	Added funtionality which supports updating statistics on indexes that don't get index
									maintenance very often but need accurate statistics.

** Derik Hammer ** 10/23/2012 --	Commented out the debug feature due to a change of logic flow that causes an infinite loop
									when the live table isn't being updated. Whether to include this feature in the future is unknown.

** Derik Hammer ** 12/12/2012 --	Updated to correct bug where indexes were being skipped. INNER JOINs in the WHILE condition were 
									removed.

** Derik Hammer ** 12/02/2013 --	Created temporary lookup tables for edition and feature parsing.

** Derik Hammer/   
   Mikhail Wall ** 12/11/2013 --	Added support for online and individual partition index rebuilds - by version and 
									when specified by the index maintenance option.

*/
CREATE PROCEDURE  [IndexMaint].[usp_SelectiveReindex] 
--(
--	@Debug bit = 0
--) 
As
Begin
	SET NOCOUNT ON

	DECLARE @DatabaseID				int
	DECLARE @ExecStatement			varchar(4000)
	DECLARE @ExecMessage			varchar(4000)
	DECLARE @IndexStatisticID		int
	DECLARE @ObjectID				int
	DECLARE @TableName				sysname
	DECLARE @IndexID				int
	DECLARE @IndexName				sysname
	DECLARE @isLOBType				bit
	DECLARE @FragLimit				tinyint
	DECLARE @FillFactor				tinyint
	DECLARE @Fragmentation			tinyint
	DECLARE @PageSpaceLimit			tinyint
	DECLARE @PageSpaceUsed			tinyint
	DECLARE @LastError				int
	DECLARE @ExecuteWindowEnd		tinyint		-- End hour, for when to stop processing
	DECLARE @MaxDefrag				tinyint 	-- Maximum fragmentation before defraging will become rebuild
	DECLARE	@DatabaseName			sysname
	DECLARE @IndexMaintOptionsID	INT
	DECLARE @IndexStatus			VARCHAR(50)
	DECLARE @FeatureAggregate		INT
	DECLARE @LogEntry				VARCHAR(8000)
	DECLARE @OnlineRebuild			NVARCHAR(25) = '';
	DECLARE @PartitionNumber		INT
	DECLARE @PartitionRebuild		NVARCHAR(25) = '';
	DECLARE @PreferOnline			BIT
	DECLARE @RebuildReorganize		NVARCHAR(25) = '';
	DECLARE @Version				NUMERIC(18,10);
	DECLARE @idxDataTypeAndLength	NVARCHAR(50);
	DECLARE @SchemaName				sysname;
	DECLARE @TableOnlyName			sysname;
	DECLARE @sqlQuery				NVARCHAR(max);
	DECLARE @parmDef				NVARCHAR(25);

	--Look-ups
	SELECT @Version = [dbo].[udf_GetVersion]()

	;WITH Editions AS (
		SELECT 'Enterprise' AS [Edition], 2 AS [FeatureAggregate]
		UNION ALL 
		SELECT 'Business Intelligence' AS [Edition], 0 AS [FeatureAggregate]
		UNION ALL 
		SELECT 'Standard' AS [Edition], 0 AS [FeatureAggregate]
		UNION ALL 
		SELECT 'Developer' AS [Edition], 2 AS [FeatureAggregate]
		UNION ALL 
		SELECT 'Express' AS [Edition], 0 AS [FeatureAggregate]
		UNION ALL 
		SELECT 'Evaluation' AS [Edition], 2 AS [FeatureAggregate]
		)
	SELECT @FeatureAggregate = FeatureAggregate
	FROM Editions 
	WHERE Edition = (SELECT [dbo].[udf_GetEdition]())

	DECLARE @FeatureInfo TABLE (Feature NVARCHAR(50), Value INT);
	INSERT INTO @FeatureInfo (Feature, Value)
		SELECT 'ONLINE', 2

	--Initiate cursor loop for all enabled configurations.
	DECLARE EnabledConfigs CURSOR FAST_FORWARD
	FOR
	SELECT imo.[OptionID]
	FROM [IndexMaint].[Options] imo
	INNER JOIN [IndexMaint].[Configs] imc ON imc.[OptionID] = imo.[OptionID]
	INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = imc.[ConfigID]
	WHERE c.[IsEnabled] = 1 AND imc.[IsEnabled] = 1  

	OPEN EnabledConfigs
	FETCH NEXT FROM EnabledConfigs INTO @IndexMaintOptionsID

	WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'EnabledConfigs' ) = 0 
	BEGIN
    
		SELECT @ExecuteWindowEnd = ExecuteWindowEnd
			, @MaxDefrag = MaxDefrag
			, @FragLimit = FragLimit
			, @PageSpaceLimit = PageSpaceLimit
			, @PreferOnline = PreferOnline
		FROM [IndexMaint].[Options]
		WHERE [OptionID] = @IndexMaintOptionsID

		DECLARE Databases_cur CURSOR FAST_FORWARD
		FOR
		SELECT Rdb.DatabaseName
		FROM [Configuration].RegisteredDatabases Rdb
		INNER JOIN [IndexMaint].[Databases] Idb ON Idb.DatabaseID = Rdb.DatabaseID
		INNER JOIN sys.databases sysDBs ON Rdb.DatabaseName = sysDBs.name
		WHERE Idb.[OptionID] = @IndexMaintOptionsID
			AND sysDBs.[state] = 0 --Ensure the database is ONLINE to continue.

		OPEN Databases_cur
		FETCH NEXT FROM Databases_cur INTO @DatabaseName

		WHILE ( SELECT  fetch_status FROM sys.dm_exec_cursors(@@SPID) WHERE   name = 'Databases_cur' ) = 0 
		BEGIN
          
			-- Check the date/time restriction before the process starts
			IF Not @ExecuteWindowEnd = Null
			Begin
				IF DATEPART(hour, GETDATE()) >= @ExecuteWindowEnd
				BEGIN
					SET @LogEntry = 'Exiting IndexMaint.usp_SelectiveReIndex because we have passed the Execution Window''s end. Current Hour: ' + CAST(DATEPART(hour, GETDATE()) AS VARCHAR(2)) + ', @ExecuteWindowEnd: ' + CAST(@ExecuteWindowEnd AS VARCHAR(2))
					EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'              
					RETURN;
				End
			END
  
			SET @LogEntry = 'Performing index maintenance on database ' + @DatabaseName + ' in accordance with Option ID ' + CAST(@IndexMaintOptionsID AS VARCHAR(10))
			EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'LIMITED'          

			-- delete the temp table if it still exists
			IF OBJECT_ID('tempdb..#IndexCheck') IS NOT NULL 
			Begin 
				DROP TABLE #IndexCheck
			End

			-- Create the table to store the results of checking to see if the index exists
			CREATE TABLE #IndexCheck ([id] int, [type] varchar(50))
			
			--Loop through each record to perform maintenance, until there are no more indexes needing maintenance or the execution window ends.
			-- -- A while loop was added instead of a cursor because a cursor's data set is static and in this case a single index would have 
			-- -- been reorged or rebuilt more than once. In this case when maintenance has been conducted on an index all of it's associated
			-- -- records are updated with 'Index Optimized' and the WHILE loop will do another SELECT TOP 1 which won't include the duplicate rows.
			-- -- The duplicate rows weren't removed from the result set because each index level has different frag levels and page density.
			WHILE EXISTS	(
								Select TOP 1 ISTAT.IndexStatisticID
								From [IndexMaint].[Statistics] ISTAT
									--Inner Join (Select MAX(IndexStatisticID) As IndexStatisticID
									--			From [IndexMaint].[Statistics]
									--			Where DatabaseName = @DatabaseName 
									--			Group By OBJECT_ID(TableName), TableName, IndexID, IndexName) UIDX
									--On (ISTAT.IndexStatisticID = UIDX.IndexStatisticID)
								Where DatabaseName = @DatabaseName 
									And (IndexStatus = 'Index Maintenance Required'
										OR IndexStatus = 'Statistic Maintenance Required')
									And LEN(LTRIM(RTRIM(IndexName))) > 0  -- Needs to have an index name...
									And (IndexID > 0 And IndexID < 255)
							)
			Begin
				-- clear the index check table
				Delete From #IndexCheck

				Select TOP 1 
					@IndexStatisticID = ISTAT.IndexStatisticID
					, @ObjectID = OBJECT_ID(TableName), @TableName = (QUOTENAME(LTRIM(RTRIM(SchemaName))) + '.' + QUOTENAME(LTRIM(RTRIM(TableName))))
					, @IndexName = LTRIM(RTRIM(IndexName)), @FillFactor = [FillFactor]
					, @Fragmentation = [AvgFragmentationPercent], @PageSpaceUsed = AvgPageSpaceUsedPercent
					, @IndexStatus = IndexStatus
					, @PartitionNumber = PartitionNumber
					, @SchemaName = (LTRIM(RTRIM(SchemaName)))
					, @TableOnlyName = (LTRIM(RTRIM(TableName)))
				From [IndexMaint].[Statistics] ISTAT
					--Inner Join (Select MAX(IndexStatisticID) As IndexStatisticID
					--			From [IndexMaint].[Statistics]
					--			Where DatabaseName = @DatabaseName 
					--			Group By OBJECT_ID((QUOTENAME(LTRIM(RTRIM(SchemaName))) + '.' + QUOTENAME(LTRIM(RTRIM(TableName))))), TableName, IndexID, IndexName) UIDX
					--On (ISTAT.IndexStatisticID = UIDX.IndexStatisticID)
				Where DatabaseName = @DatabaseName 
					And (IndexStatus = 'Index Maintenance Required'
						OR IndexStatus = 'Statistic Maintenance Required')
					And LEN(LTRIM(RTRIM(IndexName))) > 0  -- Needs to have an index name...
					And (IndexID > 0 And IndexID < 255)
						
				-- Verify the index exists by retrieving the ids from the source database
				Insert Into #IndexCheck ([id], [type])
					EXEC ('USE [' + @DatabaseName + '];
							-- verify the table exists (Row 1)
							Select [id], ''Table'' 
							From dbo.sysobjects obj 
							Where id = OBJECT_ID(RTRIM(''' + @TableName + ''')) 
								And OBJECTPROPERTY(id, N''IsUserTable'') = 1
							Union All
							-- verify the index exists (row 2)
							Select [object_id]
								, Case When allow_page_locks = 0 Then ''Index - No Page Lock'' Else ''Index'' End
							From sys.indexes 
							Where name = RTRIM(''' + @IndexName + ''') 
								And [object_id] = OBJECT_ID(RTRIM(''' + @TableName + '''));')

				-- Verify the IndexCheck table has two records
				IF (Select COUNT([id]) From #IndexCheck) = 2
				BEGIN
					IF @IndexStatus = 'Statistic Maintenance Required'
					BEGIN
						SET @ExecStatement = 'UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;'
						SET @ExecMessage = '-- Executing UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;'
					END
                    
					IF @IndexStatus = 'Index Maintenance Required'
					BEGIN          
						-- Default initialization: ONLINE=OFF (empty string) and PARTITION=ALL
						SET @OnlineRebuild = '';
						SET @PartitionRebuild = 'ALL';
						
						-- Determine if the index should be defragmented or reindexed and always update statistics for indexes which were altered.
						IF (@Fragmentation > @MaxDefrag) OR (((@PageSpaceUsed  / (CASE @FillFactor WHEN 0 THEN 100 ELSE @FillFactor END) * 100) > 100))
							Or EXISTS(Select 1 From #IndexCheck Where [type] = 'Index - No Page Lock')
						BEGIN
							SET @RebuildReorganize = ' REBUILD';
							-- Determine if any index columns are of prohibitive LOB types (by version for certain types)
							SELECT @sqlQuery = N'
							USE [' + @DatabaseName + ']
							IF EXISTS ( SELECT  o.object_id
										FROM    sys.objects o
												INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
												LEFT JOIN sys.columns c ON o.object_id = c.object_id
												JOIN sys.types t ON t.system_type_id = c.system_type_id
										WHERE   (o.name = ''' + @TableOnlyName + '''
												 AND s.name = ''' + @SchemaName + ''')
												AND CASE WHEN t.name = ''text'' THEN 1
														 WHEN t.name = ''ntext'' THEN 1
														 WHEN t.name = ''image'' THEN 1
														 WHEN t.name = ''varchar''
															  AND c.max_length = -1 THEN 1
														 WHEN t.name = ''nvarchar''
															  AND c.max_length = -1 THEN 1
														 WHEN t.name = ''varbinary''
															  AND c.max_length = -1 THEN 1
														 WHEN t.name = ''xml'' THEN 1
														 ELSE 0
													END = 1 )
								BEGIN
									SET @isLOBTypeOUT = 1
								END
							ELSE
								BEGIN 
									SET @isLOBTypeOUT = 0
								END;';

							--PRINT N'@sqlQuery: ' + @sqlQuery;

							SELECT @parmDef = N'@isLOBTypeOUT BIT OUTPUT';

							EXEC sp_executesql 
								@sqlQuery
								, @parmDef
								, @isLOBTypeOUT = @isLOBType OUTPUT;
							
							-- Set whether to REBUILD ONLINE
							IF EXISTS (SELECT [value] FROM [dbo].[udf_ParsePowersOfTwo](@FeatureAggregate) 
										WHERE [value] = (SELECT value FROM @FeatureInfo WHERE Feature = 'ONLINE'))
							   AND @isLOBType = 0
							   AND @PreferOnline = 1
							BEGIN
								SET @OnlineRebuild = ' WITH (ONLINE=ON)';
							END

							-- REBUILD specified PARTITION by (1)version, (2) if desired, (3) and if index is partitioned OR ALL
							IF ((@Version < 12 AND @OnlineRebuild = '')
								OR (@Version >= 12))
							   AND EXISTS ( SELECT	IndexName
											FROM	[IndexMaint].[Statistics]
											WHERE	IndexName = @IndexName
													AND DatabaseName = @DatabaseName
													AND ( QUOTENAME(LTRIM(RTRIM(SchemaName))) + '.'
														  + QUOTENAME(LTRIM(RTRIM(TableName))) ) = @TableName 
													AND PartitionNumber > 1 )
							BEGIN
								SET @PartitionRebuild = CAST(@PartitionNumber AS NVARCHAR(25))
							END
						END
						ELSE
						BEGIN
							SET @RebuildReorganize = ' REORGANIZE';
						END

						SET @ExecStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + @RebuildReorganize + ' PARTITION = ' + @PartitionRebuild + @OnlineRebuild + ';';
						SET @ExecStatement = @ExecStatement + ' UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;';
						SET @ExecMessage = '-- Executing ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + @RebuildReorganize + ' PARTITION = ' + @PartitionRebuild + @OnlineRebuild + ';';
						SET @ExecMessage = @ExecMessage + ' -- Executing UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;';
					END

					-- See if the statement should be displayed or executed
					--IF @Debug = 1
					--Begin
					--	Select @ExecMessage As ExecMessage, @ExecStatement As ExecStatement
					--End
					--ELSE
					--Begin

						SET @LogEntry = 'Executing: ' + @ExecStatement
						EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  
						
						-- Execute the statment for the index
						--PRINT @ExecStatement;
						EXEC (@ExecStatement)
						Set @LastError = @@ERROR				
				
						-- Update the Index Statistics table with the new status.
						-- Update all rows for the given index so that maintenance isn't performed excessively.
						UPDATE  [IndexMaint].[Statistics]
						SET     IndexStatus = CASE WHEN NOT @LastError = 0
												   THEN 'Error: ' + CAST(@LastError AS NVARCHAR(8))
												   ELSE 'Index Optimized'
											  END ,
								UpdateDate = GETDATE()
						WHERE   IndexName = @IndexName
								AND DatabaseName = @DatabaseName
								AND ( QUOTENAME(LTRIM(RTRIM(SchemaName))) + '.'
									  + QUOTENAME(LTRIM(RTRIM(TableName))) ) = @TableName
								AND ( @PartitionNumber = PartitionNumber
									  OR CAST((REPLACE(@PartitionRebuild, N'ALL', N'-1')) AS INT) = -1
									)
					--End
				End
				ELSE
				Begin
					-- print a message explaining the current index counldn't be found
					print 'Index doesn''t exist!'
			
					-- Log that the index couldn't be found
					Update [IndexMaint].[Statistics] Set   
						IndexStatus = 'Index doesn''t exist!' 
					Where IndexStatisticID = @IndexStatisticID     
				End

				-- Check to see if the process should exit due to time
				IF Not @ExecuteWindowEnd = Null
				Begin
					IF DATEPART(hour, GETDATE()) >= @ExecuteWindowEnd
					Begin
						SET @LogEntry = 'Exiting IndexMaint.usp_SelectiveReIndex because we have passed the Execution Window''s end. Current Hour: ' + CAST(DATEPART(hour, GETDATE()) AS VARCHAR(2)) + ', @ExecuteWindowEnd: ' + CAST(@ExecuteWindowEnd AS VARCHAR(2))
						EXEC Logging.usp_InsertLogEntry @Feature = 'Index Maintenance', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  
						Goto EXECUTION_WINDOW_END
					End
				End
	       END  -- While Loop

			-- End of execution
			EXECUTION_WINDOW_END:
	
			-- delete the temp table if it still exists
			IF OBJECT_ID('tempdb..#IndexCheck') IS NOT NULL 
			Begin 
				DROP TABLE #IndexCheck
			End

			FETCH NEXT FROM Databases_cur INTO @DatabaseName
		END
  
		CLOSE Databases_cur
		DEALLOCATE Databases_cur      

		FETCH NEXT FROM EnabledConfigs INTO @IndexMaintOptionsID
	END
  
	CLOSE EnabledConfigs
	DEALLOCATE EnabledConfigs
		
	SET NOCOUNT OFF
End

GO


