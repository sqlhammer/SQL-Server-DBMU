/*	Enable clr functionality and ad hoc distributed queries	*/
  EXEC sp_configure 'show advanced options',1
  RECONFIGURE WITH OVERRIDE
  EXEC sp_configure 'clr enabled',1
  RECONFIGURE WITH OVERRIDE
  EXEC sys.sp_configure @configname = 'ad hoc distributed queries', @configvalue = 1
  RECONFIGURE WITH OVERRIDE
  EXEC sp_configure 'show advanced options',0
  RECONFIGURE WITH OVERRIDE
/************************************************************/