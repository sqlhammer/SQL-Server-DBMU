CREATE FUNCTION [dbo].[udf_TimeToStr] (@time DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @strtime CHAR(6)
   DECLARE @strReturn VARCHAR(10)
   SET @strtime = RIGHT('000000' + CONVERT(VARCHAR,@time),6)

   SET @strReturn = LEFT(@strtime,2) + ':' + SUBSTRING(@strtime,3,2) + ':' + RIGHT(@strtime,2)

   RETURN (@strReturn)
END
