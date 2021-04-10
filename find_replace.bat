@echo off 
    setlocal enableextensions disabledelayedexpansion

    set "search=new_tank"
    set "replace=%1"

    set "textFile=Tank_Gunnery_Range_scripts.engscr.template"

    for /f "delims=" %%i in ('type "%textFile%" ^& break ^> "Tank Gunnery Range_scripts.engscr" ') do (
        set "line=%%i"
        setlocal enabledelayedexpansion
        set "line=!line:%search%=%replace%!"
        >>"Tank Gunnery Range_scripts.engscr" echo(!line!
        endlocal
    )