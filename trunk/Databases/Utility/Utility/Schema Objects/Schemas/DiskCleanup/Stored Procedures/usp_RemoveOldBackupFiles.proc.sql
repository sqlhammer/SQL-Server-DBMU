/*
PROCEDURE:		[DiskCleanup].usp_RemoveOldBackupFiles
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure will invoke either the xp_delete_file or udf_clr_deletefile functions to purge
				old backup files from specified directories. The parameteres for deletion include either 
				by date or by number of files for that database which reside in the selected directory.
PARAMETERS:		@DiskCleanupOptionsID INT --Default is set to 0 which indicates to loop through all enabled
					configurations. If a specific value is inputtted then only that configuration will be checked.
				@debug BIT --Setting this parameter to 1 will enable debugging print statements.
*/
/*
CHANGE HISTORY:


*/
CREATE PROCEDURE [DiskCleanup].[usp_RemoveOldBackupFiles]
(
	@DiskCleanupOptionsID INT = 0,
	@debug BIT = 0
)
AS
	SET NOCOUNT ON;

	DECLARE @Path nvarchar(1000) 
	DECLARE @PurgeValue INT
	DECLARE @PurgeTypeDesc VARCHAR(50)
	DECLARE @Extension char(3)
	DECLARE @DBName VARCHAR(128)
	DECLARE @DeleteDate NVARCHAR(50)
	DECLARE @DeleteDateTime DATETIME
	DECLARE @DeleteFile_Return INT
	DECLARE @FilePathFileName VARCHAR(2000)
	DECLARE @FileName VARCHAR(1000)
	DECLARE @msg VARCHAR(250)
	DECLARE @FileCount BIGINT
	DECLARE @FilePath VARCHAR(8000)
	--Logging
	DECLARE @LogEntry VARCHAR(8000)

	--Validate inputted DiskCleanup OptionsID
	IF NOT EXISTS (SELECT  [OptionID]
					FROM    [DiskCleanup].[Options]
					WHERE   [OptionID] = @DiskCleanupOptionsID) AND @DiskCleanupOptionsID <> 0
			 BEGIN
							SET @msg = N'Invalid DiskCleanup OptionsID.'
							RAISERROR (@msg,11,1);
							RETURN ;   
			END
  
	IF @debug = 1
	BEGIN
		PRINT 'Inputted (or default) DiskCleanup OptionsID is valid. Moving on...'
	END      

	IF @DiskCleanupOptionsID = 0
	Begin
		DECLARE diskcleanup_cur CURSOR FAST_FORWARD
		FOR
		SELECT dl.FILEPATH, dl.FileExtension, dco.PurgeValue, Pt.PurgeTypeDesc, dco.[OptionID]
		FROM [DiskCleanup].[Options] dco
		INNER JOIN [Lookup].[PurgeTypes] Pt ON Pt.PurgeTypeID = dco.PurgeTypeID
		INNER JOIN [Configuration].DiskLocations dl ON dl.DiskLocationID = dco.DiskLocationID
		INNER JOIN [DiskCleanup].[Configs] dcc ON dcc.[OptionID] = dco.[OptionID]
		INNER JOIN [Configuration].[Configs] c ON dcc.[ConfigID] = c.[ConfigID]
		WHERE dcc.[IsEnabled] = 1 AND c.[IsEnabled] = 1
	END
	ELSE
	BEGIN
		DECLARE diskcleanup_cur CURSOR FAST_FORWARD
		FOR
		SELECT  dl.FILEPATH, dl.FileExtension, dco.PurgeValue, Pt.PurgeTypeDesc, dco.[OptionID]
		FROM [DiskCleanup].[Options] dco
		INNER JOIN [Lookup].[PurgeTypes] Pt ON Pt.PurgeTypeID = dco.PurgeTypeID
		INNER JOIN [Configuration].DiskLocations dl ON dl.DiskLocationID = dco.DiskLocationID
		INNER JOIN [DiskCleanup].[Configs] dcc ON dcc.[OptionID] = dco.[OptionID]
		INNER JOIN [Configuration].[Configs] c ON dcc.[ConfigID] = c.[ConfigID]
		WHERE dcc.[IsEnabled] = 1 AND c.[IsEnabled] = 1 AND dco.[OptionID] = @DiskCleanupOptionsID
	END

	OPEN diskcleanup_cur

	FETCH NEXT FROM diskcleanup_cur INTO @Path, @Extension, @PurgeValue, @PurgeTypeDesc, @DiskCleanupOptionsID

	WHILE ( SELECT  fetch_status FROM    sys.dm_exec_cursors(@@SPID) WHERE   name = 'diskcleanup_cur' ) = 0 
	BEGIN

		IF @debug = 1
		BEGIN
			PRINT '-------------------------------------------------------------------------'
			PRINT 'Cursor Iteration for @DiskCleanupOptionsID: ' + CAST(@DiskCleanupOptionsID AS VARCHAR)
			PRINT '-------------------------------------------------------------------------'
		END  

		DECLARE DB_cursor CURSOR FAST_FORWARD
		FOR  
		SELECT Rdb.DatabaseName
		FROM [DiskCleanup].[Options] dco
		INNER JOIN [DiskCleanup].[Databases] dcDB ON dco.[OptionID] = dcDB.[OptionID]
		INNER JOIN [Configuration].RegisteredDatabases Rdb ON Rdb.DatabaseID = dcDB.DatabaseID
		WHERE dco.[OptionID] = @DiskCleanupOptionsID

		OPEN DB_cursor

		FETCH NEXT FROM DB_cursor INTO @DBName

		WHILE ( SELECT  fetch_status FROM    sys.dm_exec_cursors(@@SPID) WHERE   name = 'DB_cursor' ) = 0 
		BEGIN
  
			IF @debug = 1
			BEGIN
				PRINT '-------------------------------------------------------------------------'
				PRINT 'Cursor Iteration for @DBName: ' + CAST(@DBName AS VARCHAR)
				PRINT '-------------------------------------------------------------------------'
			END   

			SET @LogEntry = 'Beginning purge of files for Disk Cleanup OptionID ' + CAST(@DiskCleanupOptionsID AS VARCHAR(10)) + '; database name = ' + @DBName
			EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
    
			--Set path of database folder
			IF RIGHT(@Path,1) <> '\'
				SET @Path = @Path + '\'

			SET @FilePath = @Path + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@DBName,'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','')

			IF UPPER(@PurgeTypeDesc) = 'PURGE BY DAYS'
			BEGIN
			
				IF @debug = 1
				BEGIN
					PRINT 'Purge Type ''PURGE BY DAYS'' selected.'
				END  
		      
				IF @PurgeValue < 0
					SET @PurgeValue = 0 - @PurgeValue

				SET @PurgeValue = 0 - @PurgeValue

				SET @DeleteDateTime = DATEADD(dd, @PurgeValue, GETDATE())
				SET @DeleteDate = ( SELECT  REPLACE(CONVERT(NVARCHAR, @DeleteDateTime, 111),
													'/', '-') + 'T'
											+ CONVERT(NVARCHAR, @DeleteDateTime, 108)
								  )

				IF @debug = 1
				BEGIN
					PRINT '@DeleteDate = ' + CAST(@DeleteDate AS varchar)
					PRINT '@Extension = ' + @Extension
					PRINT '@Path = ' + @FilePath
				END 

				SET @LogEntry = 'Attempting execution of: EXECUTE master.dbo.xp_delete_file 0, ''' + @FilePath + ''',  + ''' + @Extension + ''', ''' + CAST(@DeleteDate AS VARCHAR) + ''', 1'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				EXECUTE master.dbo.xp_delete_file 0, @FilePath, @Extension, @DeleteDate, 1

				SET @LogEntry = 'Execution success for: EXECUTE master.dbo.xp_delete_file 0, ''' + @FilePath + ''',  + ''' + @Extension + ''', ''' + CAST(@DeleteDate AS VARCHAR) + ''', 1'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
			END  

			IF UPPER(@PurgeTypeDesc) = 'PURGE BY NUMBER OF FILES'
			BEGIN
			
				IF @debug = 1
				BEGIN
					PRINT 'Purge Type ''PURGE BY NUMBER OF FILES'' selected.'
					PRINT '@Extension = ' + @Extension
					PRINT '@Path = ' + @FilePath
				END  
		           
				--Populate the file list
				IF OBJECT_ID('tempdb..#FileList') IS NOT NULL
					DROP TABLE #FileList      

				CREATE TABLE #FileList
				(
					[FileName] nvarchar(500)
					, [FileSize_Bytes] bigint
					, [CreationTime] datetime
					, [WasAttempted] BIT DEFAULT 0
				)

				--Load files by extention
				INSERT INTO [#FileList] ( [FileName], [FileSize_Bytes],	[CreationTime] )
				SELECT [FileName], [FileSize_Bytes], [CreationTime]
				FROM dbo.[udf_clr_GetFileList](@FilePath,'%' + @Extension)

				IF @debug = 1
				BEGIN
					SELECT * FROM #FileList

					PRINT '#FileList table loaded. See results of select statement for listing.'
				END          

				--Verify it should loop at least once
				SELECT @FileCount = COUNT([FileName]) FROM #FileList WHERE [WasAttempted] = 0
				IF @FileCount <= @PurgeValue
				BEGIN
					UPDATE [#FileList] SET [WasAttempted] = 1
					IF @debug = 1
					BEGIN
						PRINT '@FileCount was less than the @PurgeValue so there will be no iteration of the deletion loop.'
					END
				END

				WHILE EXISTS (SELECT [FileName] FROM #FileList WHERE [WasAttempted] = 0)
				BEGIN
				
					--Get next file
					SELECT TOP 1 @FileName = [FileName]
					FROM [#FileList]
					WHERE [WasAttempted] = 0
					ORDER BY [CreationTime] ASC

					--Set path format
					IF RIGHT(@FilePath,1) <> '\'
						SET @FilePath = @FilePath + '\'

					--Construct full path
					SET @FilePathFileName = @FilePath + @FileName

					IF @debug = 1
					BEGIN
						PRINT 'Full File Path to Delete: ' + @FilePathFileName
					END              

					--Delete file
					SET @LogEntry = 'Attempting execution of: EXEC dbo.udf_clr_DeleteFile @FilePath = ''' + @FilePathFileName
					EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  
					                
					EXEC @DeleteFile_Return = dbo.udf_clr_DeleteFile @Path = @FilePathFileName
								
					IF @DeleteFile_Return = 1
					BEGIN
							SET @msg = 'The provided file extention (''' + RIGHT(@FileName,3) + ''') is not supported by this function.'
							EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @msg, @LogMode = 'LIMITED'  
							RAISERROR(@msg,16,1)
					END
					IF @DeleteFile_Return = 2  and @debug = 1
					BEGIN
							SET @msg = 'Attempted to delete selected file (''' + @FileName + ''') but it didn''t exist. Verify access to the target directory for the SQL Service Domain Account.'
							EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @msg, @LogMode = 'VERBOSE'  
							RAISERROR(@msg,10,1)
					END
					IF @DeleteFile_Return = 3  and @debug = 1
					BEGIN
							SET @msg = 'Deletion of ' + @FileName  + ' failed.'
							EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @msg, @LogMode = 'VERBOSE'  
							RAISERROR(@msg,10,1)
					END
					IF @DeleteFile_Return = 0 and @debug = 1
					BEGIN
							PRINT 'Deletion of file ' + @FileName + ' was completed successfully.'

							SET @LogEntry = 'Execution success for: EXEC dbo.udf_clr_DeleteFile @FilePath = ''' + @FilePathFileName
							EXEC Logging.usp_InsertLogEntry @Feature = 'Disk Cleanup', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
					END

					--UPDATE #FileList to continue our loop
					UPDATE [#FileList] SET [WasAttempted] = 1 WHERE [FileName] = @FileName

					--exit loop if we have hit our Purge Value
					SELECT @FileCount = COUNT([FileName]) FROM #FileList WHERE [WasAttempted] = 0
					IF @FileCount <= @PurgeValue
						UPDATE [#FileList] SET [WasAttempted] = 1

				END

				--Clean up after ourselves
				DROP TABLE #FileList
			END  

			FETCH NEXT FROM DB_cursor INTO @DBName

		END
  
		CLOSE DB_cursor
		DEALLOCATE DB_cursor  

		FETCH NEXT FROM diskcleanup_cur INTO @Path, @Extension, @PurgeValue, @PurgeTypeDesc, @DiskCleanupOptionsID

	END

	CLOSE diskcleanup_cur
	DEALLOCATE diskcleanup_cur

	SET NOCOUNT OFF