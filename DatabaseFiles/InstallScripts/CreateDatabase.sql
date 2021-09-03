USE [master];
GO
SET NOCOUNT ON;

/********************************************************************************************
Purpose: This will create a database with 2 data files and set up the files appropriately.

History:
Date          Version    Author                   Notes:
10/11/2018    0.0        Benjamin Reynolds        Initial Creation.
10/09/2020    0.0        Benjamin Reynolds        Added DatabaseName as a parameter

********************************************************************************************/

DECLARE  @DefLog        nvarchar(512)
        ,@DefMdf        nvarchar(512)
        ,@Mdfi          tinyint
        ,@Ldfi          tinyint
        ,@Arg           nvarchar(10)
        ,@CreateDB      nvarchar(max)
        ,@ErrorMessage  nvarchar(4000)
        ,@ErrorNumber   int
        ,@ErrorSeverity int
        ,@ErrorState    int
        ,@DatabaseName  sysname = N'Intune';

SET @CreateDB = N'CREATE DATABASE ['+@DatabaseName+N']
    ON PRIMARY ( NAME = '+@DatabaseName+N'
                ,FILENAME = N''@DefMdf'+@DatabaseName+N'.mdf''
                ,SIZE = 2GB
                ,FILEGROWTH = 1024MB
                )
              ,( NAME = '+@DatabaseName+N'_1
                ,FILENAME = N''@DefMdf'+@DatabaseName+N'_1.ndf''
                ,SIZE = 2GB
                ,FILEGROWTH = 1024MB
                )
        LOG ON ( NAME = '+@DatabaseName+N'_log
                ,FILENAME = N''@DefLog'+@DatabaseName+N'_log.ldf''
                ,SIZE = 1GB
                ,FILEGROWTH = 1024MB
                )
COLLATE SQL_Latin1_General_CP1_CI_AS
  WITH TRUSTWORTHY ON;';

IF DB_ID(@DatabaseName) IS NOT NULL
BEGIN
    PRINT 'Database Exists; script not running!';
    GOTO EndScript;
END;
ELSE
BEGIN
    -- Get the Default MDF location (from the registry):
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultData', @DefMdf OUTPUT, 'no_output';
    IF @DefMdf IS NULL -- if we couldn't get the key from this location for some reason then look at the startup parameters:
    BEGIN
        SET @Mdfi = 0;
        WHILE @Mdfi < 100
        BEGIN
            SELECT @Arg = N'SQLArg' + CAST(@Mdfi AS nvarchar(4));
            EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', @Arg, @DefMdf OUTPUT, 'no_output';
            IF LOWER(LEFT(REVERSE(@DefMdf),10)) = N'fdm.retsam'
            BEGIN
                -- If we found the parameter for the master data file then set the variable and stop processing this loop:
                SELECT @DefMdf = SUBSTRING(@DefMdf,3,CHARINDEX(N'\master.mdf',@DefMdf)-3);
                BREAK;
            END;
            ELSE
            SET @DefMdf = NULL;

            SELECT @Mdfi += 1;
        END;
    END;

    IF @DefMdf IS NOT NULL AND LEFT(REVERSE(@DefMdf),1) != N'\'
    SET @DefMdf += N'\';

    -- Get the Default LDF location (from the registry):
    EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'DefaultLog', @DefLog OUTPUT, 'no_output';
    IF @DefLog IS NULL -- if we couldn't get the key from this location for some reason then look at the startup parameters:
    BEGIN
        SET @Ldfi = 0;
        WHILE @Ldfi < 100
        BEGIN
            SELECT @Arg = N'SQLArg' + CAST(@Ldfi AS nvarchar(4));
            EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer\Parameters', @Arg, @DefLog OUTPUT, 'no_output';
            IF LOWER(LEFT(REVERSE(@DefLog),11)) = N'fdl.goltsam'
            BEGIN
                -- If we found the parameter for the master log file then set the variable and stop processing this loop:
                SELECT @DefLog = SUBSTRING(@DefLog,3,CHARINDEX(N'\mastlog.ldf',@DefLog)-3);
                BREAK;
            END;
            ELSE
            SET @DefLog = NULL;

            SELECT @Ldfi += 1;
        END;
    END;

    IF @DefLog IS NOT NULL AND LEFT(REVERSE(@DefLog),1) != N'\'
    SET @DefLog += N'\';

    IF @DefMdf IS NOT NULL AND @DefLog IS NOT NULL
    BEGIN
        BEGIN TRY
            SELECT @CreateDB = REPLACE(REPLACE(@CreateDB,N'@DefMdf',@DefMdf),N'@DefLog',@DefLog);
            EXECUTE (@CreateDB);
            PRINT N'Database "'+@DatabaseName+N'" Created';

            ---- Perform any security stuff here:
            --IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'')
            --CREATE USER [] FOR LOGIN [];
            --IF IS_ROLEMEMBER(N'db_datareader',N'') != 1
            --ALTER ROLE [db_datareader] ADD MEMBER [];
            --PRINT N'Security principals created/applied';

            -- Change the owner of the DB now that it has been created and security applied:
            EXECUTE (N'ALTER AUTHORIZATION ON DATABASE::'+@DatabaseName+N' TO sa;');
            PRINT N'Owner/Authorization of "'+@DatabaseName+N'" updated to "sa".';
        END TRY
	    BEGIN CATCH
		    SELECT  @ErrorMessage  = ERROR_MESSAGE()
                   ,@ErrorSeverity = ERROR_SEVERITY()
                   ,@ErrorState    = ERROR_STATE()
                   ,@ErrorNumber   = ERROR_NUMBER();

            PRINT N'Database Creation Error Occurred!';
            PRINT N' *** Error Number: '+CONVERT(nvarchar(20),@ErrorNumber);
            PRINT N' *** Error Message: '+@ErrorMessage;

            RAISERROR ( @ErrorMessage
                       ,@ErrorSeverity
                       ,@ErrorState
                       ) WITH NOWAIT;
            
            GOTO DBNotCreated;
	    END CATCH;
    END;
    ELSE
    BEGIN
        PRINT N'';
        PRINT N'***********************************************************************';
        PRINT N'Database CANNOT be created!';
        PRINT N' *** The default data file or log file location was not found!';
        PRINT N' **** Default Data File location found: '+ISNULL(@DefMdf,N'NULL');
        PRINT N' **** Default Log File location found: '+ISNULL(@DefLog,N'NULL');
        PRINT N'***********************************************************************';
        PRINT N'';
        GOTO DBNotCreated;
    END;
END;
GOTO EndScript;

DBNotCreated:
PRINT N'';
PRINT N'There were some errors or script issues encountered; please see any previous messages for details.';

EndScript:
GO
