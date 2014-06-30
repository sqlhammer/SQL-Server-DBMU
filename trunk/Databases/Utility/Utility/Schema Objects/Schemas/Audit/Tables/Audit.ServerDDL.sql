create table [Audit].[ServerDDL]
(
	[ServerDDLID] UNIQUEIDENTIFIER NOT NULL,
	[AuditDate] [datetime] not null,
	[LoginName] [sysname] not null,
	[EventType] [sysname] not null,
	[ServerName] [sysname] not null,
	[DatabaseName] [sysname] null,
	[SchemaName] [sysname] null,
	[ObjectName] [sysname] null,
	[TSQLCommand] [varchar](max) null,
	[XMLEventData] [xml] not null
)
GO
ALTER TABLE [Audit].[ServerDDL] ADD CONSTRAINT DF_Audit_ServerDDL_ServerDDLID DEFAULT NEWID() FOR [ServerDDLID]
GO
create clustered index [IX_Audit_ServerDDL_AuditDate] ON [Audit].[ServerDDL] ( [AuditDate] desc ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
create nonclustered index [IX_Audit_ServerDDL_EventType] ON [Audit].[ServerDDL] ( [EventType] ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
ALTER TABLE [Audit].[ServerDDL] ADD CONSTRAINT PK_Audit_ServerDDL_ServerDDLID PRIMARY KEY NONCLUSTERED ([ServerDDLID]) ON [Auditing]
GO
