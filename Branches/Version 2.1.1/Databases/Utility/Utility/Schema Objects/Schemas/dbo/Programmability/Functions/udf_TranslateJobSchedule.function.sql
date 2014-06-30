/*
FUNCTION:		dbo.udf_TranslateJobSchedule
AUTHOR:			Derik Hammer
CREATION DATE:	4/17/2012
DESCRIPTION:	This function returns a single row table that contains all of the necessary values for creating
				a SQL Agent job schedule. The purpose of this is to translate easy to read/remember terms into
				the complicated integer values that SQL Agent uses to process a job schedule.
PARAMETERS:		@Freq_Type VARCHAR(50) --Describes the type of schedule desire, e.g. DAILY, WEEKLY, MONTHLY
				@DayofWeek VARCHAR(9) --Choses the day of the week if DAILY wasn't selected.
				@StartTime INT --Time the schedule will start on the day of trigger.
				@EndTime INT --Time the schedule will end on the day of trigger.

*/
/*
CHANGE HISTORY:

** Derik Hammer ** 05/08/2012 --	Added functionality to allow for hourly and by the minute scheduling.

** Derik Hammer ** 10/23/2012 --	Altered the int values for freq_interval to fix bug where incorrect data was being entered.

** Derik Hammer ** 12/13/2012 --	Fixed bug with Job Schedule Translator preventing HOURLY and MINUTES type schedules to be created.

** Derik Hammer ** 01/15/2013 --	Weekly and Monthly periodicities don't use the same frequency_interval values so I removed the monthly
									functionality and modified the f_Interval setting logic to account for this. For the moment the only 
									monthly schedules supported is if you want to run the job once a month on a particular numbered day.

** Derik Hammer ** 02/19/2013 --	Removed the setting of the frequency interval to 1 for HOURLY and MINUTES types. The correct setting is 0.

*/
CREATE FUNCTION [dbo].[udf_TranslateJobSchedule]
(
	@Freq_Type VARCHAR(50)
  , @DayofWeek VARCHAR(MAX)
  , @Interval INT
  , @StartTime INT
  , @EndTime INT
)
RETURNS @JobScheduleBrokenDown TABLE 
(
	f_Type INT NULL
  , f_Interval INT NULL
  , f_SubDay_Type INT NULL
  , f_SubDay_Interval INT NULL
  , f_Relative_Interval INT NULL
  , f_Recurrence_Factor INT NULL  
  , StartTime INT NULL
  , EndTime INT NULL
)
AS
BEGIN

	DECLARE @f_Type INT
	DECLARE @f_SubDay_Type INT
	DECLARE @f_SubDay_Interval INT
	DECLARE @f_Interval INT
	DECLARE @f_Recurrence_Factor INT
	DECLARE @EndTimeConversion VARCHAR(8)
	DECLARE @Hour CHAR(2)
	DECLARE @Minute CHAR(2)
	DECLARE @Second CHAR(2)
	DECLARE @Day VARCHAR(9)
	DECLARE @Days TABLE (DaySelected VARCHAR(9))
	DECLARE @Position INT

	SET @f_Type =
		CASE 
				WHEN UPPER(@Freq_Type)='DAILY' THEN 4 
				WHEN UPPER(@Freq_Type)='WEEKLY' THEN 8 
				WHEN UPPER(@Freq_Type)='MONTHLY' THEN 16
				WHEN UPPER(@Freq_Type)='HOURLY' THEN 4
				WHEN UPPER(@Freq_Type)='MINUTES' THEN 4
		END;

	SET @f_Recurrence_Factor =
		CASE 
				WHEN UPPER(@Freq_Type)='DAILY' THEN 0
				WHEN UPPER(@Freq_Type)='WEEKLY' THEN 1 
				WHEN UPPER(@Freq_Type)='MONTHLY' THEN 1
				WHEN UPPER(@Freq_Type)='HOURLY' THEN 1
				WHEN UPPER(@Freq_Type)='MINUTES' THEN 1
		END;

	WHILE CHARINDEX(', ',@DayofWeek) > 0 SET @DayofWeek = REPLACE(@DayofWeek,', ',',')
	WHILE CHARINDEX(' ,',@DayofWeek) > 0 SET @DayofWeek = REPLACE(@DayofWeek,' ,',',')
	WHILE CHARINDEX(',,',@DayofWeek) > 0 SET @DayofWeek = REPLACE(@DayofWeek,',,',',')

	IF RIGHT(@DayofWeek,1) = ',' SET @DayofWeek = LEFT(@DayofWeek,LEN(@DayofWeek) - 1)
	IF LEFT(@DayofWeek,1) = ','  SET @DayofWeek = RIGHT(@DayofWeek,LEN(@DayofWeek) - 1)

	SET @DayofWeek = LTRIM(RTRIM(@DayofWeek))

	WHILE LEN(@DayofWeek) > 0
	BEGIN
		SET @Position = CHARINDEX(',', @DayofWeek)
		IF @Position = 0
		BEGIN
			SET @Day = @DayofWeek
			SET @DayofWeek = ''
		END
		ELSE
		BEGIN
			SET @Day = LEFT(@DayofWeek, @Position - 1)
			SET @DayofWeek = RIGHT(@DayofWeek, LEN(@DayofWeek) - @Position)
		END
		IF @Day <> '-' INSERT INTO @Days (DaySelected) VALUES(@Day)
	END
    
	SET @f_Interval = 0

	IF UPPER(@Freq_Type)='DAILY'
		SET @f_Interval = 1

	WHILE EXISTS (SELECT DaySelected FROM @Days)
	BEGIN
		SELECT TOP 1 @Day = DaySelected FROM @Days

		SET @f_Interval =
			CASE 
					WHEN UPPER(@Freq_Type)='DAILY' THEN 1
					WHEN UPPER(@Freq_Type)='HOURLY' THEN 1
					WHEN UPPER(@Freq_Type)='MINUTES' THEN 1
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='MONDAY' OR UPPER(@Day)='MON')) THEN @f_Interval + 2
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='TUESDAY' OR UPPER(@Day)='TUES')) THEN @f_Interval + 4
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='WEDNESDAY' OR UPPER(@Day)='WED')) THEN @f_Interval + 8
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='THURSDAY' OR UPPER(@Day)='THURS')) THEN @f_Interval + 16
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='FRIDAY' OR UPPER(@Day)='FRI')) THEN @f_Interval + 32
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='SATURDAY' OR UPPER(@Day)='SAT')) THEN @f_Interval + 64
					WHEN (UPPER(@Freq_Type)='WEEKLY' AND (UPPER(@Day)='SUNDAY' OR UPPER(@Day)='SUN')) THEN @f_Interval + 1
			END;

		DELETE FROM @Days WHERE DaySelected = @Day
	END

	SET @f_SubDay_Type =
		CASE 
				WHEN UPPER(@Freq_Type)='DAILY' THEN 1
				WHEN UPPER(@Freq_Type)='WEEKLY' THEN 1
				WHEN UPPER(@Freq_Type)='MONTHLY' THEN 1
				WHEN UPPER(@Freq_Type)='HOURLY' THEN 8
				WHEN UPPER(@Freq_Type)='MINUTES' THEN 4
		END;

	IF UPPER(@Freq_Type)='MONTHLY'
	BEGIN
		SET @f_Interval = ISNULL(@Interval,0)
		SET @f_SubDay_Interval = 0
	END  
	ELSE
	BEGIN
		SET @f_SubDay_Interval = ISNULL(@Interval,0)
	END  
	
	--Set default end time
	SELECT @EndTimeConversion = CASE LEN(@StartTime) WHEN 5 THEN REPLICATE('0',6 - LEN(@StartTime)) + CAST(@StartTime AS VARCHAR(6)) 
													WHEN 4 THEN REPLICATE('0',6 - LEN(@StartTime)) + CAST(@StartTime AS VARCHAR(6))
													WHEN 3 THEN REPLICATE('0',6 - LEN(@StartTime)) + CAST(@StartTime AS VARCHAR(6)) 
													WHEN 2 THEN REPLICATE('0',6 - LEN(@StartTime)) + CAST(@StartTime AS VARCHAR(6)) 
													WHEN 1 THEN REPLICATE('0',6 - LEN(@StartTime)) + CAST(@StartTime AS VARCHAR(6)) 
													ELSE CAST(@StartTime AS VARCHAR(8))
													END

	SET @Hour = LEFT(@EndTimeConversion,2)
	SET @Minute = SUBSTRING(@EndTimeConversion,3,2)
	SET @Second = RIGHT(@EndTimeConversion,2)

	IF CAST(@Minute AS INT) = 0
		SET @Minute = '59'
	ELSE
	BEGIN
		SET @Minute = REPLACE(CAST((CAST(@Minute AS INT) - 1) AS CHAR(2)),'0 ','00')
		IF LEN(@Minute) = 1
			SET @Minute = '0' + @Minute
		IF LEN(@Hour) = 1
			SET @Hour = '0' + @Hour
	END	

	IF @Minute = '59'
	BEGIN
		IF CAST(@hour AS INT) = 0
			SET @Hour = '23'
		ELSE
		BEGIN
			SET @Hour = CAST((CAST(@Hour AS INT)-1) AS CHAR(2))
			IF LEN(@Hour) = 1
				SET @Hour = '0' + @Hour
		END
	END
	
	SET @EndTimeConversion = @Hour + @Minute + @Second

	--Set end time
	SET @EndTime = ISNULL(@EndTime,@EndTimeConversion)
                              
	--Insert our new row
    INSERT  INTO @JobScheduleBrokenDown
            ( f_Type
            , f_Interval
            , f_SubDay_Type
            , f_SubDay_Interval
            , f_Relative_Interval
            , f_Recurrence_Factor
            , StartTime
			, EndTime 
            )
    VALUES  ( @f_Type
            , @f_Interval
            , @f_SubDay_Type
            , @f_SubDay_Interval
            , 0
            , @f_Recurrence_Factor
            , @StartTime
            , @EndTime
            ) 
    
    --Return the table
	RETURN 
END