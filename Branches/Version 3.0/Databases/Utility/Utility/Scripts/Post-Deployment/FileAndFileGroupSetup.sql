SET NOCOUNT ON;
/**************************************************************************************/
--Set data and log file initialization sizes
/**************************************************************************************/
IF ((SELECT (size * 8) / 1024 AS [Size_MB]
	FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)') < 5)
BEGIN
	ALTER DATABASE [$(DatabaseName)] 
	MODIFY FILE
		(NAME = $(DatabaseName),
		SIZE = 5MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 100MB);
END

IF ((SELECT (size * 8) / 1024 AS [Size_MB]
	FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_log') < 5)
BEGIN
	ALTER DATABASE [$(DatabaseName)] 
	MODIFY FILE
		(NAME = $(DatabaseName)_log,
		SIZE = 5MB,
		MAXSIZE = UNLIMITED,
		FILEGROWTH = 100MB);
END
/**************************************************************************************/
--Create auditing and logging filegroup
/**************************************************************************************/
IF NOT EXISTS (SELECT file_id FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_Auditing')
BEGIN
	ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Auditing],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Auditing.ndf',
		SIZE = 5MB, MAXSIZE = UNLIMITED, FILEGROWTH = 100MB
	) TO FILEGROUP [Auditing]
END
IF NOT EXISTS (SELECT file_id FROM [$(DatabaseName)].sys.[database_files] WHERE name = '$(DatabaseName)_Logging')
BEGIN
	ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Logging],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Logging.ndf',
		SIZE = 5MB, MAXSIZE = UNLIMITED, FILEGROWTH = 100MB
	) TO FILEGROUP [Logging]
END
/**************************************************************************************/