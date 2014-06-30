/*						Correct db owner						*/
IF EXISTS ( SELECT name
			FROM   sys.databases
			WHERE SUSER_SNAME(owner_sid) <> 'sa' 
				AND NAME = '$(DatabaseName)'
		  )
BEGIN
	IF (SELECT [$(DatabaseName)].[dbo].[udf_GetVersion]()) < 11
	BEGIN
		EXEC sp_changedbowner 'sa';
	END
	ELSE
	BEGIN
		ALTER AUTHORIZATION ON DATABASE::$(DatabaseName) TO sa;
	END
END
/****************************************************************/
