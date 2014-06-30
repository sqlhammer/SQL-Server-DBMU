--  Comments here are associated with the test.
--  For test case examples, see: http://tsqlt.org/user-guide/tsqlt-tutorial/
ALTER PROCEDURE [SQLCop].[test Configuration.usp_DisableConfig]
AS
BEGIN
  --Assemble
  --  This section is for code that sets up the environment. It often
  --  contains calls to methods such as tSQLt.FakeTable and tSQLt.SpyProcedure
  --  along with INSERTs of relevant data.
  --  For more information, see http://tsqlt.org/user-guide/isolating-dependencies/

	-- Disable all the constraint in database to avoid our delete failing
	EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'

	-- Purge all configurations
	DELETE FROM [Configuration].[Configs]

	-- Setup test 2 configurtions
	SET IDENTITY_INSERT [Configuration].[Configs] ON 
	INSERT INTO [Configuration].[Configs] (ConfigID, [ConfigDesc], [IsEnabled], [ConfigName])
		VALUES (1,'',1,'Test1')
	INSERT INTO [Configuration].[Configs] (ConfigID, [ConfigDesc], [IsEnabled], [ConfigName])
		VALUES (2,'',1,'Test2')
	SET IDENTITY_INSERT [Configuration].[Configs] OFF

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.

	EXEC [Configuration].[usp_DisableConfig] @ConfigID = 1
	
  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
	
	IF EXISTS (SELECT * FROM [Configuration].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 1)
		OR NOT EXISTS (SELECT * FROM [Configuration].[Configs] WHERE [IsEnabled] = 1 AND [ConfigID] = 2)
	BEGIN
		EXEC tSQLt.Fail 'Configuration.usp_DisableConfig failed to disable individual test configuration.'
	END

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.

	UPDATE [Configuration].[Configs]
	SET [IsEnabled] = 1
	WHERE [IsEnabled] = 0

	EXEC [Configuration].[usp_DisableConfig] @ConfigID = 0
	
  --Assert
  --  Compare the expected and actual values, or call tSQLt.Fail in an IF statement.  
  --  Available Asserts: tSQLt.AssertEquals, tSQLt.AssertEqualsString, tSQLt.AssertEqualsTable
  --  For a complete list, see: http://tsqlt.org/user-guide/assertions/
	
	IF EXISTS (SELECT * FROM [Configuration].[Configs] WHERE [IsEnabled] = 1)
	BEGIN
		EXEC tSQLt.Fail 'Configuration.usp_DisableConfig failed to disable test configurations when passing in the wild card parameter ''0''.'
	END
  
END;

