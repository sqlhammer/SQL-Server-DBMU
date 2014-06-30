/*
PROCEDURE:		Trace.usp_CycleTraceTables
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This procedure is used to cycle the trace tables at night so they are archived by date.
PARAMETERS:		@TraceOptionsID INT --Default is set to 0 which indicates that all trace configurations should be cycled.
					A setting of any other value will cycle only the trace configuration called.
				@debug BIT --Setting this parameter to 1 will enable debugging print statements.
				@midnightTEST BIT --Default is 0 which will constrain this procedure to only cycling trace tables within
					5 minutes of midnight. This is designed so that users do not cause a problem with the date naming convention
					without explicitly stating that they want it cycled at a different time. A setting of 1 will enable the procedure
					to run immediately, no time is needed to be specified.

*/
/*
CHANGE HISTORY:



*/
CREATE PROCEDURE [Trace].[usp_CycleTraceTables]
    @TraceOptionsID INT = 0
  , @debug BIT = 0
  , @midnightTEST BIT = 0
AS 
SET NOCOUNT ON;

DECLARE @PurgeDays INT
DECLARE @rightnow DATETIME 
DECLARE @date_time DATETIME
DECLARE @date_timeplus5 DATETIME
DECLARE @TraceName VARCHAR(100)
DECLARE @DROPgatherTRCDataSQL VARCHAR(8000)
DECLARE @cmd VARCHAR(500)
DECLARE @InsertSQL VARCHAR(8000)
DECLARE @gatherTRCDataSQL VARCHAR(8000) 
DECLARE @CreateTempTRCTableSQL VARCHAR(8000)
DECLARE @CheckImportFileExistenceCMD VARCHAR(8000) 
DECLARE @DoesImportFileExist INT  
DECLARE @RenamePreviousTraceFileCMD VARCHAR(800)
DECLARE @trace_ID INT
DECLARE @FilePathFileName NVARCHAR(200)
DECLARE @msg NVARCHAR(50)
DECLARE @DropTableSQL VARCHAR(8000) 
DECLARE @CreateTableSQL VARCHAR(8000)
DECLARE @NewTableName VARCHAR(256) 
DECLARE @YesterdayTableNamePrefix VARCHAR(12)
DECLARE @NewTableNamePrefix VARCHAR(12)
DECLARE @YesterdayTable DATETIME
DECLARE @Today DATETIME
DECLARE @CurrentTableName VARCHAR(75)
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
        SET @msg = N'Invalid Trace OptionsID (' + CAST(@TraceOptionsID AS VARCHAR(10)) + ') when executing [Trace].[usp_CycleTraceTables].'
		EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @msg, @LogMode = 'LIMITED'
        RAISERROR (@msg,11,1);
        RETURN;   
    END
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Set cycle time range 
\*------------------------------------------------*/
SET @rightnow = GETDATE() 
IF @midnightTEST = 0 
    BEGIN
		-- Determine Midnight of today.
        SET @date_time = DATEADD(d, -1, DATEADD(d, DATEDIFF(d, 0, @rightnow) + 1, 0))
    END 
ELSE 
    BEGIN 
		-- Determine current time of today.
        SET @date_time = DATEADD(d, -1, DATEADD(d, DATEDIFF(d, 0, @rightnow) + 1, 0))
        SET @date_time = DATEADD(mi, DATEDIFF(mi, @date_time, GETDATE()), @date_time)  
    END 

SET @date_timeplus5 = DATEADD(mi, 5, @date_time)  

IF @debug = 1 
    BEGIN
        PRINT '@date_time: ' + CONVERT(VARCHAR(25), @date_time)
        PRINT '@date_timeplus5: ' + CONVERT(VARCHAR(25), @date_timeplus5)
        PRINT '@rightnow: ' + CONVERT(VARCHAR(25), @rightnow)
    END         
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Begin cursoring through traces if it's time and 
the trace is set to enabled in the [Trace].[Options] table
\*------------------------------------------------*/
IF @rightnow >= @date_time
    AND @rightnow < @date_timeplus5 
    BEGIN 
      
        IF @TraceOptionsid = 0 
            BEGIN
				--Selects all Trace OptionsIDs        
                DECLARE EnabledCursor CURSOR FAST_FORWARD
                FOR
                SELECT DISTINCT t.[OptionID]
                FROM    [Trace].[Configs] t
                INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = t.[ConfigID]
                WHERE   t.[IsEnabled] = 1
                        AND c.[IsEnabled] = 1
            END
        ELSE 
            BEGIN
				--Selects only the inputed Trace OptionsID.
                DECLARE EnabledCursor CURSOR FAST_FORWARD
                FOR
                SELECT DISTINCT t.[OptionID]
                FROM    [Trace].[Configs] t
                INNER JOIN [Configuration].[Configs] c ON c.[ConfigID] = t.[ConfigID]
                WHERE   t.[OptionID] = @TraceOptionsid
                        AND t.[IsEnabled] = 1
                        AND c.[IsEnabled] = 1
            END

        OPEN EnabledCursor
        FETCH NEXT FROM EnabledCursor INTO @TraceOptionsID  

        WHILE @@FETCH_STATUS = 0 
            BEGIN	
                IF @debug = 1 
                    BEGIN 
                        PRINT '----------------------------------------------------'
                        PRINT 'Cursor iteration for Trace OptionsID (Enabled): ' + CONVERT(VARCHAR(10), @TraceOptionsID)
                        PRINT '----------------------------------------------------' + CHAR(13) + CHAR(10)
                    END      					     
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Get purgedays and ensure that it is a negative number
\*------------------------------------------------*/
				--Get purgedays from [Trace].[Options]
                SELECT  @PurgeDays = t.PurgeDays
                FROM    [Trace].[Options] t
                WHERE   t.[OptionID] = @TraceOptionsID

				--Switch to a negative number
                IF @PurgeDays > 0 
                    BEGIN
                        SET @PurgeDays = 0 - @PurgeDays
                    END
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Set @TraceName from [Trace].[Options]
\*------------------------------------------------*/
                SELECT  @TraceName = [traceName]
                FROM    [Trace].[Options]
                WHERE   [OptionID] = @TraceOptionsID         
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Set @CurrentTableName from [Trace].[Tables]
\*------------------------------------------------*/
                SELECT  @CurrentTableName = [TableName]
                FROM    [Trace].[Tables]
                WHERE   [OptionID] = @TraceOptionsID
                        AND IsMostRecent = 1

				IF @CurrentTableName IS NULL 
                    BEGIN
						
						IF @debug = 1
						BEGIN
							PRINT 'There was no IsMostRecent table registered so a new one is defined.'
						END
					                  
                        SET @YesterdayTable = DATEADD(dd, -1, GETDATE())

						SET @YesterdayTableNamePrefix = CAST(DATEPART(yyyy, @YesterdayTable) AS VARCHAR)
							+ CASE WHEN DATALENGTH(CAST(DATEPART(mm, @YesterdayTable) AS VARCHAR)) < 2 THEN '0' + CAST(DATEPART(mm, @YesterdayTable) AS VARCHAR)
								   WHEN DATALENGTH(CAST(DATEPART(mm, @YesterdayTable) AS VARCHAR)) = 2 THEN CAST(DATEPART(mm, @YesterdayTable) AS VARCHAR)
							  END + CASE WHEN DATALENGTH(CAST(DATEPART(dd, @YesterdayTable) AS VARCHAR)) < 2 THEN '0' + CAST(DATEPART(dd, @YesterdayTable) AS VARCHAR)
										 WHEN DATALENGTH(CAST(DATEPART(dd, @YesterdayTable) AS VARCHAR)) = 2 THEN CAST(DATEPART(dd, @YesterdayTable) AS VARCHAR)
									END + '_'

                        SET @CurrentTableName = @YesterdayTableNamePrefix + @TraceName

                        IF NOT EXISTS ( SELECT  [TableID]
                                        FROM    [Trace].[Tables]
                                        WHERE   [OptionID] = @TraceOptionsID
                                                AND TableName = @CurrentTableName ) 
                            BEGIN
                                INSERT  INTO [Trace].[Tables]
                                        (
                                          [OptionID]
                                        , TableName
                                        , IsMostRecent
                                        )
                                VALUES  (
                                          @TraceOptionsID
                                        , @CurrentTableName
                                        , 1
                                        )

								SET @LogEntry = 'Insert table name into the Trace.Tables table with IsMostRecent set to 1.'
								EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                            END
                        ELSE 
                            BEGIN
								--Set all tables for this Trace OptionsID to 0                                  
                                UPDATE  [Trace].[Tables]
                                SET     IsMostRecent = 0
                                WHERE   [OptionID] = @TraceOptionsID

								SET @LogEntry = 'Set all [Trace].[Tables] records IsMostRecent field to 0.'
								EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
								--Then set the proper IsMostRecent flag.
                                UPDATE  [Trace].[Tables]
                                SET     IsMostRecent = 1
                                WHERE   [OptionID] = @TraceOptionsID
                                        AND TableName = @CurrentTableName
										
								SET @LogEntry = 'Set table name (' + @CurrentTableName + ') record''s in IsMostRecent field to 1 [Trace].[Tables].'
								EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
                            END
                    END

					IF @debug = 1
					BEGIN
						PRINT 'Current Table Name: ' + @CurrentTableName
					END
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Cleanup tables older than PurgeDays 
\*------------------------------------------------*/
                DECLARE @droptablename VARCHAR(256)
                DECLARE droptables CURSOR
                FOR
                SELECT  name
                FROM    sys.tables
                WHERE   name LIKE '%' + @tracename
                        AND LEN(name) = 9 + LEN(@tracename)
                        AND create_date < DATEADD(dd, @PurgeDays, GETDATE())

                OPEN droptables
                FETCH droptables INTO @droptablename 

                WHILE @@fetch_status = 0 
                    BEGIN 
										                                
                        EXEC ( 'drop table [Trace].[' + @droptablename + ']' )

						SET @LogEntry = '[Trace].[usp_CycleTraceTables] - dropped table [Trace].[' + @droptablename + ']'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

                        FETCH droptables INTO @droptablename 
                    END 

                CLOSE droptables
                DEALLOCATE droptables
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Cycle enabled trace tables
\*------------------------------------------------*/
                BEGIN TRANSACTION CycleTable

                SET @Today = GETDATE()

                SET @NewTableNamePrefix = CAST(DATEPART(yyyy, @Today) AS VARCHAR)
                    + CASE WHEN DATALENGTH(CAST(DATEPART(mm, @Today) AS VARCHAR)) < 2 THEN '0' + CAST(DATEPART(mm, @Today) AS VARCHAR)
                            WHEN DATALENGTH(CAST(DATEPART(mm, @Today) AS VARCHAR)) = 2 THEN CAST(DATEPART(mm, @Today) AS VARCHAR)
                        END + CASE WHEN DATALENGTH(CAST(DATEPART(dd, @Today) AS VARCHAR)) < 2 THEN '0' + CAST(DATEPART(dd, @Today) AS VARCHAR)
                                    WHEN DATALENGTH(CAST(DATEPART(dd, @Today) AS VARCHAR)) = 2 THEN CAST(DATEPART(dd, @Today) AS VARCHAR)
                            END + '_'

                SET @NewTableName = @NewTableNamePrefix + @TraceName

                IF @debug = 1 
                    BEGIN 
                        PRINT 'New Table Name: ' + @NewTableName
                    END 

                IF EXISTS ( SELECT  1
                            FROM    Utility.dbo.sysobjects
                            WHERE   id = OBJECT_ID('Trace.' + @NewTableName)
                                    AND OBJECTPROPERTY(id, N'IsUserTable') = 1 ) 
                    BEGIN 
						SET @DropTableSQL = 'DROP TABLE [Trace].[' + @NewTableName + ']'
						
						SET @LogEntry = '[Trace].[usp_CycleTraceTables] - DROPPED TABLE [Trace].[' + @NewTableName + ']'
						EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

                        EXEC ( @DropTableSQL ) 
                    END
								
				--Register the new table as most recent
				IF NOT EXISTS (SELECT TableName FROM [Trace].[Tables] WHERE TableName = @NewTableName)
                BEGIN
					INSERT  INTO [Trace].[Tables]
							( [OptionID], TableName, IsMostRecent )
					VALUES  ( @TraceOptionsID, @NewTableName, 1 )

					SET @LogEntry = 'Registered new Trace Table - [Trace].[' + @NewTableName + ']'
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				END
				ELSE
				BEGIN
					UPDATE [Trace].[Tables] SET IsMostRecent = 1
					WHERE [OptionID] = @TraceOptionsID 
							AND TableName = @NewTableName
					
					SET @LogEntry = 'Updated Trace Table - [Trace].[' + @NewTableName + '] - to ''IsMostRecent'''
					EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'
				END

				--Set the previous table as not most recent
				UPDATE [Trace].[Tables] SET IsMostRecent = 0
				WHERE [OptionID] = @TraceOptionsID 
						AND TableName = @CurrentTableName
						
				IF @debug = 1 
                    BEGIN
						SELECT  @CurrentTableName = [TableName]
						FROM    [Trace].[Tables]
						WHERE   [OptionID] = @TraceOptionsID
								AND IsMostRecent = 1
                        PRINT 'Most recent table now is: ' + @CurrentTableName
                    END

                SET @CreateTableSQL = '
										CREATE TABLE [Trace].[' + @NewTableName + '] (
										[RowNumber] [int] IDENTITY (1, 1) NOT NULL ,
										[EventClass] [int] NULL ,
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
										[ObjectID] [int] NULL 
										) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
											
										ALTER TABLE [Trace].[' + @NewTableName + '] ADD 
										CONSTRAINT PK_' + @NewTableName + '_RowNumber PRIMARY KEY ([RowNumber])
										'
                EXEC ( @CreateTableSQL ) 

				SET @LogEntry = '[Trace].[usp_CycleTraceTables] - ' + @CreateTableSQL
				EXEC Logging.usp_InsertLogEntry @Feature = 'Query Trace', @TextEntry = @LogEntry, @LogMode = 'VERBOSE'

				IF @debug = 1
				BEGIN
					PRINT 'Table [Trace].[' + @NewTableName + '] created.'
				END              
                                      
                IF @@ERROR = 0 
                    BEGIN
                        COMMIT TRANSACTION CycleTable
                    END
                ELSE 
                    BEGIN
                        RAISERROR('An error occured during the cycling of trace tables. Transaction was rolled back.',11,1)
                        ROLLBACK TRANSACTION CycleTable
                    END
/*------------------------------------------------*\
\*------------------------------------------------*/
/*------------------------------------------------*\
Finalize the enabled trace cursor
\*------------------------------------------------*/      
                FETCH NEXT FROM EnabledCursor INTO @TraceOptionsID
            END
        CLOSE EnabledCursor
        DEALLOCATE EnabledCursor
    END
/*------------------------------------------------*\
\*------------------------------------------------*/
SET NOCOUNT OFF
GO