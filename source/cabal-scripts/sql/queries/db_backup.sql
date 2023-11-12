USE [master]

BACKUP DATABASE [<DB_NAME>] TO  DISK = N'/var/opt/mssql/backup/<DB_NAME>.bak' WITH NOFORMAT, INIT, NAME = N'<DB_NAME>', SKIP, NOREWIND, NOUNLOAD, STATS = 10, CHECKSUM
GO

declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'<DB_NAME>' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'<DB_NAME>' )
if @backupSetId is null begin raiserror(N'Verification error. No backup information found for database "<DB_NAME>".', 16, 1) end
RESTORE VERIFYONLY FROM DISK = N'/var/opt/mssql/backup/<DB_NAME>.bak' WITH FILE = @backupSetId, NOUNLOAD, NOREWIND
GO
