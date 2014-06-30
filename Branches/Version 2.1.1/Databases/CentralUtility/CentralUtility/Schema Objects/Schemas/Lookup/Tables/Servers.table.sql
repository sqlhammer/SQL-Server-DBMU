CREATE TABLE [Lookup].[Servers]
(
	[ServerID] bigint IDENTITY(1,1) NOT NULL, 
	[Server] sysname NOT NULL,
	[DNS] varchar(255) NULL
)
GO
ALTER TABLE [Lookup].[Servers] ADD CONSTRAINT PK_Lookup_Servers_ServerID PRIMARY KEY CLUSTERED ([ServerID] ASC)
GO