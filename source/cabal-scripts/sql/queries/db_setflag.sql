USE [<DB_NAME>]
SET NOCOUNT ON
DECLARE @startDate DATETIME, @dur INT, @lastResult INT, @newStartDate DATETIME, @D DATETIME, @cw INT, @pw INT, @nv INT
SET @D=GETDATE()
SET @cw=1
SET @pw=1

UPDATE [cabal_instantWar_nationRewardWarResults] SET [DurationDay]=7
SELECT TOP 1 @lastResult=[WarResultsID], @nv=[VictoryNation]
FROM [cabal_instantWar_results]
WHERE [WarMapId]=(SELECT MAX([WarMapId]) FROM [cabal_instantWar_results])
ORDER BY [WarResultsID] DESC

IF (@@ROWCOUNT=1)
BEGIN
	IF (@nv=1) BEGIN SET @cw=2 END
	ELSE BEGIN SET @pw=2 END

	SELECT TOP 1 @startDate=[RewardStartDateTime], @dur=[DurationDay]
	FROM [cabal_instantWar_nationRewardWarResults]
	ORDER BY [NationRewardWarResultsID] DESC

	IF (@@ROWCOUNT=0)
	BEGIN
		SELECT @newStartDate=CAST(CAST(DATEADD(d, DATEDIFF(d,@D,0)%7,@D+7) AS DATE) AS DATETIME)

		INSERT INTO [cabal_instantWar_nationRewardWarResults] (
			[TotalRound],[CapellaWin],[ProcyonWin],[RewardStartDateTime],[LastWarResultsID],[DurationDay]
		) VALUES (
			3,@cw,@pw,DATEADD(mi,-5,@newStartDate),@lastResult,7
		)
	END
	ELSE
	BEGIN
		SELECT @newStartDate=DATEADD(d, @dur, @startDate)
		IF (@newStartDate>@D)
		BEGIN
			INSERT INTO [cabal_instantWar_nationRewardWarResults] (
				[TotalRound],[CapellaWin],[ProcyonWin],[RewardStartDateTime],[LastWarResultsID],[DurationDay]
			) VALUES (
				3,@cw,@pw,DATEADD(mi,-5,@newStartDate),@lastResult,7
			)
		END
		ELSE
		BEGIN
			SELECT @newStartDate=CAST(CAST(DATEADD(d, DATEDIFF(d,@D,0)%7,@D+7) AS DATE) AS DATETIME)

			INSERT INTO [cabal_instantWar_nationRewardWarResults] (
				[TotalRound],[CapellaWin],[ProcyonWin],[RewardStartDateTime],[LastWarResultsID],[DurationDay]
			) VALUES (
				3,@cw,@pw,DATEADD(mi,-5,@newStartDate),@lastResult,7
			)
		END
	END
END
