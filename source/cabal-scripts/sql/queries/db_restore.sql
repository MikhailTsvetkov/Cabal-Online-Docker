SET NOCOUNT ON
DECLARE @Table TABLE (
    LogicalName varchar(128),
    [PhysicalName] varchar(128), 
    [Type] varchar, 
    [FileGroupName] varchar(128), 
    [Size] varchar(128),
    [MaxSize] varchar(128), 
    [FileId]varchar(128), 
    [CreateLSN]varchar(128), 
    [DropLSN]varchar(128), 
    [UniqueId]varchar(128), 
    [ReadOnlyLSN]varchar(128), 
    [ReadWriteLSN]varchar(128),
    [BackupSizeInBytes]varchar(128), 
    [SourceBlockSize]varchar(128), 
    [FileGroupId]varchar(128), 
    [LogGroupGUID]varchar(128), 
    [DifferentialBaseLSN]varchar(128), 
    [DifferentialBaseGUID]varchar(128), 
    [IsReadOnly]varchar(128), 
    [IsPresent]varchar(128), 
    [TDEThumbprint]varchar(128),
    [SnapshotUrl]varchar(128)
)
DECLARE @Path varchar(1000)='/var/opt/mssql/backup/<DB_NAME>.bak'
DECLARE @LogicalNameData varchar(128),@LogicalNameLog varchar(128)
DECLARE @query varchar(MAX), @bakstat INT
DECLARE @File_Exists INT
 

EXEC Master.dbo.xp_fileexist @Path, @File_Exists OUT
IF (@File_Exists <> 1)
BEGIN
	PRINT 'File <DB_NAME>.bak not found'
END
ELSE
BEGIN
	INSERT INTO @table
	EXEC('
	RESTORE FILELISTONLY
	   FROM DISK=''' +@Path+ '''
	   ')

	SET @LogicalNameData=(SELECT LogicalName FROM @Table WHERE Type='D')
	SET @LogicalNameLog=(SELECT LogicalName FROM @Table WHERE Type='L')

	SELECT @bakstat=count(*) FROM sys.dm_exec_requests where command = 'BACKUP DATABASE'
	IF (@bakstat>0)
	BEGIN
		PRINT 'Backup is in progress. Try later.
Aborted.'
	END

	ELSE
	BEGIN

		ALTER DATABASE [<DB_NAME>] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		RESTORE DATABASE [<DB_NAME>] FROM  DISK = @Path WITH  FILE = 1,  MOVE @LogicalNameData TO N'/var/opt/mssql/data/<DB_NAME>.mdf',  MOVE @LogicalNameLog TO N'/var/opt/mssql/data/<DB_NAME>_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 5
		ALTER DATABASE [<DB_NAME>] SET MULTI_USER

		IF (@LogicalNameData<>'<DB_NAME>')
		BEGIN
			SET @query = 'ALTER DATABASE [<DB_NAME>] MODIFY FILE ( NAME =  '+ @LogicalNameData +', NEWNAME = <DB_NAME> )'
			EXEC(@query)
		END
		IF (@LogicalNameLog<>'<DB_NAME>_log')
		BEGIN
			SET @query = 'ALTER DATABASE [<DB_NAME>] MODIFY FILE ( NAME =  '+ @LogicalNameLog +', NEWNAME = <DB_NAME>_log )'
			EXEC(@query)
		END

	END
END

GO
