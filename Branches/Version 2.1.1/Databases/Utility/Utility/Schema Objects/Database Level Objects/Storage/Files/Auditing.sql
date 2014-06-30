ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [Auditing],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Auditing.ndf', 
        SIZE = 5120 KB, 
        MAXSIZE = UNLIMITED, 
        FILEGROWTH = 10240 KB
    ) TO FILEGROUP [Auditing]
