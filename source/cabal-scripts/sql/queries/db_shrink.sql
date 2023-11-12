USE <DB_NAME>
ALTER DATABASE <DB_NAME>
SET RECOVERY SIMPLE
GO

SET NOCOUNT ON
DECLARE @LogicalNameLog varchar(128)
select @LogicalNameLog=[name]
from sys.master_files
where database_id = db_id ( '<DB_NAME>' ) and [type]=1

DBCC shrinkfile(@LogicalNameLog,notruncate) 
DBCC shrinkfile(@LogicalNameLog,truncateonly) 
GO
ALTER DATABASE <DB_NAME> 
SET RECOVERY FULL
GO
