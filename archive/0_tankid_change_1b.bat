@echo off
setlocal ENABLEDELAYEDEXPANSION

REM This script file is to be placed in the game directory of Steel Fury - Kharkov 1942
REM together with the tankid.csv database file
REM Default is to work with Tank Gunnery Mod
REM other .engscr files can be processed by drag and drop onto batch file
REM version 01b

set script_path=%~dp0
set database=%script_path%tankid.csv

REM make sure database file is available
if NOT EXIST "%database%" (
	echo Database file missing.
	echo Please make sure the tankid.csv file is in the same directory as the batch file.
	pause
	goto setError
)

if [%1]==[] (
	REM No file dropped, use default
	REM Default file to process is the Tank Gunnery Range mod
	set "textFile=%script_path%data\k42\loc_rus\levels\LEVELS\SCRIPTS\cm_users\Tank Gunnery Range_scripts.engscr"
	echo !textFile!
	REM First order is to make sure that file exists
	if EXIST "!textFile!" (
		goto MAIN
	) else (
		echo No file available to process. Please drop file with .engscr extension on batch file.
		pause
		goto setError
	)
) else (
	REM assign dropped file to textFile after checking extension
	REM only allow .engscr files
	if [%~x1]==[.engscr] (
		set "textFile=%~f1"
	) else (
		echo File Dropped: "%~f1"
		echo.
		echo Should work only on files with .engscr extension. Aborting.
		pause
		goto setError
	)
)

:RESTART

:MAIN

set /a index=0
set /a match=0
set COUNTRY[0]=""

for /F "usebackq tokens=1 delims=," %%i in ("%database%") do (
	if NOT [%%i]==[] (

			for /F "tokens=2 delims==" %%j in ( 'set COUNTRY[' ) do (

				if [%%i] == [%%j] (
					set /a match=1
				)
			)
		if !match! EQU 0 (
			set COUNTRY[!index!]=%%i
			set /a index+=1
		)
		set /a match=0
	)
)
set /a index-=1

:COUNTRY_SELECT
call :CREATE_MENU COUNTRY !index! "Choose Country:"
if %errorlevel% GTR 0 (
	REM reset errorlevel
	ver > nul
	cls
	goto :COUNTRY_SELECT
) else (
	REM echo COUNTRY=!RETURN_CHOICE!
	set Chosen_COUNTRY=!RETURN_CHOICE!
)
REM ********* 2nd level menu *********
set TANK_SERIES[0]=""
set /a TankSeries_index=0
set /a TankSeries_match=0
set "Chosen_TANK_SERIES="

for /F "usebackq tokens=1-3 delims=," %%p in ("%database%") do (

	REM only process items in token 2 if token 1 matches
	if %%p==!Chosen_COUNTRY! (
		for /f "tokens=2 delims==" %%d in ( 'set TANK_SERIES[' ) do (
				if %%q==%%d (
					set /a TankSeries_match=1
				)
		)
		if !TankSeries_match! EQU 0 (
			set TANK_SERIES[!TankSeries_index!]=%%q
			set /a TankSeries_index+=1
		)
		set /a TankSeries_match=0
	)
)
set /a TankSeries_index-=1

:TANK_SERIES_SELECT
REM echo TankSeries Index: !TankSeries_index!
call :CREATE_MENU TANK_SERIES !TankSeries_index! "Choose Tank Series:" COUNTRY_SELECT
if %errorlevel% GTR 0 (
	REM reset errorlevel
	ver > nul
	cls
	goto :TANK_SERIES_SELECT
) else (
	REM echo TANK SERIES: !RETURN_CHOICE!
	set Chosen_TANK_SERIES=!RETURN_CHOICE!
)

REM ********* 3rd level menu *********
set TANK_MODEL[0]=""
set /a TankModel_index=0
set "Chosen_TANK_MODEL="
set Chosen_TANK_GAMEID=""

for /F "usebackq tokens=1,2,3 delims=," %%V in ("%database%") do (
	REM only process items if token 1 & 2 matches
	if %%V==!Chosen_COUNTRY! (
		if %%W==!Chosen_TANK_SERIES! (
			set TANK_MODEL[!TankModel_index!]=%%X
			set /a TankModel_index+=1
		)
	)
)
set /a TankModel_index-=1

:TANK_MODEL_SELECT
REM echo TankModels Index: !TankModel_index!
call :CREATE_MENU TANK_MODEL !TankModel_index! "Choose Tank Model:" TANK_SERIES_SELECT

if %errorlevel% GTR 0 (
	REM reset errorlevel
	ver > nul
	cls
	goto :TANK_MODEL_SELECT
) else (
	echo TANK MODEL: !RETURN_CHOICE!
	set Chosen_TANK_MODEL=!RETURN_CHOICE!
)

REM ********* Get Tank Game ID *********

for /F "usebackq tokens=1,2,3,4 delims=," %%R in ("%database%") do (
	REM only process items if token 1 & 2 matches
	if %%R==!Chosen_COUNTRY! (
		if %%S==!Chosen_TANK_SERIES! (
			if %%T==!chosen_TANK_MODEL! (
				REM echo New Tank Selected: !Chosen_%passed_array.name%! - %%U
				echo New Tank Selected: !Chosen_TANK_MODEL! - %%U
				set Chosen_TANK_GAMEID=%%U
			)
		)
	)
)
REM ********* Change Tank in Tank Gunnery Range_scripts.engscr *********
call :FIND_REPLACE !Chosen_TANK_GAMEID!


goto END_MAIN

REM ********* FUNCTIONS *********
:FIND_REPLACE

    set "search=new_tank"
    set "replace=%1"
	set marker=user_human(){
	set /a counter=1

	set "temp_file=!textFile!.temp"

    for /f "delims=" %%i in ('type "!textFile!" ^& break ^> "!temp_file!" ') do (
        set "line=%%i"

		REM now that we have the platoon name, look for the platoon_name in another line
		if NOT [!player_platoon!]==[] (
			REM echo I am in the loop! 
			for /f "delims=" %%y in ('echo "%%i" ^| findstr /R /C:".*!player_platoon!.*"') do (
				REM extract current tank id
				for /f "tokens=1,2* delims=," %%P in ("%%y") do (
					set platoon=%%P
					set platoon=!platoon:	=!

					if [!platoon!]==[!player_platoon!] (
					call :LOOKUP_TANK_NAME_BY_ID %%Q

					set line=!line:%%Q= %replace%!
					set "player_platoon="
					)
				)
			)
		)

		REM look for user_human line and extract platoon name
		for /f "tokens=1 delims=:" %%z in ('echo "%%i" ^| findstr /R /C:".*%marker%.*"') do (
			REM return platoon
			set "platoon_line=%%z"
			REM strip the front marker "user_human(){"
			call set platoon_line=%%platoon_line:!!marker!!=%%
			for /f "delims=:" %%B in ("!platoon_line!") do call set player_platoon=%%B
		)
		
	
	
        >>"!temp_file!" echo !line!
		set /a counter=!counter!+1
    )
goto :eof	

:LOOKUP_TANK_NAME_BY_ID
for /F "usebackq tokens=3,4 delims=," %%c in ("%database%") do (
	REM only process items if token 1 & 2 matches
	if "%%d"=="%1" (
		set current_tank_name=%%c
		echo.Current Tank : %%c - %1
	)
)

goto :eof

:LCase
:UCase
:: Converts to upper/lower case variable contents
:: Syntax: CALL :UCase _VAR1 _VAR2
:: Syntax: CALL :LCase _VAR1 _VAR2
:: _VAR1 = Variable NAME whose VALUE is to be converted to upper/lower case
:: _VAR2 = NAME of variable to hold the converted value
:: Note: Use variable NAMES in the CALL, not values (pass "by reference")

SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z
SET _Lib_UCase_Tmp=!%1!
IF /I "%0"==":UCase" SET _Abet=%_UCase%
IF /I "%0"==":LCase" SET _Abet=%_LCase%
FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
echo.%_Lib_UCase_Tmp%
GOTO:EOF

:CREATE_MENU
REM Function to create user input menu
REM Parameters: 3
REM Param1: array name
REM Param2: size of array
REM Param3: Message Text


set passed_array.name=%1
set passed_array.count=%2
set passed.message=%3

REM show Mission Name

FOR /F %%N IN ("!textFile!") DO SET mission=%%~nN
set mission=!mission:_= !
set mission=!mission:scripts=mission!
call :UCase mission
echo.
set title_str=!Chosen_COUNTRY! !Chosen_TANK_SERIES!
echo.!title_str!
echo.

REM Strip quotes and present message
echo %passed.message:"=%

for /L %%K in (0,1,%passed_array.count%) do (
	if NOT [!%passed_array.name%[%%K]!] == [] (
 		echo %%K: !%passed_array.name%[%%K]!
	)
)
echo.
echo R: Restart
echo X: Exit
set /a limit=%2
echo.
echo Acceptable values 0-!limit!

SET /P M=Make Choice, then press ENTER:
cls

if /I "%M%"=="X" (
	exit
) else (
	REM Parse entry for out-of-range values
	if NOT %M% GTR %passed_array.count% (
		if NOT %M% LSS 0 (
			set Chosen_%passed_array.name%=!%passed_array.name%[%M%]!
			set RETURN_CHOICE=!%passed_array.name%[%M%]!
			goto :eof
		)
	)
)
REM Restart is pressed
if /I "%M%"=="R" (
	if defined COUNTRY[0] (
		call :CLEAR_ARRAY COUNTRY
	)
	if defined TANK_SERIES[0] (
		call :CLEAR_ARRAY TANK_SERIES
	)
	if defined TANK_MODEL[0] (
		call :CLEAR_ARRAY TANK_MODEL
	)
	set "chosen_COUNTRY="
	set "chosen_TANK_SERIES="
	endlocal
	goto :RESTART

)
echo Invalid Choice!
pause
goto setError

goto:eof

:CLEAR_ARRAY
set array.name=%1
set /a clear_index=0

for /f "delims=[=]" %%a in ('set %array.name%[') do (
	set "%array.name%[!clear_index!]="
	set /a clear_index+=1
)

goto:eof

:setError
Exit /B 5


:END_MAIN

move /y "!textFile!" "!textFile!.bak"
move /y "!temp_file!" "!textFile!"
echo Backup file: !textFile!.bak
pause
endlocal

:_end_program
exit
