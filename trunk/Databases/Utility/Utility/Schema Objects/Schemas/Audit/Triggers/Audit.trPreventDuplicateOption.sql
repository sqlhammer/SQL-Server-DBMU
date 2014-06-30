CREATE TRIGGER [Audit].[trPreventDuplicateOption]
ON [Audit].[Options]
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON

	IF 1 < (SELECT COUNT(*) FROM [Audit].[Options])
	BEGIN
		RAISERROR('There can only be a single audit retention purge option at a time. Please update the existing record. This insert has been rolled back.',16,1);
	END
END
