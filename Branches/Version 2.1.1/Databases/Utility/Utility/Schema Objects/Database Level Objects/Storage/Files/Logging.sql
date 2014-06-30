ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Logging],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Logging.ndf', 
        SIZE = 5120 KB, 
        MAXSIZE = UNLIMITED, 
        FILEGROWTH = 10240 KB
    ) TO FILEGROUP [Logging]
