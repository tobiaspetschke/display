@echo off
echo Script started at %time%
SETLOCAL ENABLEDELAYEDEXPANSION
SET UPDFILE=upd.txt
SET URL="q45:8000/"
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
    IF          "%COMMAND%"=="CLEAR" (
        ECHO Clearing img folder and backup file
        del /F /S /Q img
    ) ELSE IF   "%COMMAND%"=="UPDATE" (
        call :funcUpdateScript
    ) ELSE (
        REM Not a command so must be an image update
        call :funcDownloadAndUpdateNewImage
    )
goto :eof


:funcDownloadAndUpdateNewImage
echo Image update
SET LAST_IMGFILE=""
SET NEW_IMGFILE=""
SET /p NEW_IMGFILE=<%UPDFILE%
IF EXIST last_%UPDFILE% SET /P LAST_IMGFILE=<last_%UPDFILE%
IF NOT "%NEW_IMGFILE%"=="%LAST_IMGFILE%" (
    echo Downloading new image %NEW_IMGFILE%
    IF EXIST img\%NEW_IMGFILE% DEL img\%NEW_IMGFILE%
    WGET --no-cache -P img "%URL%%NEW_IMGFILE%"
    IF EXIST img\%NEW_IMGFILE% (
        call :funcDisplayImage img\%NEW_IMGFILE%
    )
) ELSE echo Ignoring new image as it is the same as the last one
goto :eof

:funcUpdateScript
echo Updating script
SET SCRIPT=Update.cmd
SET NEWSCRIPT=Update.new
IF EXIST %NEWSCRIPT% DEL /F /Q %NEWSCRIPT%
wget --no-cache -O %NEWSCRIPT% "%URL%%Script%"
IF EXIST %NEWSCRIPT% (
    DEL /F /Q %SCRIPT% && RENAME %NEWSCRIPT% %SCRIPT% && EXIT
)
goto :eof

:funcDisplayImage
     SET "IMGFILE=%~1"
     echo Displaying file %IMGFILE%
     call :funcSendDisplayCmd "i %IMGFILE% 0 l a 0 di 0"
     IF NOT "%ERRORLEVEL%"=="0" echo Could not download image into display
goto :eof


:funcBackupUpdFile
     IF EXIST %UPDFILE% (
         SET LAST_UPDFILE=last_%UPDFILE%
		 IF EXIST !LAST_UPDFILE! DEL !LAST_UPDFILE!
         RENAME !UPDFILE! !LAST_UPDFILE!
     )
goto :eof
