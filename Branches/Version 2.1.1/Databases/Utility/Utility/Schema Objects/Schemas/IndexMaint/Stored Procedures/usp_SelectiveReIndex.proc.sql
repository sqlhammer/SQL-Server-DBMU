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

*/

CREATE PROCEDURE  [IndexMaint].[usp_SelectiveReindex] 
--(
--	@Debug bit = 0
--) 
As
Begin
	SET NOCOUNT ON

	DECLARE @DatabaseID			int
	DECLARE @ExecStatement		varchar(4000)
	DECLARE @ExecMessage		varchar(4000)
	DECLARE @IndexStatisticID	int
	DECLARE @ObjectID			int
	DECLARE @TableName			sysname
	DECLARE @IndexID			int
	DECLARE @IndexName			sysname
	DECLARE @FragLimit			tinyint
	DECLARE @FillFactor			tinyint
	DECLARE @Fragmentation		tinyint
	DECLARE @PageSpaceLimit		tinyint
	DECLARE @PageSpaceUsed		tinyint
	DECLARE @LastError			int
	DECLARE @ExecuteWindowEnd	tinyint		-- End hour, for when to stop processing
	DECLARE @MaxDefrag			tinyint 	-- Maximum fragmentation before defraging will become rebuild
	DECLARE	@DatabaseName		sysname
	DECLARE @IndexMaintOptionsID INT
	DECLARE @IndexStatus		VARCHAR(50)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

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
		FROM [IndexMaint].[Options]
		WHERE [OptionID] = @IndexMaintOptionsID

		DECLARE Databases_cur CURSOR FAST_FORWARD
		FOR
		SELECT Rdb.DatabaseName
		FROM [Configuration].RegisteredDatabases Rdb
		INNER JOIN [IndexMaint].[Databases] Idb ON Idb.DatabaseID = Rdb.DatabaseID
		INNER JOIN sys.databases sysDBs ON Rdb.DatabaseID = sysDBs.database_id
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
						-- Determine if the index should be defragmented or reindexed and always update statistics for indexes which were altered.
						IF (@Fragmentation > @MaxDefrag) OR (((@PageSpaceUsed  / (CASE @FillFactor WHEN 0 THEN 100 ELSE @FillFactor END) * 100) > 100))
							Or EXISTS(Select 1 From #IndexCheck Where [type] = 'Index - No Page Lock')
						Begin
							SET @ExecStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' REBUILD;';
							SET @ExecStatement = @ExecStatement + ' UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;';
							SET @ExecMessage = '-- Executing ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' REBUILD;'
							SET @ExecMessage = @ExecMessage + ' -- Executing UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;';
						End
						ELSE
						Begin
							SET @ExecStatement = 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' REORGANIZE;';
							SET @ExecStatement = @ExecStatement + ' UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) + ' WITH FULLSCAN;';
							SET @ExecMessage = '-- Executing ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' REORGANIZE;'
							SET @ExecMessage = @ExecMessage + ' -- Executing UPDATE STATISTICS ' + QUOTENAME(@DatabaseName) + '.' + @TableName + ' ' + QUOTENAME(@IndexName) +  ' WITH FULLSCAN;';
						End
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
						EXEC (@ExecStatement)
						Set @LastError = @@ERROR				
				
						-- Update the Index Statistics table with the new status.
						-- -- Update all rows for the given index so that maintenance isn't performed excessively.
						Update [IndexMaint].[Statistics] Set   
							IndexStatus = CASE When Not @LastError = 0 Then 'Error: ' + CAST(@LastError AS NVARCHAR(8))
											Else 'Index Optimized' End
							, UpdateDate = GETDATE() 
						WHERE IndexName = @IndexName
							AND DatabaseName = @DatabaseName
							AND (QUOTENAME(LTRIM(RTRIM(SchemaName))) + '.' + QUOTENAME(LTRIM(RTRIM(TableName)))) = @TableName
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

