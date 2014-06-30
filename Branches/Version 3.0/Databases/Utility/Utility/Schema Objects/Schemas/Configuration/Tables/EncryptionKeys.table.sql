CREATE TABLE [Configuration].[EncryptionKeys]
(
	[EncryptionKeyID] INT IDENTITY(1,1) NOT NULL,
	[KeyName] SYSNAME NOT NULL,
	[KeySecret] VARCHAR(128) NOT NULL
)
GO
ALTER TABLE [Configuration].[EncryptionKeys] ADD CONSTRAINT PK_Configuration_EncryptionKeys_EncryptionKeyID PRIMARY KEY CLUSTERED ([EncryptionKeyID] ASC)
GO
ALTER TABLE [Configuration].[EncryptionKeys] ADD CONSTRAINT UQ_Configuration_EncryptionKeys_KeyName UNIQUE ([KeyName])
GO
