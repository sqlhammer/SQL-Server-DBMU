/*
Do not change the database name.
It will be properly coded for build and deployment
This is using sqlcmd variable substitution
*/
ALTER DATABASE [$(DatabaseName)]
    ADD FILE 
    (
    	NAME = [$(DatabaseName)_Logging], 
    	FILENAME = '$(DefaultDataPath)$(DatabaseName)_Logging.ndf', 
        SIZE = 3072 KB, 
        MAXSIZE = UNLIMITED, 
        FILEGROWTH = 1024 KB
    )  TO FILEGROUP [Logging]
	

