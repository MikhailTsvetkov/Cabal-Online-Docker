EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'<DB_NAME>'
GO
USE [master]
GO
DROP DATABASE [<DB_NAME>]
GO
