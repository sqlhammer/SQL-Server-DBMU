/*
PROCEDURE:		[dbo].[udf_FeatureSelect]
DESCRIPTION:	This function will return a tabled list of feature names derived from a comma separated list of database names.
PARAMETERS:		@List nvarchar(max) --Inputted comma separated list of database names.

*/
/*
CHANGE HISTORY:



*/
CREATE FUNCTION [dbo].[udf_FeatureSelect]
(
	@FeatureList nvarchar(max)
)

RETURNS @List TABLE (FeatureName nvarchar(max) NOT NULL)

AS

BEGIN

  DECLARE @Item nvarchar(max)
  DECLARE @Position int

  DECLARE @CurrentID int
  DECLARE @CurrentItem nvarchar(max)
  DECLARE @CurrentItemStatus bit

  DECLARE @ItemList01 TABLE (Item nvarchar(max))

  DECLARE @ItemList02 TABLE (ID int IDENTITY PRIMARY KEY,
                             Item nvarchar(max),
                             ItemStatus bit,
                             Completed bit)

  DECLARE @ItemList03 TABLE (Item nvarchar(max),
                             ItemStatus bit)


  ----------------------------------------------------------------------------------------------------
  --// Split input string into elements                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE CHARINDEX(', ',@FeatureList) > 0 SET @FeatureList = REPLACE(@FeatureList,', ',',')
  WHILE CHARINDEX(' ,',@FeatureList) > 0 SET @FeatureList = REPLACE(@FeatureList,' ,',',')
  WHILE CHARINDEX(',,',@FeatureList) > 0 SET @FeatureList = REPLACE(@FeatureList,',,',',')

  IF RIGHT(@FeatureList,1) = ',' SET @FeatureList = LEFT(@FeatureList,LEN(@FeatureList) - 1)
  IF LEFT(@FeatureList,1) = ','  SET @FeatureList = RIGHT(@FeatureList,LEN(@FeatureList) - 1)

  SET @FeatureList = LTRIM(RTRIM(@FeatureList))

  WHILE LEN(@FeatureList) > 0
  BEGIN
    SET @Position = CHARINDEX(',', @FeatureList)
    IF @Position = 0
    BEGIN
      SET @Item = @FeatureList
      SET @FeatureList = ''
    END
    ELSE
    BEGIN
      SET @Item = LEFT(@FeatureList, @Position - 1)
      SET @FeatureList = RIGHT(@FeatureList, LEN(@FeatureList) - @Position)
    END
    IF @Item <> '-' INSERT INTO @ItemList01 (Item) VALUES(@Item)
  END

  ----------------------------------------------------------------------------------------------------
  --// Handle exclusions                                                                 //--
  ----------------------------------------------------------------------------------------------------

  INSERT INTO @ItemList02 (Item, ItemStatus, Completed)
  SELECT DISTINCT Item = CASE WHEN Item LIKE '-%' THEN RIGHT(Item,LEN(Item) - 1) ELSE Item END,
                  ItemStatus = CASE WHEN Item LIKE '-%' THEN 0 ELSE 1 END,
                  0 AS Completed
  FROM @ItemList01

  ----------------------------------------------------------------------------------------------------
  --// Resolve elements                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE EXISTS (SELECT * FROM @ItemList02 WHERE Completed = 0)
  BEGIN

    SELECT TOP 1 @CurrentID = ID,
                 @CurrentItem = Item,
                 @CurrentItemStatus = ItemStatus
    FROM @ItemList02
    WHERE Completed = 0
    ORDER BY ID ASC

    IF @CurrentItem = 'ALL_FEATURES'
    BEGIN
      INSERT INTO @ItemList03 (Item, ItemStatus)
      SELECT [FeatureName], @CurrentItemStatus
      FROM [Lookup].[Features]
    END
    ELSE
    BEGIN
      INSERT INTO @ItemList03 (Item, ItemStatus)
      SELECT [FeatureName], @CurrentItemStatus
      FROM [Lookup].[Features]
      WHERE [FeatureName] = PARSENAME(@CurrentItem,1)
    END

    UPDATE @ItemList02
    SET Completed = 1
    WHERE ID = @CurrentID

    SET @CurrentID = NULL
    SET @CurrentItem = NULL
    SET @CurrentItemStatus = NULL

  END

  ----------------------------------------------------------------------------------------------------
  --// Return results                                                                             //--
  ----------------------------------------------------------------------------------------------------

  INSERT INTO @List (FeatureName)
  SELECT Item
  FROM @ItemList03
  WHERE ItemStatus = 1
  EXCEPT
  SELECT Item
  FROM @ItemList03
  WHERE ItemStatus = 0

  RETURN

  ----------------------------------------------------------------------------------------------------

END
