@echo off
setlocal ENABLEDELAYEDEXPANSION

REM This script file is to be placed in the game directory of Steel Fury - Kharkov 1942
REM together with the tankid.csv database file
REM Default is to work with Firing Ground Mission
REM other .engscr files can be processed by drag and drop onto this batch file
REM 
REM A back up of the very first original is made in the same directory as the changed file
REM with _original.bak appended to the file name
REM
REM version 02 (2022-02-19)

set script_path=%~dp0
set database=%script_path%tankid.csv

REM make sure database file is available
if NOT EXIST "%database%" (
	echo.
	echo Database file missing.
	echo Please make sure the tankid.csv file is in the same directory as the batch file.
	echo.

	goto setError
)

REM ============ Set default script file to process ============

REM Firing Ground Mission in JCM
if EXIST "!script_path!data\k42\loc_rus\levels\LEVELS\SCRIPTS\cm_pack_mission10\Firing ground_scripts.engscr" (
	set "target_script=!script_path!data\k42\loc_rus\levels\LEVELS\SCRIPTS\cm_pack_mission10\Firing ground_scripts.engscr"
	goto :_test_for_dropped_file
	) 

REM Firing Ground Mission in ITM
if EXIST "!script_path!data\k42\loc_rus\levels\LEVELS\SCRIPTS\cm_teach\Firing ground_scripts.engscr" (
	set "target_script=!script_path!data\k42\loc_rus\levels\LEVELS\SCRIPTS\cm_teach\Firing ground_scripts.engscr"
	goto :_test_for_dropped_file
	) 

REM ============ End Set default script file ============

:_test_for_dropped_file

if [%1]==[] (
	REM No file dropped, use default
	REM Default file to process is the Tank Gunnery Range mod

	set "textFile=!target_script!"

	REM First order is to make sure that file exists
	if EXIST "!textFile!" (
		goto MAIN
	) else (
		echo.
		echo No file dropped and default Firing Ground mission not found.
		echo.
		echo Usage:
		echo    Drop file with .engscr extension on this batch file to switch
		echo       vehicle or platoon scripted for player.
		echo.

		goto setError
	)
) else (
	REM assign dropped file to textFile after checking extension
	REM only allow .engscr files
	if [%~x1]==[.engscr] (
		set "textFile=%~f1"
	) else (
		echo.
		echo File Dropped: "%~f1"
		echo.
		echo  Works only on files with .engscr extension. Aborting.
		echo.

		goto setError
	)
)

:MAIN

call :FIND_CURRENT_TANK_INFO

:INPUT_OR_USE_MENU

REM User to choose to input tank ingame code directly or go through menus to select tank
REM Warn user of game crash if tank code does not exist in game

REM show Mission Name

FOR %%N IN ("!textFile!") DO SET "mission=%%~nN"
set mission=!mission:_= !
set mission=!mission:scripts=mission!
echo.
call :UCase mission

REM show current tank unit
if [!Current_Tank_Unit!]==[] (
	set "Current_Tank_Unit=!Current_Tank_ID!"
	)
echo.Scripted Player Unit: [4m!Current_Tank_Unit! [0m
echo.
echo The batch file facilitates substitution of mission player unit through menu selection
echo   or manual entry of an in-game unit code. Manual entry allows use of platoons/tanks 
echo   missing in the attached database. Works only if missions are not packed and scripts
echo   readable, e.g. in JCM, STA or ITM.
echo.
echo Any selection or entry is substituted as typed into the dropped .engscr file, or, 
echo   the default mission Firing Ground. Whether there is such a unit as you entered in  
echo   activated mods is not checked. Be warned^^! The mission may crash if you choose
echo   or enter a non-existent unit code, or, if mission specific requirements are not
echo   met by the new unit chosen, e.g. a single tank chosen when the mission is 
echo   scripted for platoons and infantry.
echo. 
echo A back up is saved in the same directory the very first time you run the batch file
echo   on a .engscr mission script file. You can restore the original by
echo   1. by running the batch file again and choose restore (for default mission)
echo   2. or, drop the changed .engscr (not the back up file) from the mission script  
echo      directory onto the batch file.
echo   [4mThe restore option will only appear below if a backup is found.[0m
echo.

REM if a backup file is found, offer option to restore
IF EXIST "!textFile!_original.bak" (
	echo.
	echo [96mRestore backup - press[0m R
)

echo.
echo [96mType in in-game tank code (e.g. [0mwer_mtank1[96m) or leave empty to pick from menu[0m
echo.

REM clear variable Z to prepare for user input
set "Z="
REM request user input
SET /P Z=Make Choice, then press ENTER: 
cls

REM if user simply pressed return, assume choice is menu
IF not defined Z set "Z=0"

REM user chose the restore option
IF /I "%Z%"=="R" (
	IF EXIST "!textFile!_original.bak" (
		move /y "!textFile!_original.bak" "!textFile!"
		echo.
		echo [96mRestored^^![0m Press any key to exit.
		pause >nul
	)
	goto :_end_program
)

REM user chose the menu option
if /I "%Z%"=="0" (
	goto :RESTART
) else (
	REM assume manual entry is a valid code if it is more than 7 characters
	REM by testing if an 8th char is present. If not, message and exit
	if defined Z if "%Z:~7,1%"=="" (
		echo.
		echo Entered: %Z%
		echo In-game vehicle code has 8 characters or more.
		echo.
		echo Press any key to restart.
		pause >nul
		goto :INPUT_OR_USE_MENU
		)
	set Chosen_TANK_GAMEID=%Z%
	goto :WRITE_CHANGE
)


:RESTART

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

REM ================ Debug ==================
REM echo.
REM echo index=%index%
REM echo match=%match%
REM echo Country[0]=%Country%[0]
REM echo Chosen_COUNTRY=%Chosen_COUNTRY%
REM echo.
REM ================ Debug ==================
	REM reset errorlevel
	ver > nul

call :CREATE_MENU COUNTRY !index! "[96mChoose Country:[0m"

REM ================ Debug ==================
REM echo.
REM echo Errorlevel=%errorlevel%
REM echo.
REM ================ Debug ==================

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
					if NOT [%%q]==[dummy] (
					set /a TankSeries_match=1
					)
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
call :CREATE_MENU TANK_SERIES !TankSeries_index! "[96mChoose Tank Series:[0m" COUNTRY_SELECT
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
			if NOT [%%W]==[dummy] (
			set TANK_MODEL[!TankModel_index!]=%%X
			set /a TankModel_index+=1
			)
		)
	)
)
set /a TankModel_index-=1

:TANK_MODEL_SELECT
REM echo TankModels Index: !TankModel_index!
call :CREATE_MENU TANK_MODEL !TankModel_index! "[96mChoose Tank Model:[0m" TANK_SERIES_SELECT

if %errorlevel% GTR 0 (
	REM reset errorlevel
	ver > nul
	cls
	goto :TANK_MODEL_SELECT
) else (
	REM echo TANK MODEL: !RETURN_CHOICE!
	set Chosen_TANK_MODEL=!RETURN_CHOICE!
)

REM ********* Get Tank Game ID *********

for /F "usebackq tokens=1,2,3,4 delims=," %%R in ("%database%") do (
	REM only process items if token 1 & 2 matches
	if %%R==!Chosen_COUNTRY! (
		if %%S==!Chosen_TANK_SERIES! (
			if %%T==!chosen_TANK_MODEL! (
				REM echo New Tank Selected: !Chosen_%passed_array.name%! - %%U
				echo.ORIGINAL PLAYER UNIT: !Current_Tank_Unit!
				echo.NEW UNIT SELECTED   : !Chosen_TANK_MODEL! - %%U
				set Chosen_TANK_GAMEID=%%U
			)
		)
	)
)

:WRITE_CHANGE
REM ********* Change Tank in Tank Gunnery Range_scripts.engscr *********
REM call :FIND_REPLACE !Chosen_TANK_GAMEID!
call :REPLACE_WITH_SELECTION !Chosen_TANK_GAMEID!

goto END_MAIN

REM ********* FUNCTIONS *********
:FIND_CURRENT_TANK_INFO

	set marker=user_human(){

    for /f "delims=" %%i in ('type "!textFile!"') do (
        set "line=%%i"

		REM now that we have the platoon name, look for the platoon_name in another line
		if NOT [!player_platoon!]==[] (
			REM if player platoon already known, find the tank used for this platoon 
			for /f "tokens=1,2 delims=," %%Y in ("!line!") do (
				set line_item1=%%Y
				set line_item1=!line_item1:	=!
				REM extract current tank id
				if [!line_item1!]==[!player_platoon!] (
					set my_tank_id=%%Z
					REM echo.My Tank ID: !my_tank_id!
					call :LOOKUP_TANK_NAME_BY_ID !my_tank_id!
					goto :eof
				)
			)
		)

		REM look for user_human line and extract platoon name
		for /f "tokens=1 delims=:" %%z in ('echo %%i ^| findstr /R /C:".*%marker%.*"') do (
			REM return platoon
			set "platoon_line=%%z"
			REM strip the front marker "user_human(){"
			call set platoon_line=%%platoon_line:!!marker!!=%%
			for /f "delims=:" %%B in ("!platoon_line!") do call set player_platoon=%%B
		)
    )
goto :eof	

:REPLACE_WITH_SELECTION

    set "replace=%1"
	set marker=user_human(){
	set /a counter=1

	set "temp_file=!textFile!.temp"

    for /f "delims=" %%i in ('type "!textFile!" ^& break ^> "!temp_file!" ') do (
        set "line=%%i"

		REM now that we have the platoon name, look for the platoon_name in another line
		if NOT [!player_platoon!]==[] (
			REM echo I am in the loop! 
			for /f "tokens=1,2 delims=," %%Y in ("!line!") do (
				set line_item1=%%Y
				set line_item1=!line_item1:	=!
				REM extract current tank id
				if [!line_item1!]==[!player_platoon!] (
					echo.
					echo.ORIGINAL  :!line!
					set line=!line:%%Z= %replace%!
					set "player_platoon="
					echo.CHANGED TO:!line!
					echo.
				)
			)
		)

        >>"!temp_file!" echo !line!
		set /a counter=!counter!+1
    )

goto :eof

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
						set "Current_Tank_ID=%%Q"
						echo.%%Q : !Current_Tank_ID!
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
		set "Current_Tank_Unit=%%c - %1 ^(platoon id = !player_platoon!^)"
	)
)
if [!current_tank_name!]==[] (
	set "Current_Tank_Unit=%1 ^(platoon id = !player_platoon!^)"
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
SET "_Lib_UCase_Tmp=!%1!"
IF /I "%0"==":UCase" SET _Abet=%_UCase%
IF /I "%0"==":LCase" SET _Abet=%_LCase%
FOR %%Z IN (%_Abet%) DO SET "_Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!"
echo.[101;93m %_Lib_UCase_Tmp% [0m
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

FOR %%N IN ("!textFile!") DO SET "mission=%%~nN"
set mission=!mission:_= !
set mission=!mission:scripts=mission!
call :UCase mission
echo.

REM show current tank unit
if [!Current_Tank_Unit!]==[] (
	set "Current_Tank_Unit=!Current_Tank_ID!"
	)
echo.Current Player Unit: !Current_Tank_Unit!
echo.

REM Show the currently selected Country and Tank Series
if NOT [!Chosen_COUNTRY!]==[] (
	set "title_str=!Chosen_COUNTRY! !Chosen_TANK_SERIES!"
	echo.Selected - !title_str!
)
echo.

REM Strip quotes and present message
echo %passed.message:"=%

for /L %%K in (0,1,%passed_array.count%) do (
	if NOT [!%passed_array.name%[%%K]!] == [] (
		if NOT [!%passed_array.name%[%%K]!] == [dummy] (
 		echo %%K: !%passed_array.name%[%%K]!
		)
	)
)
echo.
echo R: Restart
echo X: Exit
set /a limit=%2
echo.
echo Acceptable values 0-!limit!

REM clear variable M to prepare for user input
set "M="
REM request user input
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
echo Invalid Choice^^!

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
echo Aborting! Press key to exit.
pause >nul
Exit /B 5


:END_MAIN

REM back up original file first time to filename_original.bak
REM if filename_original.bak already there, just overwrite

IF NOT EXIST "!textFile!_original.bak" (
	echo.
	echo Backing up to "!textFile!_original.bak" before copying.
	move /y "!textFile!" "!textFile!_original.bak"

)
REM activate the modded file
move /y "!temp_file!" "!textFile!"
echo.
echo Enjoy^^! Press any key to exit.
echo.
pause >nul
endlocal

:_end_program
exit
