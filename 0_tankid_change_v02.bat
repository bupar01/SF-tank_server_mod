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
REM version 02a (2022-02-21)

goto :PRE-CHECK

REM ==== ******************* ====
REM ====   Functions Block   ====

:_wrap_and_echo

REM Auto wrap according to command prompt windows width
REM Command prompt windows width obtained from formula below placed
REM in start up part of this program 
REM
REM Limitations: can only deal with straight text and not color escape codes

SET "str_to_wrap=%1"

rem Read the file given by first param and show its contents with no word split
set "firstline=true"
set "output="
rem For each line in input file
for /F "delims=" %%a in (!str_to_wrap!) do (
   rem For each word in input line
   for %%b in (%%a) do (
      rem Add the new word
      set "newOutput=!output! %%b"
      rem If new word don't exceed window width
      if "!newOutput:~%width%,1!" equ "" (
         rem Keep it
         set "output=!newOutput!"
      ) else (
         rem Show the output before the new word
		 if !firstline! EQU true (
			echo.!output:~1!
			set "firstline="
		 ) else (
			echo.!output!
		 )
         rem and store the new word
         set "output=%%b"
      )
   )
)
rem Show the last output, if any
if defined output echo.!output!

goto :eof

:SHOW_ARRAY
	REM ===============*** Added 2022-03-02 ***================
	REM Pass in an array and echo to output
	SETLOCAL
	REM SET Arr=%1
	SET /A x=0
	
	REM ECHO.
	:SymLoop
	IF defined %~1[%x%] (
		REM ECHO %x% - !%~1[%x%]!
		SET /A x+=1
		GOTO :SymLoop
	) 
	REM ECHO.
	ENDLOCAL
goto:eof


:SHOW_2D_ARRAY
	REM ===============*** Added 2022-03-03 ***================
	REM Pass in a global 2D array name and echo items to output
	SETLOCAL
	SET /A x=0
	SET /A y=0

	:SymLoop2D
	IF defined %~1[%x%][%y%] (
		REM ECHO Array element %x% defined
		:SymLoop2
		IF DEFINED %~1[%x%][%y%] (
			REM ECHO %x%.%y% - !%~1[%x%][%y%]!
			SET /A y+=1
			GOTO :SymLoop2
		)
		SET /A y=0
		SET /A x+=1
		GOTO :SymLoop2D
	) 
	REM ECHO.
	ENDLOCAL
goto:eof

:CREATE_POINTS_ARRAY
	REM ===============*** Added 2022-03-03 ***================
	REM Pass in zone definition line in parameter 1 
	REM and put all set contour points into an array
	REM Return array in parameter 2
	REM Return array size in parameter 3
	REM ECHO.
	REM ECHO Split points into array...
	REM strip last semi-colon
	SET var1=%~1
	SET var1=!var1:;=!
	
	REM Put array name into variable to pass into function
	SET var2=%~2
	
	REM Initialize array counter
	SET /A x=0
	REM Initialize points counter
	SET /A y=0
	REM Initialize point elements counter
	SET /A z=0
	
	for /F "tokens=8* delims=," %%p in ( "!var1!" ) do (
		SET "points_str=%%q"
	)
	REM echo points_str: %points_str%
	
	CALL :parse_points "!points_str!"
	goto :end_of_parse_points
	
	
	:parse_points
		REM strip quotes
		SET var1=%~1
		REM ECHO cc!var1!cc
		for /F "tokens=1* delims=," %%a in ( "!var1!" ) do (
			REM ECHO xx%%axx
			SET tmp_str=%%a
			REM first char which is either a tab or space in the contour definition
			SET %var2%[%y%][%z%]=!tmp_str:~1!
			REM ECHO %x% - !%var2%[%y%][%z%]!
			SET /A x+=1
			SET /A z+=1
			IF "!z!"=="4" (
				SET /A z=0
				SET /A y+=1
			)
			REM ECHO %var2% - %x% - %y% - %z%
			IF NOT [%%b]==[] (
				REM ECHO %%b
				CALL :parse_points "%%b"
			)
		)
	goto:eof
	
	:end_of_parse_points
	REM ECHO Number of points in contour - %y%
	REM Return array size in parameter 3
	SET /A %~3=%y%

goto:eof


:CREATE_CONTOUR_ARRAY
	REM ===============*** Added 2022-03-02 ***================
	REM Pass in zone definition line in parameter 1 
	REM and put all items into an array
	REM Return array in parameter 2
	REM Return array size in parameter 3

	REM strip last semi-colon
	SET var1=%~1
	REM SET var1=!var1:;=!
	REM Put array name into variable to pass into function
	SET var2=%~2
	
	SET /A x=0
	
	CALL :parse_contour "!var1!"
	goto :end_of_parse_contour
	
	:parse_contour
	REM strip quotes
	SET var1=%~1

	for /F "tokens=1* delims=,;" %%a in ( "!var1!" ) do (
		SET tmp_str=%%a
		REM first char which is either a tab or space in the contour definition
		SET %var2%[%x%]=!tmp_str:~1!
		REM ECHO xx!%var2%[%x%]!xx
		SET /A x+=1
		IF NOT [%%b]==[] (
			CALL :parse_contour "%%b"
		)
	)
	GOTO:eof
	REM ******* End of parse_contour function ********
	:end_of_parse_contour

	REM Return array size in parameter 3
	SET /A %~3=%x%
	
goto:eof


:RETRIEVE_ZONE_INFO
	REM ===============*** Added 2022-03-01 ***================
	REM assume assigned_contour already set and identifies player's starting contour
	REM assume zones_file_full_path already set
	REM goal: get the zone coordinates
	REM       assign them to !zoneX!, !zoneY!
	REM       get number of set points in zone and place in number_of_zone_points
	
	REM echo zone: xx%assigned_contour%xx
	SET "marker=%assigned_contour%"
	REM echo marker: xx%marker%xx

	REM get each line and parse for user assigned zone
	for /f "delims=" %%f in ('type "!zones_file_full_path!"') do (
        set "any_line=%%f"
		
		REM find the line containing the marker which is the user assigned contour
		for /f "tokens=1 delims=," %%A in ('echo %%f ^| findstr /R /C:".*%marker%.*"') do (
			REM echo "%marker%" - "%%A"
			REM echo coordinate-x: "%%B"
			SET "zone_definition=!any_line!"
			
			REM Now count how many items/tokens are in this line
			set i=0
			SET var1=!any_line!
			REM ECHO !var1!
			:loopprocess
			for /F "tokens=1*" %%A in ( "!var1!" ) do (
			  set /A i+=1
			  set var1=%%B
			  goto loopprocess )
			REM echo The string contains %i% tokens.
			REM Extract the x and y coordinates of the contour
			REM zoneX is token 7, zoneY is token 8
			
			for /f "tokens=7,8,12 delims=," %%L in ( "!any_line!" ) do (
				CALL :DROP_DECIMAL "%%L" "zoneX"
				REM SET /A zoneX=%%L
				REM ECHO %%L
				REM pause
				CALL :DROP_DECIMAL "%%M" "zoneY"
				REM SET /A zoneY=%%M
				REM ECHO %%M
				REM pause
				CALL :DROP_DECIMAL "%%N" "azimuth"
				REM echo !azimuth!
				REM pause
			)
			REM each zone point has 4 comma separated numbers beginning from the 9th position
			REM to get the number of set points, count how many numbers after the 8th position
			REM and then divide by 4
			REM with the start and end points, there should be at least 2 points
			SET /A number_of_zone_points=%i%-8
			SET /A number_of_zone_points/=4
			REM echo coodinates: !zoneX!, !zoneY!, !azimuth!
			REM echo number of set points: %number_of_zone_points%
		
			REM ECHO !any_line!
			CALL :CREATE_CONTOUR_ARRAY "!any_line!" "Contour_Array" "Contour_Array_Count"
			CALL :SHOW_ARRAY "Contour_Array"
			REM ECHO Contour_Array_Count: !Contour_Array_Count!

			CALL :CREATE_POINTS_ARRAY "!any_line!" "Contour_Points_Array" "Contour_Points_Array_Count"
			REM ECHO Returned from Create Points Array
			REM ECHO items count: %Contour_Points_Array_Count%
			CALL :SHOW_2D_ARRAY "Contour_Points_Array"
			REM ECHO Returned from SHOW_2D_ARRAY
			REM PAUSE
			
			REM Can ignore the rest of the file once the assigned zone info retrieved
			goto:eof
		)
	)
goto :eof	

:READ_FILE_AND_REPLACE
	REM takes 3 parameters
	REM Parameter 1: File to read
	REM Parameter 2: Marker for target line
	REM Parameter 3: Replacement line
	REM Parameter 4: Output File
	
	REM ECHO.
	REM ECHO TARGET: %~1
	REM ECHO MARKER: %~2
	REM ECHO REPLACEMENT: %~3
	REM ECHO.
	
	SET "search_str=%~2"
	
	REM Delete temp file if already exists

	IF EXIST "%~4" (
		del /Q "%~4"
	)
	
	REM read each line and copy to temp file if search_str not found

    for /f "delims=" %%i in ('type "%~1" ^& break ^> "%~4" ') do (
        set "current_line=%%i"

		REM now that we have the zone name, look for the zone name in another line
		if NOT [!current_line!]==[!current_line:%search_str%=!] (
			REM search_str found in line! 
			>>"%~4" echo %~3
		) ELSE (
			>>"%~4" echo !current_line!
		)
    )
	REM ECHO finished replace
	REM pause

goto :eof

:EXPAND_CONTOUR
	REM User has chosen a platoon and the starting contour needs to be expanded to 
	REM accomodate all the units
	
	REM default is 150 units length and 20 units deep for 3 units platoons
	REM simple strategy is to add 4 points to the zone equal distance from the 
	REM zone center coordinates (zoneX, zoneY) obtained above
	
	SET /A points1X=%zoneX%-75
	SET /A points1Y=%zoneY%-10
	SET /A points2X=%zoneX%-75
	SET /A points2Y=%zoneY%+10
	SET /A points3X=%zoneX%+75
	SET /A points3Y=%zoneY%+10
	SET /A points4X=%zoneX%+75
	SET /A points4Y=%zoneY%-10
	
	SET points_str=, %points1X%, 0, %points1Y%, !azimuth!, %points2X%, 0, %points2Y%, !azimuth!, %points3X%, 0, %points3Y%, !azimuth!, %points4X%, 0, %points4Y%, !azimuth!
	SET "expanded_user_contour=!zone_definition:~0,-1!%points_str%;"
	
	REM ECHO Original zone line: !zone_definition!
	REM ECHO New zone definition: !expanded_user_contour!
	
	REM write new temporary zone file, replacing the assigned zone line
	CALL :READ_FILE_AND_REPLACE "!zones_file_full_path!" "%assigned_contour%" "!expanded_user_contour!" "!zones_file_full_path!.temp"

	REM Back up original and replace with temporary file
	IF NOT EXIST "!zones_file_full_path!_original.bak" (
		move /y "!zones_file_full_path!" "!zones_file_full_path!_original.bak" 1>nul
		REM ECHO Zone file backed up.
	)
	move /y "!zones_file_full_path!.temp" "!zones_file_full_path!" 1>nul
	REM ECHO Zone file changed.

goto :eof	


:FIND_CURRENT_TANK_INFO

	set marker=user_human(){

    for /f "delims=" %%i in ('type "!textFile!"') do (
        set "line=%%i"

		REM now that we have the platoon name, look for the platoon_name in another line
		if NOT [!player_platoon!]==[] (
			REM if player platoon already known, find the tank used for this platoon 
			for /f "tokens=1,2,3 delims=," %%X in ("!line!") do (
				set line_item1=%%X
				set line_item1=!line_item1:	=!
				REM extract current tank id
				if [!line_item1!]==[!player_platoon!] (
					set my_tank_id=%%Y
					REM echo.My Tank ID: !my_tank_id!
					call :LOOKUP_TANK_NAME_BY_ID !my_tank_id!
					REM ===============*** Added 2022-03-01 ***================
					REM get assigned contour zone
					set assigned_contour=%%Z
					REM strip space
					SET assigned_contour=!assigned_contour: =!
					
					REM necessary data acquired, exit function
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

IF !colored_text! EQU true (
	echo [101;93m %_Lib_UCase_Tmp% [0m
) ELSE (
	echo %_Lib_UCase_Tmp%
)
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


:_GET_PATH
REM extract path from parameter 1, a quoted string
REM return result path in a unquoted string 

SET %~2=%~dp1

goto:eof

:_GET_FILENAME_FROM_PATH
REM extract file name from quoted FULL path in parameter 1
REM return unquoted filename (without extension) in parameter 2

SET %~2=%~n1
goto:eof

:_GET_MISSION_FILE_STEM
REM extract mission file name stem from script file name
REM from parameter 1 return result in parameter 2 (unquoted)

SET raw_name=%~1
REM echo raw_name: %raw_name%
REM echo stripped: %raw_name:_scripts=%
REM pause
SET %~2=%raw_name:_scripts=%
goto:eof

:RESTORE_ORIGINAL_BACKUP
	REM Parameter 1: target file name
	REM Parameter 2: backup file specific string and extension
	
	IF EXIST "%~1%~2" (
		move /y "%~1%~2" "%~1" 1>nul
	)

goto :eof

:DROP_DECIMAL
	REM function to drop decimal portion of string
	REM parameter 1: string containing decimal
	REM parameter 2: return integer variable
	
	for /f "tokens=1,2 delims=." %%a in ( "%~1" ) do (
		set /A %~2=%%a
	)
goto :eof

REM ==== End Functions Block ====
REM ==== ******************* ====

:PRE-CHECK

REM *** get_command_window_width ***

for /f "tokens=2" %%A in ('mode con ^| find "Columns"') do set /A "width=%%A-1"


REM *** test if Windows version is 10 or above ***

REM undefine variable
SET "WINDOWS_VERSION="
REM find out which version of windows OS to determine if color text is supported
REM for /f "tokens=4-5 delims=. " %%i in ('ver') do set WINDOWS_VERSION=%%i.%%j
for /f "tokens=4-5 delims=. " %%i in ('ver') do set WINDOWS_VERSION=%%i
SET /A WINDOWS_VERSION=%WINDOWS_VERSION%
REM echo Windows %WINDOWS_VERSION%
IF %WINDOWS_VERSION% GEQ 10 (
	SET "colored_text=true"
)
REM echo colored: !colored_text!
REM pause

REM =======*** Set Paths to batch file and database ***=======

set script_path=%~dp0
set database=%script_path%tankid.csv

REM *** make sure database file is available ***

if NOT EXIST "%database%" (
	echo.
	echo Database file missing.
	call :_wrap_and_echo "Please make sure the tankid.csv file is in the same directory as the batch file."
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
		call :_wrap_and_echo "No file dropped and default Firing Ground mission not found."
		echo.
		echo Usage:
		call :_wrap_and_echo "Drop file with .engscr extension on this batch file to switch  vehicle or platoon scripted for player."
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
		call :_wrap_and_echo "Works only on files with .engscr extension. Aborting."
		echo.

		goto setError
	)
)

goto :MAIN


:MAIN

REM ===========**** Added 2022-02-28 ****===========

REM **** set up mission file variables ****

REM get path to mission script folder

CALL :_GET_PATH "!textFile!" mission_path
CALL :_GET_FILENAME_FROM_PATH "!textFile!" mission_script
CALL :_GET_MISSION_FILE_STEM "%mission_script%" mission_file_stem

REM ECHO Returned: %mission_path%
REM ECHO Mission script: %mission_script%
REM ECHO Mission filename stem: %mission_file_stem%

REM Compose zones file path & See if zone file exist

SET  zones_file_full_path=%mission_path%%mission_file_stem%_zones.engcfg
REM ECHO %zones_file_full_path%

REM see if a zone file back up is present and restore it
CALL :RESTORE_ORIGINAL_BACKUP "%zones_file_full_path%" "_original.bak"

IF NOT EXIST "%zones_file_full_path%" (
	ECHO ***Error: zones file not found! Aborting!
	ECHO.
	GOTO setError
)

REM see if a script file back up is present and restore it
CALL :RESTORE_ORIGINAL_BACKUP "!textFile!" "_original.bak"

call :FIND_CURRENT_TANK_INFO

CALL :RETRIEVE_ZONE_INFO

REM ECHO Completed retrieval of zone info
REM PAUSE

:INPUT_OR_USE_MENU

REM User to choose to input tank ingame code directly or go through menus to select tank
REM Warn user of game crash if tank code does not exist in game

REM show Mission Name

REM pause
FOR %%N IN ("!textFile!") DO SET "mission=%%~nN"

REM pause
set mission=!mission:_= !

REM pause
set mission=!mission:scripts=mission!

call :UCase mission

REM show current tank unit
if [!Current_Tank_Unit!]==[] (
	set "Current_Tank_Unit=!Current_Tank_ID!"
)
REM IF NOT [!my_tank_id:_platoon_=!]==[!my_tank_id!] (
	REM SET "affirmative="
REM ) ELSE (
	REM SET "affirmative=not "
REM )

IF !colored_text! EQU true (
	echo.Current Unit: [4m !Current_Tank_Unit! [0m
) ELSE (
	echo.Current Unit: !Current_Tank_Unit!
)

IF !colored_text! EQU true (
	echo [96m-------------------------[0m
) ELSE (
	echo -------------------------
)
call :_wrap_and_echo "The batch file facilitates substitution of mission player unit through menu selection or manual entry of an in-game unit code. Manual entry allows use of platoons/tanks missing in the attached database. Works only if missions are not packed and scripts readable, e.g. in JCM, STA or ITM."
echo.
call :_wrap_and_echo "Any selection or entry is substituted as typed into the dropped .engscr file, or, the default mission Firing Ground. Whether there is such a unit as you entered in activated mods is not checked. The mission crashes if you choose or enter a non-existent unit code, or, if mission specific requirements are not met by the new unit chosen. You may be fired upon if you replaced a unit of conflicting alliance."
echo.
call :_wrap_and_echo "Back up is saved in the script directory. Restore is automatic:"
call :_wrap_and_echo "1. when you rerun the batch file (for default mission), whether you choose a new unit or exit without choosing an unit."
call :_wrap_and_echo "2. or drop the changed .engscr (not the back up file) from the mission script directory onto the batch file."

IF !colored_text! EQU true (
	echo [96m-------------------------[0m
) ELSE (
	echo -------------------------
)
REM if a backup file is found, offer option to restore
REM IF EXIST "!textFile!_original.bak" (
	REM IF !colored_text! EQU true (
		REM echo [96mRestore backup - press[0m R
	REM ) ELSE (
		REM echo Restore backup - press R.
	REM )
REM )

if NOT "!my_tank_id:_platoon_=!"=="!my_tank_id!" (
	call :_wrap_and_echo "Current unit (!my_tank_id: =!) is!affirmative! a platoon. Menu only provides single vehicle units. You may want to try entering a platoon unit manually."
	ECHO.
)

IF !colored_text! EQU true (
	echo [96mType in in-game unit code ^(e.g.[0m wer_mtank1[96m^) or leave empty to pick from menu[0m
) ELSE (
	echo Type in in-game unit code ^(e.g. wer_mtank1^) or leave empty to pick from menu
)
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
		REM move /y "!textFile!_original.bak" "!textFile!"
		CALL :RESTORE_ORIGINAL_BACKUP "!textFile!" "_original.bak"
		echo.
		IF !colored_text! EQU true (
			echo [96mScript file restored^^![0m
		) ELSE (
			echo Script file restored^^!
		)
	) ELSE (
		echo.
		echo Something is wrong^^! Back up file not found^^!
		echo.
	)
	REM Back up original and replace with temporary file
	IF EXIST "!zones_file_full_path!_original.bak" (
		move /y "!zones_file_full_path!_original.bak" "!zones_file_full_path!" 1>nul
	)
	echo.
	echo Press any key to exit.
	echo.
	pause >nul
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

IF !colored_text! EQU true (
	SET "prompt_country=[96mChoose Country:[0m"
) ELSE (
	SET "prompt_country=Choose Country:"
)

call :CREATE_MENU COUNTRY !index! "!prompt_country!"

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

IF !colored_text! EQU true (
	SET "prompt_series=[96mChoose Tank Series:[0m"
) ELSE (
	SET "prompt_series=Choose Tank Series:"
)

REM echo TankSeries Index: !TankSeries_index!
call :CREATE_MENU TANK_SERIES !TankSeries_index! "!prompt_series!" COUNTRY_SELECT
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

IF !colored_text! EQU true (
	SET "prompt_model=[96mChoose Tank Model:[0m"
) ELSE (
	SET "prompt_model=Choose Tank Model:"
)

REM echo TankModels Index: !TankModel_index!
call :CREATE_MENU TANK_MODEL !TankModel_index! "!prompt_model!" TANK_SERIES_SELECT

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

REM Parse if Chosen_TANK_GAMEID is a platoon
REM by testing if the _platoon_ substring is present

IF NOT x%Chosen_TANK_GAMEID:_platoon_=%==x%Chosen_TANK_GAMEID% (
	
	REM if this is a platoon, adjust contour to prevent
	REM different units stacked on top of each other
	REM resulting in toppled vehicles
	CALL :EXPAND_CONTOUR
)

REM Change _scripts.engscr
call :REPLACE_WITH_SELECTION !Chosen_TANK_GAMEID!

goto END_MAIN


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
	move /y "!textFile!" "!textFile!_original.bak" 1>nul
	REM add timeout for Windows Explorer to catch up with updating 
	REM file names if directory to mission files is open
	timeout /t 2 >nul
)
REM activate the modded file
move /y "!temp_file!" "!textFile!" 1>nul

echo.
echo Enjoy^^! Press any key to exit.
echo.
pause >nul
endlocal

:_end_program
exit
