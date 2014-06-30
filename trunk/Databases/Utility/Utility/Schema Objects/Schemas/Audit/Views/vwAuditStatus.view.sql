CREATE VIEW [Audit].[vwAuditStatus]
AS
	select name AS [TriggerName]
		, CASE is_disabled
			WHEN 1 THEN 'False'
			ELSE 'True'
		END AS [IsEnabled]
	from master.sys.server_triggers 
	where name = 'ServerAuditTrigger'
