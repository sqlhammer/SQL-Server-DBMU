ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Utility],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix).mdf',
		SIZE = 5120 KB,
		FILEGROWTH = 10240 KB,
		MAXSIZE = UNLIMITED
	) TO FILEGROUP [Primary]
