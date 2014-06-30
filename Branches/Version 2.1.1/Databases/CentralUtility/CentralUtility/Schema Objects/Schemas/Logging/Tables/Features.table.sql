CREATE TABLE [Logging].[Features]
(
	[LoggingFeatureID] INT IDENTITY(1,1) NOT NULL,
	[FeatureID] INT NOT NULL,
	[OptionID] INT NOT NULL
)
GO
ALTER TABLE [Logging].[Features] ADD CONSTRAINT PK_Logging_Features_LoggingFeatureID PRIMARY KEY CLUSTERED ( [LoggingFeatureID] ASC ) ON [Logging]
GO
ALTER TABLE [Logging].[Features] ADD CONSTRAINT FK_Logging_Features_FeatureID FOREIGN KEY ([FeatureID]) REFERENCES [Lookup].[Features] ([FeatureID])
GO
ALTER TABLE [Logging].[Features] ADD CONSTRAINT FK_Logging_Features_OptionID FOREIGN KEY ([OptionID]) REFERENCES [Logging].[Options] ([OptionID])
GO
