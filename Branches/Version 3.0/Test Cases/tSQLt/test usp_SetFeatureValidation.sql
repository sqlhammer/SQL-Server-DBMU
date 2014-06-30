--  Comments here are associated with the test.
--  For test case examples, see: http://tsqlt.org/user-guide/tsqlt-tutorial/
ALTER PROCEDURE [SQLCop].[test usp_SetFeatureValidation]
AS
BEGIN
  --Assemble
  --  This section is for code that sets up the environment. It often
  --  contains calls to methods such as tSQLt.FakeTable and tSQLt.SpyProcedure
  --  along with INSERTs of relevant data.
  --  For more information, see http://tsqlt.org/user-guide/isolating-dependencies/
  DECLARE @TestOnePassed BIT = 1
	, @TestTwoPassed BIT = 1;

  EXEC [tSQLt].[FakeTable] @TableName = N'Configuration.RegisteredDatabases',
      @Identity = 0, -- bit
      @ComputedColumns = 0, -- bit
      @Defaults = 0 -- bit
  
  INSERT INTO Configuration.RegisteredDatabases ([DatabaseID], [DatabaseName], verifybackup, verifydiskcleanup, verifyindexmaint)
  VALUES (1, 'master', 1, 1, 1);

  INSERT INTO Configuration.RegisteredDatabases ([DatabaseID], [DatabaseName], verifybackup, verifydiskcleanup, verifyindexmaint)
  VALUES (1, 'msdb', 1, 1, 1);

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.
  
  --Test 1
  EXEC [Configuration].[usp_SetFeatureValidation] @Databases = 'master', @VerifyBackup = 0, @VerifyDiskCleanup = 0, @VerifyIndexMaint = 0;

  IF EXISTS (SELECT * FROM Configuration.RegisteredDatabases 
			WHERE (verifybackup = 1 OR verifydiskcleanup = 1 OR verifyindexmaint = 1)
				AND DatabaseName = 'master')
  BEGIN
		SET @TestOnePassed = 0;
  END
  IF EXISTS (SELECT * FROM Configuration.RegisteredDatabases 
			WHERE (verifybackup = 0 OR verifydiskcleanup = 0 OR verifyindexmaint = 0)
				AND DatabaseName = 'msdb')
  BEGIN
		SET @TestOnePassed = 0;
  END

  --Setup Test 2
  UPDATE Configuration.RegisteredDatabases 
  SET VerifyBackup = 0, VerifyIndexMaint = 0, VerifyDiskCleanup = 0

  --Test 2
  EXEC [Configuration].[usp_SetFeatureValidation] @Databases = 'master,msdb', @VerifyBackup = 1, @VerifyDiskCleanup = 1, @VerifyIndexMaint = 1;

  IF EXISTS (SELECT * FROM Configuration.RegisteredDatabases WHERE verifybackup = 0 OR verifydiskcleanup = 0 OR verifyindexmaint = 0)
  BEGIN
	SET @TestTwoPassed = 0;
  END

  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
  IF @TestOnePassed = 0 OR @TestTwoPassed = 0
  BEGIN
	DECLARE @Msg_Batch1 VARCHAR(500), @Msg_Batch2 VARCHAR(500)

	IF @TestOnePassed = 0
	BEGIN
		SET @Msg_Batch1 = 'Test 1: Setting all feature configurations for a single database -- failed.';
	END
	ELSE
	BEGIN
		SET @Msg_Batch1 = 'Test 1: Setting all feature configurations for a single database -- succeeded.';
	END

	IF @TestTwoPassed = 0
	BEGIN
		SET @Msg_Batch2 = 'Test 2: Setting all feature configurations for a comma separated list of databases -- failed.';
	END
	ELSE
	BEGIN
		SET @Msg_Batch2 = 'Test 2: Setting all feature configurations for a comma separated list of databases -- succeeded.';
	END

	EXEC tSQLt.Fail @Msg_Batch1, @Msg_Batch2;
  END
  
END;

