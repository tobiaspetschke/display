@echo off
echo lala > lala
SETLOCAL ENABLEDELAYEDEXPANSION
SET UPDFILE=upd.txt
SET URL="q45/"
REM SERIALPORT will contain 0 if no display is found
SET SERIALPORT=0


REM Main start
call :funcDetectDisplay
 REM IF NOT "%SERIALPORT%"=="0" (
	REM We have found a display
	call :funcDownloadAndProcessUpd %URL% %CMDFILE%
 REM	)
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
		call :funcSendDisplayCmd gdi
		IF ERRORLEVEL 0 goto :DisplayFound
		)
:NoDisplayFound
SET SERIALPORT=0
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
        REM call :funcBackupUpdFile
    )
goto :eof


:funcProcessUpdFile
    SET /p IMGFILE=<%UPDFILE%
    SET LAST_IMGFILE=""
    IF EXIST last_%UPDFILE% SET /p LAST_IMGFILE=<last_%UPDFILE%
    IF NOT "%IMGFILE%"=="%LAST_IMGFILE%" (
        ECHO Downloading new image file
        IF EXIST img\%IMGFILE% DEL img\%IMGFILE%
        WGET --no-cache -P img "%URL%%IMGFILE%"
        IF EXIST img\%IMGFILE% (
            call :funcDisplayImage img\%IMGFILE%
        )
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
