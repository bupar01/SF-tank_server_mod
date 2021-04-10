@echo off

setlocal ENABLEDELAYEDEXPANSION

set script_path=%~dp0
set database=!script_path!tankid.csv
set "textFile=Tank Gunnery Range_scripts.engscr"

if [%1]==[] goto MAIN

set "textFile=%~f1"

:MAIN

set /a index=0
set /a match=0
set COUNTRY[0]=""
set TANK_SERIES[0]=""
set TANK_MODEL[0]=""
set Chosen_COUNTRY=""
set Chosen_TANK_SERIES=""
set Chosen_TANK_MODEL=""
set Chosen_TANK_GAMEID=""


for /F "tokens=1 delims=," %%i in (%database%) do (
REM 	@echo !index! - %%i
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

call :CREATE_MENU COUNTRY !index! "Choose Country:"
if %errorlevel% GTR 0 exit /b

REM ********* 2nd level menu *********

set /a TankSeries_index=0
set /a TankSeries_match=0


for /F "tokens=1-3 delims=," %%p in (%database%) do (

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
call :CREATE_MENU TANK_SERIES !TankSeries_index! "Choose Tank Series:"
if %errorlevel% GTR 0 exit /b

REM ********* 3rd level menu *********

set /a TankModel_index=0

for /F "tokens=1,2,3 delims=," %%V in (%database%) do (
	REM only process items if token 1 & 2 matches
	if %%V==!Chosen_COUNTRY! (
		if %%W==!Chosen_TANK_SERIES! (
			set TANK_MODEL[!TankModel_index!]=%%X
			set /a TankModel_index+=1
		)
	)
)
call :CREATE_MENU TANK_MODEL !TankModel_index! "Choose Tank Model:"
if %errorlevel% GTR 0 exit /b

REM ********* Get Tank Game ID *********

for /F "tokens=1,2,3,4 delims=," %%R in (%database%) do (
	REM only process items if token 1 & 2 matches
	if %%R==!Chosen_COUNTRY! (
		if %%S==!Chosen_TANK_SERIES! (
			if %%T==!chosen_TANK_MODEL! (
				echo New Tank Selected: !Chosen_%passed_array.name%! - %%U
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
REM    setlocal enableextensions disabledelayedexpansion

    set "search=new_tank"
    set "replace=%1"
	set marker=user_human(){
set /a counter=1

	set "temp_file=%textFile%.temp"

    for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "%temp_file%" ') do (
        set "line=%%i"

REM echo 8888888888--Counter: !counter! --88888888888
REM echo !line!
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
					)
				)
			)
		)
REM if !counter! EQU 258 echo I am at station 1! -- !line!

		REM look for user_human line and extract platoon name
		for /f "delims=" %%z in ('echo "%%i" ^| findstr /R /C:".*%marker%.*"') do (
			REM return platoon
			set "platoon_line=%%z"
			REM strip the front marker "user_human(){"
			call set platoon_line=%%platoon_line:!!marker!!=%%
			REM echo user_human:!!platoon_line!!
			for /f "delims=:" %%B in ("!platoon_line!") do call set player_platoon=%%B
		)
		
	
	
REM		setlocal enabledelayedexpansion
        REM set "line=!line:%search%=%replace%!"
        >>"%temp_file%" echo !line!
REM        endlocal
		set /a counter=!counter!+1
		REM echo end_counter: !counter!
    )
goto :eof	

:LOOKUP_TANK_NAME_BY_ID
for /F "tokens=3,4 delims=," %%c in (%database%) do (
	REM only process items if token 1 & 2 matches
	if "%%d"=="%1" (
		REM echo %1=%%P:%%c
		set current_tank_name=%%c
		echo Current Tank : %%c - %1
	)
)

goto :eof

:CREATE_MENU
REM Function to create user input menu
REM Parameters: 3
REM Param1: array name
REM Param2: size of array
REM Param3: Message Text

set passed_array.name=%1
set passed_array.count=%2
set passed.message=%3



REM Strip quotes and present message
echo %passed.message:"=%

for /L %%K in (0,1,%passed_array.count%) do (
	if NOT [!%passed_array.name%[%%K]!] == [] (
 		echo %%K: !%passed_array.name%[%%K]!
	)
)
echo X: Exit


SET /P M=Make Choice, then press ENTER:

if /I "%M%"=="X" (
	echo Requested to Exit
	REM pause
	goto setError
) else (
	REM Parse entry for out-of-range values
	if NOT %M% GEQ %passed_array.count% (
		if NOT %M% LSS 0 (
			set Chosen_%passed_array.name%=!%passed_array.name%[%M%]!
			REM echo Chosen !Chosen_%passed_array.name%!
			goto :eof
		)
	)
)
echo Invalid Choice!
goto setError

goto :eof

:setError
Exit /B 5



:END_MAIN

REM echo My platoon: %player_platoon%

move /y "%textFile%" "%textFile%.bak"
move /y "%temp_file%" "%textFile%"
echo Backup file: %textFile%.bak
pause
endlocal
exit /b