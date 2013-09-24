@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET UPDFILE=upd.txt
SET URL="127.0.0.1:90/"
REM SERIALPORT will contain 0 if no display is found
SET SERIALPORT=0

REM Main start
call :funcDetectDisplay
    IF NOT "%SERIALPORT%"=="0" (
	REM We have found a display
	call :funcDownloadAndProcessUpd %URL% %CMDFILE%
    )
goto :eof
REM Main end

REM The caller must check %ERRORLEVEL% afterwards
:funcSendDisplayCmd 
	SET "CMD=%~1"
	SET zbdcontrol=//nologo RunQuietly.vbs "zbdcontrol -D 0 -Q -s %SERIALPORT% %CMD%"
	cscript %zbdcontrol%
goto :eof

REM This will set SERIALPORT to nonzero if display is found
:funcDetectDisplay
	SET SERIALPORT=0
	for /f "tokens=4" %%A in ('mode^|findstr "COM.*:"') do (
		SET PORT=%%A
		SET PORT=!PORT::=! 
		SET PORT=!PORT:COM=! 
		SET SERIALPORT=!PORT!
		call :funcSendDisplayCmd v
        call :funcSendDisplayCmd v
		IF ERRORLEVEL 0 goto :DisplayFound
		)
:NoDisplayFound
SET SERIALPORT=0
Echo No Display found
goto :eof
:DisplayFound
ECHO Display found on com port %SERIALPORT%
goto :eof


:funcDownloadAndProcessUpd
    Echo Downloading update file
    IF EXIST %UPDFILE% DEL /Q %UPDFILE%
    WGET --no-cache "%URL%%UPDFILE%"
    IF "%ERRORLEVEL%"=="0" (
        call :funcProcessUpdFile
        call :funcBackupUpdFile
    )
goto :eof


:funcProcessUpdFile
    SET /p COMMAND=<%UPDFILE%
    IF  "%COMMAND%"=="CLEAR" (
        ECHO Clearing img folder and backup file
        del /F /S /Q img
        IF EXIST last_%UPDFILE% DEL last_%UPDFILE%
    ) ELSE IF   "%COMMAND%"=="UPDATE" (
        echo Updating script
        del /F /S /Q Update.cmd
        WGET --no-cache "%URL%Update.cmd"
        goto :eof
    ) ELSE (
        echo Image command
        SET NEW_IMGFILE=%COMMAND%
        SET LAST_IMGFILE=""
        IF EXIST last_%UPDFILE% SET /P LAST_IMGFILE=<last_%UPDFILE%
        IF NOT !NEW_IMGFILE!==!LAST_IMGFILE! (
            echo Downloading new image
            IF EXIST img\!NEW_IMGFILE! DEL img\!NEW_IMGFILE!
            WGET --no-cache -P img "!URL!!NEW_IMGFILE!"
            IF EXIST img\!NEW_IMGFILE! (
                call :funcDisplayImage img\!NEW_IMGFILE!
            )
        ) ELSE echo Ignoring new image as it is the same as the last one
    )
goto :eof

:funcDisplayImage
     SET "IMGFILE=%~1"
     echo Displaying file %IMGFILE%
     call :funcSendDisplayCmd "i %IMGFILE% 0 l a" 
	 call :funcSendDisplayCmd "di 0"
goto :eof


:funcBackupUpdFile
     IF EXIST %UPDFILE% (
         SET LAST_UPDFILE=last_%UPDFILE%
		 IF EXIST !LAST_UPDFILE! DEL !LAST_UPDFILE!
         RENAME !UPDFILE! !LAST_UPDFILE!
     )
goto :eof
