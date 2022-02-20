@echo off

setlocal ENABLEDELAYEDEXPANSION

set /a index=0
set /a match=0
set COUNTRY[0]=""
set TANK_SERIES[0]=""
set TANK_MODEL[0]=""
set Chosen_COUNTRY=""
set Chosen_TANK_SERIES=""
set Chosen_TANK_MODEL=""
set Chosen_TANK_GAMEID=""

for /F "tokens=1 delims=," %%i in (sample.csv) do (
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


for /F "tokens=1-3 delims=," %%p in (sample.csv) do (

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

for /F "tokens=1,2,3 delims=," %%V in (sample.csv) do (
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

for /F "tokens=1,2,3,4 delims=," %%R in (sample.csv) do (
	REM only process items if token 1 & 2 matches
	if %%R==!Chosen_COUNTRY! (
		if %%S==!Chosen_TANK_SERIES! (
			if %%T==!chosen_TANK_MODEL! (
				echo Tank Game ID: %%U
			)
		)
	)
)

goto END_MAIN

REM ********* FUNCTIONS *********

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
	goto :eof
) else (
	REM Parse entry for out-of-range values
	if NOT %M% GEQ %passed_array.count% (
		if NOT %M% LSS 0 (
			set Chosen_%passed_array.name%=!%passed_array.name%[%M%]!
			echo Chosen !Chosen_%passed_array.name%!
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

endlocal


pause

exit /b