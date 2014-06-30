--  Comments here are associated with the test.
--  For test case examples, see: http://tsqlt.org/user-guide/tsqlt-tutorial/
ALTER PROCEDURE [SQLCop].[test usp_VerifyBackupPlansExist]
AS
BEGIN
  --Assemble
  --  This section is for code that sets up the environment. It often
  --  contains calls to methods such as tSQLt.FakeTable and tSQLt.SpyProcedure
  --  along with INSERTs of relevant data.
  --  For more information, see http://tsqlt.org/user-guide/isolating-dependencies/
  
	--Disable all constraints
	EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'

	/**************************************************************************************/
	-- Purge all options
	DELETE FROM [Backup].[Options]
	-- Purge all feature configs
	DELETE FROM [Backup].[Configs]
	-- Purge all configurations
	DELETE FROM [Configuration].[Configs]
	/**************************************************************************************/

  --Act
  --  Execute the code under test like a stored procedure, function or view
  --  and capture the results in variables or tables.
	EXEC [Utility].[Backup].[usp_VerifyBackupPlansExist] @debug = 0, @MailProfile = 'DefaultMailProfile';
  
END;

