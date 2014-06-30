ALTER DATABASE [$(DatabaseName)]
	ADD LOG FILE
	(
		NAME = [Utility_log],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_log.ldf',
		SIZE = 5120 KB,
		FILEGROWTH = 10240 KB,
		MAXSIZE = UNLIMITED
	)
