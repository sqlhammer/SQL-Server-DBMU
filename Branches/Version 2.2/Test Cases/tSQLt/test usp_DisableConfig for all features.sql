--  Comments here are associated with the test.
--  For test case examples, see: http://tsqlt.org/user-guide/tsqlt-tutorial/
ALTER PROCEDURE [SQLCop].[test usp_DisableConfig for all features]
AS
BEGIN
  --Assemble
  --  This section is for code that sets up the environment. It often
  --  contains calls to methods such as tSQLt.FakeTable and tSQLt.SpyProcedure
  --  along with INSERTs of relevant data.
  --  For more information, see http://tsqlt.org/user-guide/isolating-dependencies/

	-- Disable all the constraint in database to avoid our delete failing
	EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'

	/**************************************************************************************/
	-- Purge all options
	DELETE FROM [Backup].[Options]
	DELETE FROM [DiskCleanup].[Options]
	DELETE FROM [IndexMaint].[Options]
	DELETE FROM [Logging].[Options]
	DELETE FROM [Trace].[Options]
	-- Purge all feature configs
	DELETE FROM [Backup].[Configs]
	DELETE FROM [DiskCleanup].[Configs]
	DELETE FROM [IndexMaint].[Configs]
	DELETE FROM [Logging].[Configs]
	DELETE FROM [Trace].[Configs]
	-- Purge all configurations
	DELETE FROM [Configuration].[Configs]
	/**************************************************************************************/
	-- Setup 2 backup options
	SET IDENTITY_INSERT [Backup].[Options] ON
	INSERT INTO [Backup].[Options] ([OptionID],[BackupTypeID] ,[DiskLocationID] ,[EncryptionKeyID] ,
			[CheckPreferredReplica] ,[Verify] ,[CHECKSUM] ,[UseCompression] ,[FileCount] ,
			[BufferCount] ,[MaxTransSize] ,[FrequencyType] ,[FrequencyInterval] ,
			[FrequencySubDayType] ,[FrequencySubDayInterval] ,[FrequencyRelativeInterval] ,
			[FrequencyRecurranceFactor] ,[StartTime] ,[EndTime])
		VALUES  (1,1,1,NULL,1,0,0,0,NULL,NULL,NULL,1,1,1,1,1,1,0,235959)
	INSERT INTO [Backup].[Options] ([OptionID],[BackupTypeID] ,[DiskLocationID] ,[EncryptionKeyID] ,
			[CheckPreferredReplica] ,[Verify] ,[CHECKSUM] ,[UseCompression] ,[FileCount] ,
			[BufferCount] ,[MaxTransSize] ,[FrequencyType] ,[FrequencyInterval] ,
			[FrequencySubDayType] ,[FrequencySubDayInterval] ,[FrequencyRelativeInterval] ,
			[FrequencyRecurranceFactor] ,[StartTime] ,[EndTime])
		VALUES  (2,1,1,NULL,1,0,0,0,NULL,NULL,NULL,1,1,1,1,1,1,0,235959)
	SET IDENTITY_INSERT [Backup].[Options] OFF
	-- Setup 2 diskcleanup options
	SET IDENTITY_INSERT [DiskCleanup].[Options] ON
	INSERT INTO [DiskCleanup].[Options] ([OptionID],[DiskLocationID] ,[PurgeValue] ,[PurgeTypeID])
		VALUES  (1,1,1,1)
	INSERT INTO [DiskCleanup].[Options] ([OptionID],[DiskLocationID] ,[PurgeValue] ,[PurgeTypeID])
		VALUES  (2,1,1,1)
	SET IDENTITY_INSERT [DiskCleanup].[Options] OFF
	-- Setup 2 indexmaint options
	SET IDENTITY_INSERT [IndexMaint].[Options] ON
	INSERT INTO [IndexMaint].[Options] ([OptionID],[FragLimit] ,[PageSpaceLimit] ,[StatisticsExpiration] ,
	          [ExecuteWindowEnd] ,[MaxDefrag] ,[CheckPeriodicity])
		VALUES  (1,20,90,2,NULL,40,NULL)
	INSERT INTO [IndexMaint].[Options] ([OptionID],[FragLimit] ,[PageSpaceLimit] ,[StatisticsExpiration] ,
	          [ExecuteWindowEnd] ,[MaxDefrag] ,[CheckPeriodicity])
		VALUES  (2,20,90,2,NULL,40,NULL)
	SET IDENTITY_INSERT [IndexMaint].[Options] OFF
	-- Setup 2 Logging options
	SET IDENTITY_INSERT [Logging].[Options] ON
	INSERT INTO [Logging].[Options] ([OptionID],[LoggingModeID] ,[PurgeTypeID] ,[PurgeValue])
		VALUES  (1,1,1,1000)
	INSERT INTO [Logging].[Options] ([OptionID],[LoggingModeID] ,[PurgeTypeID] ,[PurgeValue])
		VALUES  (2,1,1,1000)
	SET IDENTITY_INSERT [Logging].[Options] OFF
	-- Setup 2 Trace options
	SET IDENTITY_INSERT [Trace].[Options] ON
	INSERT INTO [Trace].[Options] ([OptionID],[DiskLocationID] ,[TraceName] ,[PurgeDays] ,[MaxFileSize] ,
	          [QueryRunTime] ,[Reads] ,[Writes])
		VALUES  (1,1,'trace1',1,1,1000,1000,1000)
	INSERT INTO [Trace].[Options] ([OptionID],[DiskLocationID] ,[TraceName] ,[PurgeDays] ,[MaxFileSize] ,
	          [QueryRunTime] ,[Reads] ,[Writes])
		VALUES  (2,1,'trace2',1,1,1000,1000,1000)
	SET IDENTITY_INSERT [Trace].[Options] OFF
	/**************************************************************************************/
	-- Setup test 2 configurations
	SET IDENTITY_INSERT [Configuration].[Configs] ON 
	INSERT INTO [Configuration].[Configs] (ConfigID, [ConfigDesc], [IsEnabled], [ConfigName])
		VALUES (1,'',1,'Test1')
	INSERT INTO [Configuration].[Configs] (ConfigID, [ConfigDesc], [IsEnabled], [ConfigName])
		VALUES (2,'',1,'Test2')
	SET IDENTITY_INSERT [Configuration].[Configs] OFF
	-- Setup test 3 backup configurations
	SET IDENTITY_INSERT [Backup].[Configs] ON 
	INSERT INTO [Backup].[Configs] (BackupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (1,1,1,1)
	INSERT INTO [Backup].[Configs] (BackupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (2,2,1,2)
	INSERT INTO [Backup].[Configs] (BackupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (3,2,1,1)
	SET IDENTITY_INSERT [Backup].[Configs] OFF
	-- Setup test 3 diskcleanup configurations
	SET IDENTITY_INSERT [DiskCleanup].[Configs] ON 
	INSERT INTO [DiskCleanup].[Configs] (DiskCleanupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (1,1,1,1)
	INSERT INTO [DiskCleanup].[Configs] (DiskCleanupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (2,2,1,2)
	INSERT INTO [DiskCleanup].[Configs] (DiskCleanupConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (3,2,1,1)
	SET IDENTITY_INSERT [DiskCleanup].[Configs] OFF
	-- Setup test 3 indexmaint configurations
	SET IDENTITY_INSERT [IndexMaint].[Configs] ON 
	INSERT INTO [IndexMaint].[Configs] (IndexMaintConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (1,1,1,1)
	INSERT INTO [IndexMaint].[Configs] (IndexMaintConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (2,2,1,2)
	INSERT INTO [IndexMaint].[Configs] (IndexMaintConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (3,2,1,1)
	SET IDENTITY_INSERT [IndexMaint].[Configs] OFF
	-- Setup test 3 logging configurations
	SET IDENTITY_INSERT [Logging].[Configs] ON 
	INSERT INTO [Logging].[Configs] (LoggingConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (1,1,1,1)
	INSERT INTO [Logging].[Configs] (LoggingConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (2,2,1,2)
	INSERT INTO [Logging].[Configs] (LoggingConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (3,2,1,1)
	SET IDENTITY_INSERT [Logging].[Configs] OFF
	-- Setup test 3 trace configurations
	SET IDENTITY_INSERT [Trace].[Configs] ON 
	INSERT INTO [Trace].[Configs] (TraceConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (1,1,1,1)
	INSERT INTO [Trace].[Configs] (TraceConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (2,2,1,2)
	INSERT INTO [Trace].[Configs] (TraceConfigID, [ConfigID], [IsEnabled], [OptionID])
		VALUES (3,2,1,1)
	SET IDENTITY_INSERT [Trace].[Configs] OFF


  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.

	-- Test with Configuration ID
	EXEC [Backup].[usp_DisableConfig] @ConfigID = 1, @OptionID = 1
	EXEC [IndexMaint].[usp_DisableConfig] @ConfigID = 1, @OptionID = 1
	EXEC [Logging].[usp_DisableConfig] @ConfigID = 1, @OptionID = 1
	EXEC [Trace].[usp_DisableConfig] @ConfigID = 1, @OptionID = 1
	EXEC [DiskCleanup].[usp_DisableConfig] @ConfigID = 1, @OptionID = 1
	
  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
	
	DECLARE @BackupMsg_Batch1 VARCHAR(200) = NULL, @IndexMaintMsg_Batch1 VARCHAR(200) = NULL, 
		@LoggingMsg_Batch1 VARCHAR(200) = NULL, @DiskCleanupMsg_Batch1 VARCHAR(200) = NULL, 
		@TraceMsg_Batch1 VARCHAR(200) = NULL

	IF EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @BackupMsg_Batch1 = 'Backup.usp_DisableConfig - Failed when using OptionID and ConfigID.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @IndexMaintMsg_Batch1 = 'IndexMaint.usp_DisableConfig - Failed when using OptionID and ConfigID.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @LoggingMsg_Batch1 = 'Logging.usp_DisableConfig - Failed when using OptionID and ConfigID.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @DiskCleanupMsg_Batch1 = 'DiskCleanup.usp_DisableConfig - Failed when using OptionID and ConfigID.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @TraceMsg_Batch1 = 'Trace.usp_DisableConfig - Failed when using OptionID and ConfigID.' + CHAR(13) + CHAR(10)
	END

	/**************************************************************************************/
	-- Message report occurs at the end of the procedure.
	/**************************************************************************************/

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.

	-- Reset Disabled status
	UPDATE [Backup].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [IndexMaint].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [Logging].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [DiskCleanup].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [Trace].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0

	--Test with configuration name
	EXEC [Backup].[usp_DisableConfig] @ConfigName = 'Test1', @OptionID = 1
	EXEC [IndexMaint].[usp_DisableConfig] @ConfigName = 'Test1', @OptionID = 1
	EXEC [Logging].[usp_DisableConfig] @ConfigName = 'Test1', @OptionID = 1
	EXEC [Trace].[usp_DisableConfig] @ConfigName = 'Test1', @OptionID = 1
	EXEC [DiskCleanup].[usp_DisableConfig] @ConfigName = 'Test1', @OptionID = 1
	
  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
	
	DECLARE @BackupMsg_Batch2 VARCHAR(200) = NULL, @IndexMaintMsg_Batch2 VARCHAR(200) = NULL, 
		@LoggingMsg_Batch2 VARCHAR(200) = NULL, @DiskCleanupMsg_Batch2 VARCHAR(200) = NULL, 
		@TraceMsg_Batch2 VARCHAR(200) = NULL

	IF EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @BackupMsg_Batch2 = 'Backup.usp_DisableConfig - Failed when using OptionID and ConfigName.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @IndexMaintMsg_Batch2 = 'IndexMaint.usp_DisableConfig - Failed when using OptionID and ConfigName.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @LoggingMsg_Batch2 = 'Logging.usp_DisableConfig - Failed when using OptionID and ConfigName.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @DiskCleanupMsg_Batch2 = 'DiskCleanup.usp_DisableConfig - Failed when using OptionID and ConfigName.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 0 AND [ConfigID] = 2)
	BEGIN
		SET @TraceMsg_Batch2 = 'Trace.usp_DisableConfig - Failed when using OptionID and ConfigName.' + CHAR(13) + CHAR(10)
	END

	
	/**************************************************************************************/
	-- Message report occurs at the end of the procedure.
	/**************************************************************************************/

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.

	-- Reset Enabled status
	UPDATE [Backup].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [IndexMaint].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [Logging].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [DiskCleanup].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0
	UPDATE [Trace].[Configs] SET [IsEnabled] = 1 WHERE [IsEnabled] = 0

	--Test with configuration name
	EXEC [Backup].[usp_DisableConfig] @OptionID = 1
	EXEC [IndexMaint].[usp_DisableConfig] @OptionID = 1
	EXEC [Logging].[usp_DisableConfig] @OptionID = 1
	EXEC [Trace].[usp_DisableConfig] @OptionID = 1
	EXEC [DiskCleanup].[usp_DisableConfig] @OptionID = 1
	
  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
	
	DECLARE @BackupMsg_Batch3 VARCHAR(200) = NULL, @IndexMaintMsg_Batch3 VARCHAR(200) = NULL, 
		@LoggingMsg_Batch3 VARCHAR(200) = NULL, @DiskCleanupMsg_Batch3 VARCHAR(200) = NULL, 
		@TraceMsg_Batch3 VARCHAR(200) = NULL

	IF EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 1 AND [OptionID] = 1)
		OR EXISTS (SELECT * FROM [Backup].[Configs] WHERE [IsEnabled] = 0 AND [OptionID] = 2)
	BEGIN
		SET @BackupMsg_Batch3 = 'Backup.usp_DisableConfig - Failed when using OptionID only.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 1 AND [OptionID] = 1)
		OR EXISTS (SELECT * FROM [IndexMaint].[Configs] WHERE [IsEnabled] = 0 AND [OptionID] = 2)
	BEGIN
		SET @IndexMaintMsg_Batch3 = 'IndexMaint.usp_DisableConfig - Failed when using OptionID only.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 1 AND [OptionID] = 1)
		OR EXISTS (SELECT * FROM [Logging].[Configs] WHERE [IsEnabled] = 0 AND [OptionID] = 2)
	BEGIN
		SET @LoggingMsg_Batch3 = 'Logging.usp_DisableConfig - Failed when using OptionID only.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 1 AND [OptionID] = 1)
		OR EXISTS (SELECT * FROM [DiskCleanup].[Configs] WHERE [IsEnabled] = 0 AND [OptionID] = 2)
	BEGIN
		SET @DiskCleanupMsg_Batch3 = 'DiskCleanup.usp_DisableConfig - Failed when using OptionID only.' + CHAR(13) + CHAR(10)
	END
	IF EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 1 AND [OptionID] = 1)
		OR EXISTS (SELECT * FROM [Trace].[Configs] WHERE [IsEnabled] = 0 AND [OptionID] = 2)
	BEGIN
		SET @TraceMsg_Batch3 = 'Trace.usp_DisableConfig - Failed when using OptionID only.' + CHAR(13) + CHAR(10)
	END

	/**************************************************************************************/
	--Report
	/**************************************************************************************/
	
	IF @BackupMsg_Batch3 IS NOT NULL OR @DiskCleanupMsg_Batch3 IS NOT NULL OR @IndexMaintMsg_Batch3 IS NOT NULL OR 
		@LoggingMsg_Batch3 IS NOT NULL OR @TraceMsg_Batch3 IS NOT NULL OR @BackupMsg_Batch1 IS NOT NULL OR 
		@DiskCleanupMsg_Batch1 IS NOT NULL OR @IndexMaintMsg_Batch1 IS NOT NULL OR @LoggingMsg_Batch1 IS NOT NULL OR 
		@TraceMsg_Batch1 IS NOT NULL OR @BackupMsg_Batch2 IS NOT NULL OR @DiskCleanupMsg_Batch2 IS NOT NULL OR 
		@IndexMaintMsg_Batch2 IS NOT NULL OR @LoggingMsg_Batch2 IS NOT NULL OR @TraceMsg_Batch2 IS NOT NULL
	BEGIN
		DECLARE @Msg_Batch1 VARCHAR(2000), @Msg_Batch2 VARCHAR(2000), @Msg_Batch3 VARCHAR(2000)

		SELECT @Msg_Batch1 = CHAR(13) + CHAR(10) + ISNULL(@BackupMsg_Batch1,'Backup.usp_DisableConfig - Succeeded when using OptionID and ConfigID.') + CHAR(13) + CHAR(10) +
			ISNULL(@DiskCleanupMsg_Batch1,'DiskCleanup.usp_DisableConfig - Succeeded when using OptionID and ConfigID.') + CHAR(13) + CHAR(10) +
			ISNULL(@IndexMaintMsg_Batch1,'IndexMaint.usp_DisableConfig - Succeeded when using OptionID and ConfigID.') + CHAR(13) + CHAR(10) +
			ISNULL(@LoggingMsg_Batch1,'Logging.usp_DisableConfig - Succeeded when using OptionID and ConfigID.') + CHAR(13) + CHAR(10) +
			ISNULL(@TraceMsg_Batch1,'Trace.usp_DisableConfig - Succeeded when using OptionID and ConfigID.') + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

		SELECT @Msg_Batch2 = ISNULL(@BackupMsg_Batch2,'Backup.usp_DisableConfig - Succeeded when using OptionID and ConfigName.') + CHAR(13) + CHAR(10) +
			ISNULL(@DiskCleanupMsg_Batch2,'DiskCleanup.usp_DisableConfig - Succeeded when using OptionID and ConfigName.') + CHAR(13) + CHAR(10) +
			ISNULL(@IndexMaintMsg_Batch2,'IndexMaint.usp_DisableConfig - Succeeded when using OptionID and ConfigName.') + CHAR(13) + CHAR(10) +
			ISNULL(@LoggingMsg_Batch2,'Logging.usp_DisableConfig - Succeeded when using OptionID and ConfigName.') + CHAR(13) + CHAR(10) +
			ISNULL(@TraceMsg_Batch2,'Trace.usp_DisableConfig - Succeeded when using OptionID and ConfigName.') + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

		SELECT @Msg_Batch3 = ISNULL(@BackupMsg_Batch3,'Backup.usp_DisableConfig - Succeeded when using OptionID only.') + CHAR(13) + CHAR(10) +
			ISNULL(@DiskCleanupMsg_Batch3,'DiskCleanup.usp_DisableConfig - Succeeded when using OptionID only.') + CHAR(13) + CHAR(10) +
			ISNULL(@IndexMaintMsg_Batch3,'IndexMaint.usp_DisableConfig - Succeeded when using OptionID only.') + CHAR(13) + CHAR(10) +
			ISNULL(@LoggingMsg_Batch3,'Logging.usp_DisableConfig - Succeeded when using OptionID only.') + CHAR(13) + CHAR(10) +
			ISNULL(@TraceMsg_Batch3,'Trace.usp_DisableConfig - Succeeded when using OptionID only.') + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)

		EXEC tSQLt.Fail @Msg_Batch1, @Msg_Batch2, @Msg_Batch3
	END
	
END;

