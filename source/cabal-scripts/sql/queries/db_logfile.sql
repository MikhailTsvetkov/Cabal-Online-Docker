SET NOCOUNT ON
select physical_name
from sys.master_files
where database_id = db_id ( '<DB_NAME>' ) and [type]=1
