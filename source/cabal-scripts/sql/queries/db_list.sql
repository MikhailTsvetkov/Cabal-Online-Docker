SET NOCOUNT ON
SELECT [name]
FROM sys.databases
WHERE NOT [name]='master' AND NOT [name]='model' AND NOT [name]='msdb' AND NOT [name]='tempdb';
