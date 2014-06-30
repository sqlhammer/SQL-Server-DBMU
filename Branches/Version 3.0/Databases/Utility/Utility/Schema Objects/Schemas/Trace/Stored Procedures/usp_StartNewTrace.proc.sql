/*
PROCEDURE:		[Trace].usp_StartNewTrace
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure is used to configure and start a new trace based on configuration values derived
				from the Utility database table schema.
PARAMETERS:		@TraceOptionsID INT --Used to identify which trace options set to pull the configuration from.
*/
/*
CHANGE HISTORY:



*/

CREATE PROCEDURE [Trace].[usp_StartNewTrace]
       @TraceOptionsID INT
AS 
		--Prevent counts to improve performance
	   SET NOCOUNT ON;

	   --Declare variables
       DECLARE @rc INT
       DECLARE @TraceID INT
       DECLARE @maxfilesize BIGINT
       DECLARE @TraceName VARCHAR(50)    
       DECLARE @sql NVARCHAR(256)
       DECLARE @file_name NVARCHAR(200)
       DECLARE @Query_Runtime BIGINT
	   DECLARE @Reads BIGINT
	   DECLARE @Writes BIGINT
       DECLARE @DatabaseNames NVARCHAR(1000)
       DECLARE @Database TABLE ( NAME VARCHAR(128) )
	   --Logging
		DECLARE @LogEntry VARCHAR(8000)

	   --Retrieve the file name from the [Trace].[Options] table
       SELECT   @file_name =	CASE 	WHEN RIGHT(DL.FILEPATH,1) = '\' THEN DL.FilePath + 'Utility_Trace_' + T.TraceName
										WHEN RIGHT(DL.FILEPATH,1) <> '\' AND RIGHT(DL.FILEPATH,1) <> '/' THEN DL.FilePath + '\Utility_Trace_' + T.TraceName
										WHEN RIGHT(DL.FILEPATH,1) = '/' THEN LEFT(DL.FILEPATH,LEN(DL.FILEPATH)-1) + '\Utility_Trace_' + T.TraceName
								END
       FROM     [Trace].[Options] T
                INNER JOIN [Configuration].[DiskLocations] DL ON DL.[DiskLocationID] = T.[DiskLocationID]
       WHERE    T.[OptionID] = @TraceOptionsID
				 
       PRINT 'Trace File: ' + @file_name

	   --Populate Trace name from the [Trace].[Options] table
       SELECT   @TraceName = traceName
       FROM     [Trace].[Options]
       WHERE    [OptionID] = @TraceOptionsID

       PRINT 'Trace Name: ' + @TraceName  

	   --Populate the max files size from the [Trace].[Options] table
       SELECT   @maxfilesize = MaxFileSize
       FROM     [Trace].[Options]
       WHERE    [OptionID] = @TraceOptionsID

       PRINT 'Max File Size (MB): ' + CAST(@maxfilesize AS VARCHAR(250))    

	   --Retrieve databases from the [Trace].[Options] table  
       INSERT   INTO @Database
                ( NAME
                )
                SELECT  Rdb.DatabaseName
                FROM    [Configuration].RegisteredDatabases Rdb
                        INNER JOIN [Trace].[Databases] Tdb ON Tdb.DatabaseID = Rdb.DatabaseID
                        INNER JOIN [Trace].[Options] Topt ON Topt.[OptionID] = Tdb.[OptionID]
                WHERE   Topt.[OptionID] = @TraceOptionsID
		
	   PRINT 'Database Name(s):'
	   DECLARE DBnamePrint CURSOR FAST_FORWARD FOR
		SELECT  [NAME] FROM @Database
	   OPEN DBnamePrint
	   FETCH NEXT FROM DBnamePrint INTO @sql
	   WHILE @@FETCH_STATUS = 0
	   BEGIN
			PRINT '** ' + @sql
			FETCH NEXT FROM DBnamePrint INTO @sql
	   END
	   CLOSE DBnamePrint
	   DEALLOCATE DBnamePrint
	   SET @sql = NULL

	   --Retrieve Filter options from the [Trace].[Options] table 
       SELECT   @Query_Runtime = QueryRunTime
       FROM     [Trace].[Options]
       WHERE    [OptionID] = @TraceOptionsID

       PRINT 'Query Run Time (microseconds): ' + ISNULL(CAST(@Query_Runtime AS VARCHAR(20)),'NULL')

       SELECT   @Reads = Reads
       FROM     [Trace].[Options]
       WHERE    [OptionID] = @TraceOptionsID

       PRINT 'Reads: ' + ISNULL(CAST(@Reads AS VARCHAR(20)),'NULL')

       SELECT   @Writes = Writes
       FROM     [Trace].[Options]
       WHERE    [OptionID] = @TraceOptionsID

       PRINT 'Writes: ' + ISNULL(CAST(@Writes AS VARCHAR(20)),'NULL')

	   --Create the trace
		SET @LogEntry = 'Starting new Trace from Trace OptionID: ' + CAST(@TraceOptionsID AS VARCHAR(10))
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'

       EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, @file_name, @maxfilesize, NULL
  
		-- Check for errors and if none continue
       IF ( @rc != 0 ) 
	   BEGIN
			SET @LogEntry = 'Error starting new Trace using: EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, ' + @file_name + ', ' + CAST(@maxfilesize AS VARCHAR(10)) + ', NULL'
			EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'LIMITED'   
            RAISERROR ('Error with the sp_trace_create', 16,1)
	   END
       ELSE 
          BEGIN
				SET @LogEntry = 'Started new Trace using: EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, ' + @file_name + ', ' + CAST(@maxfilesize AS VARCHAR(10)) + ', NULL'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'   

				-- set the events.
                DECLARE @on BIT
                SET @on = 1

				 --Event: RPC: COmpleted
                EXEC sp_trace_setevent @TraceID, 10, 1, @on -- Column: TextData
                EXEC sp_trace_setevent @TraceID, 10, 3, @on -- Column: DatabaseID
                EXEC sp_trace_setevent @TraceID, 10, 6, @on -- Column: NTUserName
                EXEC sp_trace_setevent @TraceID, 10, 11, @on -- Column: SQLSecurityLoginName
                EXEC sp_trace_setevent @TraceID, 10, 12, @on -- Column: SPID
                EXEC sp_trace_setevent @TraceID, 10, 13, @on -- Column: Duration
                EXEC sp_trace_setevent @TraceID, 10, 14, @on -- Column: StartTime
                EXEC sp_trace_setevent @TraceID, 10, 15, @on -- Column: EndTime
                EXEC sp_trace_setevent @TraceID, 10, 16, @on -- Column: Reads
                EXEC sp_trace_setevent @TraceID, 10, 17, @on -- Column: Writes
                EXEC sp_trace_setevent @TraceID, 10, 22, @on -- Column: ObjectID
				 --Event: SQL: BatchCompleted
                EXEC sp_trace_setevent @TraceID, 12, 1, @on -- Column: TextData
                EXEC sp_trace_setevent @TraceID, 12, 3, @on -- Column: DatabaseID
                EXEC sp_trace_setevent @TraceID, 12, 6, @on -- Column: NTUserName
                EXEC sp_trace_setevent @TraceID, 12, 11, @on -- Column: SQLSecurityLoginName
                EXEC sp_trace_setevent @TraceID, 12, 12, @on -- Column: SPID
                EXEC sp_trace_setevent @TraceID, 12, 13, @on -- Column: Duration
                EXEC sp_trace_setevent @TraceID, 12, 14, @on -- Column: StartTime
                EXEC sp_trace_setevent @TraceID, 12, 15, @on -- Column: EndTime
                EXEC sp_trace_setevent @TraceID, 12, 16, @on -- Column: Reads
                EXEC sp_trace_setevent @TraceID, 12, 17, @on -- Column: Writes
                EXEC sp_trace_setevent @TraceID, 12, 22, @on -- Column: ObjectID
				 --Event: SQL: StmtCompleted
                EXEC sp_trace_setevent @TraceID, 41, 1, @on -- Column: TextData
                EXEC sp_trace_setevent @TraceID, 41, 3, @on -- Column: DatabaseID
                EXEC sp_trace_setevent @TraceID, 41, 6, @on -- Column: NTUserName
                EXEC sp_trace_setevent @TraceID, 41, 11, @on -- Column: SQLSecurityLoginName
                EXEC sp_trace_setevent @TraceID, 41, 12, @on -- Column: SPID
                EXEC sp_trace_setevent @TraceID, 41, 13, @on -- Column: Duration
                EXEC sp_trace_setevent @TraceID, 41, 14, @on -- Column: StartTime
                EXEC sp_trace_setevent @TraceID, 41, 15, @on -- Column: EndTime
                EXEC sp_trace_setevent @TraceID, 41, 16, @on -- Column: Reads
                EXEC sp_trace_setevent @TraceID, 41, 17, @on -- Column: Writes
                EXEC sp_trace_setevent @TraceID, 41, 22, @on -- Column: ObjectID
				 --Event: SP: StmtCompleted
                EXEC sp_trace_setevent @TraceID, 45, 1, @on -- Column: TextData
                EXEC sp_trace_setevent @TraceID, 45, 3, @on -- Column: DatabaseID
                EXEC sp_trace_setevent @TraceID, 45, 6, @on -- Column: NTUserName
                EXEC sp_trace_setevent @TraceID, 45, 11, @on -- Column: SQLSecurityLoginName
                EXEC sp_trace_setevent @TraceID, 45, 12, @on -- Column: SPID
                EXEC sp_trace_setevent @TraceID, 45, 13, @on -- Column: Duration
                EXEC sp_trace_setevent @TraceID, 45, 14, @on -- Column: StartTime
                EXEC sp_trace_setevent @TraceID, 45, 15, @on -- Column: EndTime
                EXEC sp_trace_setevent @TraceID, 45, 16, @on -- Column: Reads
                EXEC sp_trace_setevent @TraceID, 45, 17, @on -- Column: Writes
                EXEC sp_trace_setevent @TraceID, 45, 22, @on -- Column: ObjectID


				-- Set the Filters
                DECLARE @intfilter INT
                DECLARE @bigintfilter BIGINT
        
				--WHERE TextData NOT EQUAL
                EXEC sp_trace_setfilter @TraceID, 1, 0, 7, N'WAITFOR DELAY ''00:00:%'
				--WHERE TextData NOT EQUAL
                EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler'
				
				--AND WHERE Duration IS GREATER THAN
				IF @Query_Runtime IS NOT NULL
				BEGIN              
					EXEC sp_trace_setfilter @TraceID, 13, 0, 4, @Query_Runtime
					SET @LogEntry = 'Set query runtime trace filter using: EXEC sp_trace_setfilter ' + CAST(@TraceID AS VARCHAR(10)) + ', 13, 0, 4, ' + CAST(@Query_Runtime AS VARCHAR(20))
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE' 
				END
				--AND WHERE Reads IS GREATER THAN
				IF @Reads IS NOT NULL
				BEGIN              
					EXEC sp_trace_setfilter @TraceID, 16, 0, 4, @Reads
					SET @LogEntry = 'Set reads trace filter using: EXEC sp_trace_setfilter ' + CAST(@TraceID AS VARCHAR(10)) + ', 13, 0, 4, ' + CAST(@Reads AS VARCHAR(20))
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'                   
				END
				--AND WHERE Writes IS GREATER THAN
				IF @Writes IS NOT NULL
				BEGIN              
					EXEC sp_trace_setfilter @TraceID, 17, 0, 4, @Writes
					SET @LogEntry = 'Set writes trace filter using: EXEC sp_trace_setfilter ' + CAST(@TraceID AS VARCHAR(10)) + ', 13, 0, 4, ' + CAST(@Writes AS VARCHAR(20))
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE' 
				END
               
				--loop through database names to apply filters
                DECLARE TraceDB_Cursor CURSOR FAST_FORWARD
                FOR
                        SELECT  NAME
                        FROM    @Database
				
                OPEN TraceDB_Cursor
                FETCH NEXT FROM TraceDB_Cursor INTO @sql
								
				--AND WHERE DatabaseName EQUALS
                EXEC sp_trace_setfilter @TraceID, 35, 0, 0, @sql
				SET @LogEntry = 'Set database trace filter using: EXEC sp_trace_setfilter ' + CAST(@TraceID AS VARCHAR(10)) + ', 35, 0, 0, ' + @sql
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE' 

                FETCH NEXT FROM TraceDB_Cursor INTO @sql
				
                WHILE ( SELECT  fetch_status FROM    sys.dm_exec_cursors(@@SPID) WHERE   name = 'TraceDB_Cursor' ) = 0 
                      BEGIN		
							--OR WHERE DatabaseName EQUALS
                            EXEC sp_trace_setfilter @TraceID, 35, 1, 0, @sql
							SET @LogEntry = 'Set database trace filter using: EXEC sp_trace_setfilter ' + CAST(@TraceID AS VARCHAR(10)) + ', 35, 1, 0, ' + @sql
							EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE' 

                            FETCH NEXT FROM TraceDB_Cursor INTO @sql
                      END

				-- Set the trace status to start
                EXEC sp_trace_setstatus @TraceID, 1

				SET @LogEntry = 'Set Trace status to started using: EXEC sp_trace_setstatus ' + CAST(@TraceID AS VARCHAR(10)) + ', 1'
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE' 
  
				--Display trace ID for future references
                PRINT 'Trace ID = ' + CAST(@TraceID AS VARCHAR(10))
          END

		SET NOCOUNT OFF          