CREATE  FUNCTION [udf_freq_interval_desc] (@freq_interval INT)  
RETURNS VARCHAR(1000)  
AS  
BEGIN  
   DECLARE @result VARCHAR(1000)  

   SET @result = ''
	   
   IF (@freq_interval & 1 = 1)  
      SET @result = 'Sunday, '  
   IF (@freq_interval & 2 = 2)  
      SET @result = @result + 'Monday, '  
   IF (@freq_interval & 4 = 4)  
      SET @result = @result + 'Tuesday, '  
   IF (@freq_interval & 8 = 8)  
      SET @result = @result + 'Wednesday, '  
   IF (@freq_interval & 16 = 16)  
      SET @result = @result + 'Thursday, '  
   IF (@freq_interval & 32 = 32)  
      SET @result = @result + 'Friday, '  
   IF (@freq_interval & 64 = 64)  
      SET @result = @result + 'Saturday, '  

   RETURN(LEFT(@result,LEN(@result)-1))  
END 

GO
