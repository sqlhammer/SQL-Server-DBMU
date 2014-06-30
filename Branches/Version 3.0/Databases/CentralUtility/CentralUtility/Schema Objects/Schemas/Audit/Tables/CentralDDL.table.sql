CREATE TABLE [Audit].[CentralDDL]
(
	[CentralDDLID] BIGINT IDENTITY(1,1) NOT NULL,
	[ServerDDLID] UNIQUEIDENTIFIER NOT NULL,
	[OriginatingServer] SYSNAME NOT NULL,
	[AuditDate] [datetime] not null,
	[LoginName] [sysname] not null,
	[EventType] [sysname] not null,
	[DatabaseName] [sysname] null,
	[SchemaName] [sysname] null,
	[ObjectName] [sysname] null,
	[TSQLCommand] [varchar](max) null,
	[XMLEventData] [xml] not NULL,
	[InsertDate] DATETIME2(3) NOT NULL
)
GO
CREATE CLUSTERED INDEX [IX_Audit_CentralDDL_AuditDate] ON [Audit].[CentralDDL] ( [AuditDate] DESC ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
CREATE NONCLUSTERED INDEX [IX_Audit_CentralDDL_EventType] ON [Audit].[CentralDDL] ( [EventType] ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
CREATE NONCLUSTERED INDEX [IX_Audit_CentralDDL_OriginatingServer] ON [Audit].[CentralDDL] ( [OriginatingServer] ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
CREATE NONCLUSTERED INDEX [IX_Audit_CentralDDL_DatabaseName] ON [Audit].[CentralDDL] ( [DatabaseName] ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
CREATE NONCLUSTERED INDEX [IX_Audit_CentralDDL_LoginName] ON [Audit].[CentralDDL] ( [LoginName] ) WITH (FILLFACTOR = 80) ON [Auditing]
GO
ALTER TABLE [Audit].[CentralDDL] ADD CONSTRAINT PK_Audit_CentralDDL_CentralDDLID PRIMARY KEY NONCLUSTERED ([CentralDDLID]) ON [Auditing]
GO
ALTER TABLE [Audit].[CentralDDL] ADD CONSTRAINT DF_Audit_CentralDDL_InsertDate DEFAULT GETDATE() FOR [InsertDate]
GO
