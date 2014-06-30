CREATE FUNCTION [udf_Date2Str] (@date INT)
RETURNS VARCHAR(10)
AS
BEGIN
   DECLARE @strdate CHAR(8)
   SET @strdate = LEFT(CONVERT(VARCHAR,@date) + '00000000', 8)

   RETURN SUBSTRING(@strdate,5,2) + '/' + RIGHT(@strdate,2) + '/' + LEFT(@strdate,4) 
END
GO