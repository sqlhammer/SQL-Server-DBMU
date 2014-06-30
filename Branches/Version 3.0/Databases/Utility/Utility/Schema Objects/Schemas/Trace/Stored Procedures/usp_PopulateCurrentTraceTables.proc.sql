/*
PROCEDURE:		[Trace].[usp_PopulateCurrentTraceTables]
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure is used to populate the most recent trace table with everything in the trace file and then
				roll-over the trace file for a fresh load. This keeps the current day's trace table up-to-date and it 
				prevents trace files from having to be very large in order to prevent the trace from stopping when the 
				file fills.
PARAMETERS:		@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@TraceOptionsID INT --Default is set to 0 which indicates that all trace configurations should be cycled.
					A setting of any other value will cycle only the trace configuration called.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Trace].[usp_PopulateCurrentTraceTables]
      @debug BIT = 0
    , @TraceOptionsID INT = 0
AS 
	  SET NOCOUNT ON;

      DECLARE @DROPgatherTRCDataSQL VARCHAR(8000)
      DECLARE @cmd VARCHAR(500)
	  DECLARE @TraceName VARCHAR(50)
      DECLARE @InsertSQL VARCHAR(8000)
      DECLARE @gatherTRCDataSQL VARCHAR(8000) 
      DECLARE @CreateTempTRCTableSQL VARCHAR(8000)
      DECLARE @CheckImportFileExistenceCMD VARCHAR(8000) 
      DECLARE @DoesImportFileExist INT  
      DECLARE @RenamePreviousTraceFileCMD VARCHAR(800)
      DECLARE @TableName VARCHAR(256)
      DECLARE @FilePathFileNameFileExt NVARCHAR(200)
	  DECLARE @FilePathFileName VARCHAR(8000)
	  DECLARE @msg VARCHAR(MAX)
	  DECLARE @trace_ID INT
	  DECLARE @Today DATETIME
	  DECLARE @TableNamePrefix VARCHAR(9)
	  DECLARE @DeleteFile_Return INT
	  --Logging
	  DECLARE @LogEntry VARCHAR(8000)
/*------------------------------------------------*\
Validate Trace OptionsID
\*------------------------------------------------*/
IF NOT EXISTS ( SELECT  [OptionID]
                FROM    [Trace].[Options]
                WHERE   [OptionID] = @TraceOptionsID )
    AND @TraceOptionsID <> 0 
    BEGIN
        SET @msg = N'Invalid Trace OptionsID (' + CAST(@TraceOptionsID AS VARCHAR(10)) + ') when executing [Trace].[usp_PopulateCurrentTraceTables].'
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
        RAISERROR (@msg,11,1);
        RETURN;   
    END
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Stop Traces that were marked as disabled
\*------------------------------------------------*/
       IF @TraceOptionsid = 0 
          BEGIN
				--Selects all Trace OptionsIDs where IsEnabled = 0 or if their corrisponding
				--config entry's IsEnabled = 0     
                DECLARE StopCur CURSOR FAST_FORWARD
                FOR
                        SELECT DISTINCT t.[OptionID]
                        FROM    [Trace].[Configs] t
						INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = t.[ConfigID]
                        WHERE   t.[IsEnabled] = 0 OR c.[IsEnabled] = 0

                OPEN StopCur
                FETCH NEXT FROM StopCur INTO @TraceOptionsID

                WHILE @@FETCH_STATUS = 0 
                      BEGIN		
                            SELECT  @FilePathFileName = CASE 	WHEN RIGHT(DL.FILEPATH,1) = '\' THEN DL.FilePath + 'Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
																WHEN RIGHT(DL.FILEPATH,1) <> '\' AND RIGHT(DL.FILEPATH,1) <> '/' THEN DL.FilePath + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
																WHEN RIGHT(DL.FILEPATH,1) = '/' THEN LEFT(DL.FILEPATH,LEN(DL.FILEPATH)-1) + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
														END 
                            FROM    [Trace].[Options] T
							INNER JOIN [Configuration].[DiskLocations] DL ON DL.[DiskLocationID] = T.[DiskLocationID]
                            WHERE   T.[OptionID] = @TraceOptionsID


                            SELECT  @trace_ID = traceid
                            FROM    ::
                                    FN_TRACE_GETINFO(0)
                            WHERE   property = 2
                                    AND value = @FilePathFileName

                            IF @debug = 1 
                               BEGIN 
                                     PRINT '----Stop Trace Section -------------'
                                     PRINT ISNULL(@trace_ID, 0)
                                     PRINT @FilePathFileName
                               END

                            IF @trace_ID > 0 
                               BEGIN 
										EXEC sp_trace_setstatus @trace_ID, 0	--<< stop
										SET @LogEntry = 'Stop trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 0'
										EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

										EXEC sp_trace_setstatus @trace_ID, 2	--<< close
										SET @LogEntry = 'Close trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 2'
										EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                               END 

							 --Delete trace file
							SET @LogEntry = 'Attempting execution of: EXEC dbo.udf_clr_DeleteFile @FilePath = ''' + @FilePathFileName
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  

							EXEC @DeleteFile_Return = dbo.udf_clr_DeleteFile @FilePath = @FilePathFileName

							IF @DeleteFile_Return = 1
							BEGIN
									SET @msg = 'The provided file extention (''' + RIGHT(@FilePathFileName,3) + ''') is not supported by this function.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
									RAISERROR(@msg,16,1)
							END
							IF @DeleteFile_Return = 2
							BEGIN
									SET @msg = 'The trace file didn''t exist. This is an information message only and doesn''t require any additional actions nor is it an indication of failure.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
									RAISERROR(@msg,10,1)
							END
							IF @DeleteFile_Return = 3
							BEGIN
									SET @msg = 'Deletion of ' + @FilePathFileName + ' failed. This error will leave your trace in the ''closed'' state.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
									RAISERROR(@msg,16,1)
							END
							IF @DeleteFile_Return = 0 and @debug = 1
							BEGIN
									SET @msg = 'Deletion of trace file ' + @FilePathFileName + ' was completed successfully.'
									PRINT @msg
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
							END
  
							IF @debug = 1
								PRINT '----Stop Trace Section -------------'        
								
							SET @LogEntry = 'Stopped disabled Trace option ID: ' + CAST(@TraceOptionsID AS VARCHAR(10))
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'                  
									
                            FETCH NEXT FROM StopCur INTO @TraceOptionsID
                      END		
				CLOSE StopCur
				DEALLOCATE StopCur
				SET @TraceOptionsID = 0
          END
       ELSE 
          BEGIN
                SELECT  @FilePathFileName = CASE 	WHEN RIGHT(DL.FILEPATH,1) = '\' THEN DL.FilePath + 'Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
													WHEN RIGHT(DL.FILEPATH,1) <> '\' AND RIGHT(DL.FILEPATH,1) <> '/' THEN DL.FilePath + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
													WHEN RIGHT(DL.FILEPATH,1) = '/' THEN LEFT(DL.FILEPATH,LEN(DL.FILEPATH)-1) + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
											END 
                FROM   [Trace].[Options] T
                INNER JOIN [Trace].[Configs] tc ON tc.[OptionID] = T.[OptionID] 
				INNER JOIN [Configuration].[DiskLocations] DL ON DL.[DiskLocationID] = T.[DiskLocationID]
				INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = Tc.[ConfigID]
                WHERE   T.[OptionID] = @TraceOptionsID
					AND (tc.[IsEnabled] = 0 OR c.[IsEnabled] = 0)


                SELECT  @trace_ID = traceid
                FROM    ::
                        FN_TRACE_GETINFO(0)
                WHERE   property = 2
                        AND value = @FilePathFileName

                IF @debug = 1 
                   BEGIN 
                         PRINT '----Stop Trace Section -------------'
                         PRINT ISNULL(@trace_ID, 0)
                         PRINT @FilePathFileName
                   END

                IF @trace_ID > 0 
                   BEGIN                  
                        EXEC sp_trace_setstatus @trace_ID, 0	--<< stop
						SET @LogEntry = 'Stop trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 0'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

						EXEC sp_trace_setstatus @trace_ID, 2	--<< close
						SET @LogEntry = 'Close trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 2'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                   END 

				--Delete trace file
				SET @LogEntry = 'Attempting execution of: EXEC dbo.udf_clr_DeleteFile @FilePath = ''' + @FilePathFileName
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  

				EXEC @DeleteFile_Return = dbo.udf_clr_DeleteFile @FilePath = @FilePathFileName

				IF @DeleteFile_Return = 1
				BEGIN
						SET @msg = 'The provided file extention (''' + RIGHT(@FilePathFileName,3) + ''') is not supported by this function.'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
						RAISERROR(@msg,16,1)
				END
				IF @DeleteFile_Return = 2
				BEGIN
						SET @msg = 'The trace file didn''t exist. This is an information message only and doesn''t require any additional actions nor is it an indication of failure.'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
						RAISERROR(@msg,10,1)
				END
				IF @DeleteFile_Return = 3
				BEGIN
						SET @msg = 'Deletion of ' + @FilePathFileName + ' failed. This error will leave your trace in the ''closed'' state.'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
						RAISERROR(@msg,16,1)
				END
				IF @DeleteFile_Return = 0 and @debug = 1
				BEGIN
						SET @msg = 'Deletion of trace file ' + @FilePathFileName + ' was completed successfully.'
						PRINT @msg
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
				END
  
				IF @debug = 1
					PRINT '----Stop Trace Section -------------' 
				              
          END                             
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Begin cursoring through traces if it's time and 
the trace is set to enabled in the [Trace].[Options] table
\*------------------------------------------------*/
      IF @TraceOptionsid = 0 
         BEGIN
				--Selects all Trace OptionsIDs
               DECLARE Overallcursor CURSOR FAST_FORWARD
               FOR
                       SELECT DISTINCT	tro.[OptionID]
                       FROM     [Trace].[Configs] trc
					   INNER JOIN [Trace].[Options] tro ON trc.[OptionID] = tro.[OptionID]
					   INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = trc.[ConfigID]
                       WHERE    trc.[IsEnabled] = 1 
								AND c.IsEnabled = 1
         END
      ELSE
         BEGIN
				--Selects only the inputed Trace OptionsID.
				--This was added so that the entire procedure
				--wouldn't have to be in the cursor loop and 
				--outside of it for the individual selection.
				--This way everything follows the same logic
				--but with only 1 row to cursor through.
               DECLARE Overallcursor CURSOR FAST_FORWARD
               FOR
                       SELECT DISTINCT  tro.[OptionID]
                       FROM     [Trace].[Configs] trc
					   INNER JOIN [Trace].[Options] tro ON trc.[OptionID] = tro.[OptionID]
                       INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = trc.[ConfigID]
                       WHERE    trc.[IsEnabled] = 1 
								AND c.IsEnabled = 1
								AND tro.[OptionID] = @TraceOptionsid
	  END

      OPEN Overallcursor
      FETCH NEXT FROM Overallcursor INTO @TraceOptionsID  

      WHILE @@FETCH_STATUS = 0 
            BEGIN	
/*------------------------------------------------*\
\*------------------------------------------------*/
                  IF @debug = 1 
                     BEGIN 
                           PRINT CHAR(13) 
                           PRINT '--------------------------------------------------------------------------'
                           PRINT '    Import Trace Data - Cursor Iteration for Trace OptionsID = ' + CAST(@TraceOptionsID AS VARCHAR)
                           PRINT '--------------------------------------------------------------------------'
                           PRINT CHAR(13) 
                     END 
		         

                    SELECT  @FilePathFileName = CASE 	WHEN RIGHT(DL.FILEPATH,1) = '\' THEN DL.FilePath + 'Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
														WHEN RIGHT(DL.FILEPATH,1) <> '\' AND RIGHT(DL.FILEPATH,1) <> '/' THEN DL.FilePath + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
														WHEN RIGHT(DL.FILEPATH,1) = '/' THEN LEFT(DL.FILEPATH,LEN(DL.FILEPATH)-1) + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
												END 
							, @TraceName =  T.TraceName
					FROM    [Trace].[Options] T
					INNER JOIN [Configuration].[DiskLocations] DL ON DL.[DiskLocationID] = T.[DiskLocationID]
					WHERE   T.[OptionID] = @TraceOptionsID
                    
					SET @TableName = NULL

					SELECT @TableName = [TableName]
					FROM [Trace].[Tables]
					WHERE [OptionID] = @TraceOptionsID
						AND [IsMostRecent] = 1

					IF @TableName IS NULL 
					BEGIN
						SET @Today = GETDATE()

						SET @TableNamePrefix = CAST(DATEPART(yyyy,
															@Today) AS VARCHAR)
							+ CASE WHEN DATALENGTH(CAST(DATEPART(mm,
															@Today) AS VARCHAR)) < 2
									THEN '0'
										+ CAST(DATEPART(mm,
														@Today) AS VARCHAR)
									WHEN DATALENGTH(CAST(DATEPART(mm,
															@Today) AS VARCHAR)) = 2
									THEN CAST(DATEPART(mm, @Today) AS VARCHAR)
								END
							+ CASE WHEN DATALENGTH(CAST(DATEPART(dd,
															@Today) AS VARCHAR)) < 2
									THEN '0'
										+ CAST(DATEPART(dd,
														@Today) AS VARCHAR)
									WHEN DATALENGTH(CAST(DATEPART(dd,
															@Today) AS VARCHAR)) = 2
									THEN CAST(DATEPART(dd, @Today) AS VARCHAR)
								END + '_'

						SET @TableName = @TableNamePrefix + @TraceName

						IF NOT EXISTS (SELECT [TableID] FROM [Trace].[Tables]
										WHERE [OptionID] = @TraceOptionsID
											AND TableName = @TableName)
							BEGIN
								--Set all tables for this Trace OptionsID to 0                                  
								UPDATE [Trace].[Tables] SET IsMostRecent = 0 
								WHERE [OptionID] = @TraceOptionsID 
									AND IsMostRecent = 1
								--Then set the proper IsMostRecent flag on the new table.
								INSERT INTO [Trace].[Tables] ([OptionID], TableName, IsMostRecent)
									VALUES ( @TraceOptionsID, @TableName, 1 )
							END
						ELSE
							BEGIN
								--Set all tables for this Trace OptionsID to 0
								UPDATE [Trace].[Tables] SET IsMostRecent = 0
								WHERE [OptionID] = @TraceOptionsID 
									AND IsMostRecent = 1 
									AND TableName <> @TableName
								--Then set the proper IsMostRecent flag.
								UPDATE [Trace].[Tables] SET IsMostRecent = 1 
								WHERE [OptionID] = @TraceOptionsID 
									AND TableName = @TableName 
									AND IsMostRecent = 0
							END                              
					END

                  IF @debug = 1 
                     BEGIN 
							PRINT 'Does ''' + ISNULL(@FilePathFileName,'NULL') + ''' exist?'

							EXEC Master.dbo.xp_fileexist @FilePathFileName, @DoesImportFileExist OUT 
							
							PRINT 'Does Import File Exist (1 = exists): '
                                 + CAST(@DoesImportFileExist AS CHAR(1))
                     END 
                  ELSE 
                     BEGIN 
							EXEC Master.dbo.xp_fileexist @FilePathFileName, @DoesImportFileExist OUT 

							SELECT @LogEntry = ISNULL(@FilePathFileName,'NULL') + ' does ' + CASE WHEN CAST(@DoesImportFileExist AS CHAR(1)) <> '1' THEN 'not ' END + 'exist.'
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                     END

				  IF NOT EXISTS ( SELECT   1 FROM     dbo.sysobjects WHERE    id = OBJECT_ID(N'[Trace].[' + @TableName + N']') AND OBJECTPROPERTY(id,N'IsUserTable') = 1 ) 
                    BEGIN
                        SET @CreateTempTRCTableSQL = 'CREATE TABLE [Trace].['
                            + @TableName
                            + '] (
								[RowNumber] [int] IDENTITY (1, 1) NOT NULL ,                           
								[TextData] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
								[DatabaseID] [int] NULL ,
								[DatabaseName] AS DB_NAME(DatabaseID),										
								[NTUserName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
								[LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
								[SPID] [int] NULL ,
								[Duration] [bigint] NULL ,
								[StartTime] [datetime] NULL ,
								[EndTime] [datetime] NULL ,
								[Reads] [bigint] NULL ,
								[Writes] [bigint] NULL ,
								[ObjectID] [int] NULL ,
								[EventClass] [int] NOT NULL
								)

								ALTER TABLE [Trace].[' + @TableName
                            + '] ADD 
								CONSTRAINT PK_' + @TableName
                            + '_RowNumber PRIMARY KEY ([RowNumber])
											
								CREATE INDEX [IX_' + @TableName + '_SPID] ON [Trace].[' + @TableName + '] ([SPID]) INCLUDE ([Duration],[StartTime],[EndTime],[Reads],[Writes])'

                        EXEC ( @CreateTempTRCTableSQL  ) 
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @CreateTempTRCTableSQL, @LogMode = 'LIMITED'
                    END

                  IF @DoesImportFileExist = 1 /*1 = exists with xp_fileexists */
                     BEGIN

                           IF @debug = 1 
                              BEGIN 
                                    PRINT 'Table Name: ' + ISNULL(@TableName,'NULL')
                              END 

                           IF NOT EXISTS ( SELECT   1
                                           FROM     dbo.sysobjects
                                           WHERE    id = OBJECT_ID(N'[Trace].[TEMP_TRC_'
                                                              + @TableName
                                                              + N']')
                                                    AND OBJECTPROPERTY(id,
                                                              N'IsUserTable') = 1 ) 
                              BEGIN 
                                    SET @CreateTempTRCTableSQL = 'CREATE TABLE [Trace].[TEMP_TRC_'
                                        + @TableName
                                        + '] (
											[RowNumber] [int] IDENTITY (1, 1) NOT NULL ,                             
											[TextData] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
											[DatabaseID] [int] NULL ,
											[NTUserName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
											[LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
											[SPID] [int] NULL ,
											[Duration] [bigint] NULL ,
											[StartTime] [datetime] NULL ,
											[EndTime] [datetime] NULL ,
											[Reads] [bigint] NULL , 
											[Writes] [bigint] NULL ,
											[ObjectID] [int] NULL ,
											[EventClass] [int] NOT NULL
											) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
											'

                                    EXEC ( @CreateTempTRCTableSQL  ) 
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @CreateTempTRCTableSQL, @LogMode = 'LIMITED'
                              END

                           SET @gatherTRCDataSQL = '    
									declare @FilePathFileNameFileExt nvarchar(200)
									set @FilePathFileNameFileExt  = '''
                               + @FilePathFileName + '''

									insert into [Trace].[TEMP_TRC_' + @TableName
                               + '] 
									( TextData, DatabaseID, NTUserName, LoginName, SPID, Duration, StartTime, EndTime,
									Reads, Writes, ObjectID, EventClass )
									select TextData, DatabaseID, NTUserName, LoginName, SPID, Duration, StartTime, EndTime,
									Reads, Writes, ObjectID, EventClass
									FROM ::fn_trace_gettable ( @FilePathFileNameFileExt, default)
									
									CREATE INDEX [IX_TEMP_TRC_' + @TableName + '_SPID] ON [Trace].[TEMP_TRC_' + @TableName + '] ([SPID]) INCLUDE ([Duration],[StartTime],[EndTime],[Reads],[Writes])'

                           EXEC ( @gatherTRCDataSQL  )
						   EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @gatherTRCDataSQL, @LogMode = 'VERBOSE'

                           SET @InsertSQL = 'WITH    temptable
									  AS ( SELECT   TextData
												  , DatabaseID
												  , NTUserName
												  , LoginName
												  , Spid
												  , Duration
												  , StartTime
												  , EndTime
												  , Reads
												  , Writes
												  , ObjectID
												  , EventClass
										   FROM     [Trace].[TEMP_TRC_' + @TableName
                               + ']
										   WHERE TextData IS NOT NULL
										 )
								 MERGE [Trace].[' + @TableName
                               + '] AS currenttable
									USING temptable
									ON currenttable.Spid = temptable.Spid
										AND currenttable.Duration = temptable.Duration
										AND currenttable.StartTime = temptable.StartTime
										AND currenttable.EndTime = temptable.EndTime
										AND currenttable.Reads = temptable.Reads
										AND currenttable.Writes = temptable.Writes
									WHEN NOT MATCHED 
										THEN
											 INSERT (
													  TextData
													, DatabaseID
													, NTUserName
													, LoginName
													, Spid
													, Duration
													, StartTime
													, EndTime
													, Reads
													, Writes
													, ObjectID
													, EventClass
													)
										   VALUES   ( temptable.TextData
													, temptable.DatabaseID
													, temptable.NTUserName
													, temptable.LoginName
													, temptable.Spid
													, temptable.Duration
													, temptable.StartTime
													, temptable.EndTime
													, temptable.Reads
													, temptable.Writes
													, temptable.ObjectID
													, temptable.EventClass
											);'
                           EXEC ( @InsertSQL )
						   EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @InsertSQL, @LogMode = 'VERBOSE'
						   
                           SET @DROPgatherTRCDataSQL = '    drop table [Trace].[TEMP_TRC_'
                               + @TableName + ']  '

                           EXEC   (   @DROPgatherTRCDataSQL )
						   EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @DROPgatherTRCDataSQL, @LogMode = 'VERBOSE'
/*------------------------------------------------*\
Stop the individual trace
\*------------------------------------------------*/

							IF @debug = 1
							BEGIN
								PRINT 'Merge statement complete.'
								PRINT 'Begin cycling the trace file.'
							END
  
							SELECT  @FilePathFileName = CASE 	WHEN RIGHT(DL.FILEPATH,1) = '\' THEN DL.FilePath + 'Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
																WHEN RIGHT(DL.FILEPATH,1) <> '\' AND RIGHT(DL.FILEPATH,1) <> '/' THEN DL.FilePath + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
																WHEN RIGHT(DL.FILEPATH,1) = '/' THEN LEFT(DL.FILEPATH,LEN(DL.FILEPATH)-1) + '\Utility_Trace_' + T.TraceName + '.' + DL.FileExtension
														END 
                            FROM   [Trace].[Options] T
							INNER JOIN [Configuration].[DiskLocations] DL ON DL.[DiskLocationID] = T.[DiskLocationID]
                            WHERE   T.[OptionID] = @TraceOptionsID
														
                            SELECT  @trace_ID = traceid
                            FROM    ::
                                    FN_TRACE_GETINFO(0)
                            WHERE   property = 2
                                    AND value = @FilePathFileName

                            IF @debug = 1 
                               BEGIN 
                                     PRINT '----Stop Trace Section -------------'
                                     PRINT ISNULL(@trace_ID, 0)
                                     PRINT @FilePathFileName
                                     PRINT '----Stop Trace Section -------------'
                               END

                            IF @trace_ID > 0 
                               BEGIN 
										EXEC sp_trace_setstatus @trace_ID, 0	--<< stop
										SET @LogEntry = 'Stop trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 0'
										EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

										EXEC sp_trace_setstatus @trace_ID, 2	--<< close
										SET @LogEntry = 'Close trace using: EXEC sp_trace_setstatus ' + CAST(@trace_ID AS VARCHAR(10)) + ', 2'
										EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                               END 

							 --Delete trace file
							SET @LogEntry = 'Attempting execution of: EXEC dbo.udf_clr_DeleteFile @FilePath = ''' + @FilePathFileName
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'  

							EXEC @DeleteFile_Return = dbo.udf_clr_DeleteFile @FilePath = @FilePathFileName

							IF @DeleteFile_Return = 1
							BEGIN
									SET @msg = 'The provided file extention (''' + RIGHT(@FilePathFileName,3) + ''') is not supported by this function.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
									RAISERROR(@msg,16,1)
							END
							IF @DeleteFile_Return = 2
							BEGIN
									SET @msg = 'The trace file didn''t exist. This is an information message only and doesn''t require any additional actions nor is it an indication of failure.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
									RAISERROR(@msg,10,1)
							END
							IF @DeleteFile_Return = 3
							BEGIN
									SET @msg = 'Deletion of ' + @FilePathFileName + ' failed. This error will leave your trace in the ''closed'' state.'
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
									RAISERROR(@msg,16,1)
							END
							IF @DeleteFile_Return = 0 and @debug = 1
							BEGIN
									SET @msg = 'Deletion of trace file ' + @FilePathFileName + ' was completed successfully.'
									PRINT @msg
									EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'VERBOSE'
							END 
                     END
/*------------------------------------------------*\
Start New Trace in accordance with [Trace].[Options]
\*------------------------------------------------*/
							IF @debug = 1 
								BEGIN 
									PRINT CHAR(13) 
									PRINT '--------------------------------------------------------------------------'
									PRINT '    Start New Trace'
									PRINT 'Starting Trace OptionsID '
											+ CAST(@TraceOptionsID AS VARCHAR(10))
									PRINT '--------------------------------------------------------------------------'
									PRINT CHAR(13) 
								END 

							DECLARE @StartTraceSQL VARCHAR(100)

							SET @StartTraceSQL = 'exec [Trace].[usp_StartNewTrace] @TraceOptionsID='
								+ CAST(@TraceOptionsID AS VARCHAR(10))
							EXEC ( @StartTraceSQL )
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @StartTraceSQL, @LogMode = 'VERBOSE'
/*------------------------------------------------*\
\*------------------------------------------------*/
							SET @LogEntry = 'Trace file and table rolled over for Trace option ID: ' + CAST(@TraceOptionsID AS VARCHAR(10))
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'
/*------------------------------------------------*\
		Finalize the overall cursor
\*------------------------------------------------*/      
                  FETCH NEXT FROM Overallcursor INTO @TraceOptionsID
            END
      CLOSE Overallcursor
      DEALLOCATE Overallcursor
/*------------------------------------------------*\
\*------------------------------------------------*/    
SET NOCOUNT OFF
GO