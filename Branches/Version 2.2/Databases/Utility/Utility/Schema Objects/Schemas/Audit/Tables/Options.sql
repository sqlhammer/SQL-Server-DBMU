CREATE TABLE [Audit].[Options]
(
	[OptionID] INT IDENTITY(1,1) NOT NULL,
	[PurgeValue] BIGINT NULL,
	[PurgeTypeID] INT NULL
)
GO
ALTER TABLE Audit.Options ADD CONSTRAINT PK_Audit_Options_OptionID PRIMARY KEY (OptionID);
GO
ALTER TABLE Audit.Options ADD CONSTRAINT FK_Audit_Options_PurgeTypeID FOREIGN KEY ([PurgeTypeID]) 
	REFERENCES [Lookup].[PurgeTypes] ([PurgeTypeID]);
GO
ALTER TABLE Audit.Options ADD CONSTRAINT [CK_Audit_Options_PurgeTypeID] CHECK (
	CASE 
		WHEN [Lookup].[IsPurgeByDays]([PurgeTypeID]) = 1 THEN 1
		WHEN [Lookup].[IsPurgeByRows]([PurgeTypeID]) = 1 THEN 1
		WHEN [PurgeTypeID] IS NULL THEN 1
		ELSE 0
	END = 1
	)
GO
ALTER TABLE Audit.Options ADD CONSTRAINT [CK_Audit_Options_PurgeTypeID_PurgeValue] CHECK (
	CASE
		WHEN [PurgeValue] IS NOT NULL AND [PurgeTypeID] IS NOT NULL THEN 1
		WHEN [PurgeValue] IS NULL AND [PurgeTypeID] IS NULL THEN 1
		ELSE 0
	END = 1
	)
GO
