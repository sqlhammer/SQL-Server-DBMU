CREATE VIEW [Logging].[vwGetLogEntries]
AS
	SELECT	[Entries].[EntryID]
			, [Entries].[LoginName]
			, [Feats].[FeatureName] AS [Feature]
			, [Entries].[InsertDate]
			, [Entries].[TextEntry]
	FROM [Logging].[Entries] Entries
	INNER JOIN [Lookup].[Features] Feats ON [Feats].[FeatureID] = [Entries].[FeatureID]
