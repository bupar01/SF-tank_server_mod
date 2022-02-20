# SF-tank_server_mod

This utility provides the user ability to change from default unit before playing a mission without the need to go through the Mission Editor.

This batch file works through menu selection or manual entry of an in-game unit code. Manual entry allows use of platoons/tanks missing in the attached database. Works only if missions are not packed, e.g. in Japanese Community Mod (JCM), STA or Iron Task Mod (ITM), and scripts directory readable and writable.

Any selection or entry is substituted as typed into the dropped .engscr file, or, the default mission Firing Ground. Whether there is such a unit as you entered in current activated mods is not checked. Be warned! The mission may crash if you choose or enter a non-existent unit code, or, if mission specific requirements are not met by the new unit chosen, e.g. a single tank chosen when the mission is scripted for platoons and infantry.

A back up is saved in the same directory the very first time you run the batch file on a .engscr mission script. You can restore the original by running the batch file again and choose restore (for the default mission), or, drop the changed script with extension .engscr (not the back up file) from the mission script directory onto the batch file. The restore option will only appear if a backup is found.

The default mission is present in both JCM and ITM as of February 2022.

## Zip archive content:

999-TSM_v02 (Tank_Server_Mod)

### Tank_Server_Mod Files:

1. tankid.csv - this database holds the game tank id codes that the batch file reads (no need to touch this file). If you like to browse this file, open with a text editor or a spreadsheet program
2. 0_tankid_change_v02.bat - windows batch file to choose and switch user tank
3. 0_tankid_change_v02_no_color.bat - stripped of colored text for earlier Windows version users (Windows 7)
4. docs\how_to_use_tank_server_mod.txt - this file
5. docs\vehicles_lists_from_different_mods.xlsx - Excel spreadsheet list of vehicle codes from different mods compared

***IMPORTANT***: The tankid.csv and 0_tankid_change_v02.bat/0_tankid_change_v02_no_color.bat files is required to be in the root directory of the game Steel Fury - Kharkov 1942.

## Installation

Place the extracted folder containing the files into JSGME's MODS folder (make sure there is no extra enclosing folder from the extraction process).

Activate, preferably last in your lists of mods, with JSGME.

The tankid.csv and 0_tankid_change_v02.bat/0_tankid_change_v02_no_color.bat files should now appear in the game root directory

## How to use

Double-click the 0_tankid_change_v02.bat file in the Steel Fury - Kharkov 1942 game root folder and follow prompts to select country, tank series and the tank model. You can type in a unit if you already have its code instead of using the menu system.

The command prompt window can be closed once the replacement is confirmed.

Run Steel Fury and play the changed mission.

### Default Mission

The default mission, Firing Ground 1, is located within the GMP 1.47 in JCM and STA mods and within the Training Missions in ITM. In ITM, it is hidden at first until you get through the earlier missions but can be bypassed with the all-missions-open module.

### How to use to change other mission or campaign files

Drag-and-drop a mission or campaign script file on the 0_tankid_change_v02.bat file. The mission or campaign script files are located in different folders under "data\k42\loc_rus\levels\LEVELS\SCRIPTS\".

Follow prompts to select country, tank series and the tank model. The command prompt window can be closed once the replacement is confirmed.

### How to restore the original mission script

A backup of the original script will be created in the same mission script folder the first time the mission is changed.

Run the 0_tankid_change_v02.bat file again and choose restore option will revert to the original script file for the Firing Ground Mission. If you have made changes to another mission by drag-and-drop, drop the changed script file from the mission folder onto the batch file. If a back up file is found, the restore option will be offered.

