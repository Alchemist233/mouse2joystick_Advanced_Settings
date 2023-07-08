;	;	;	;	;	;	;	;	;	;	;	;	;	;	;	;
;	Modified for Advanced Settings by: Alchemist233 ()
;	Last Modified Date: 2023-07-08

;	Modified for CEMU by: CemuUser8 (https://www.reddit.com/r/cemu/comments/5zn0xa/autohotkey_script_to_use_mouse_for_camera/)
;	Last Modified Date: 2020-05-19
; 
;	Original Author: Helgef
;	Date: 2016-08-17
;
;	Description:
;	Mouse to virtual joystick. For virtual joystick you need to install vJoy. See url below.
;	
;	Notes: 	
;			-F4 exit at any time.
;
;	Urls:
;			https://autohotkey.com/boards/viewtopic.php?f=19&t=21489 										- First released here / help / instruction / bug reports.
;			http://vjoystick.sourceforge.net/site/															- vJoy device drivers, needed for mouse to virtual joystick.
;			https://autohotkey.com/boards/viewtopic.php?f=19&t=20703&sid=2619d57dcbb0796e16ea172f238f08a0 	- Original request by crisangelfan.
;			https://autohotkey.com/boards/viewtopic.php?t=5705												- CvJoyInterface.ahk
;
;	Acknowledgements:
;			crisangelfan and evilC on autohotkey.com forum provided useful input.
;			Credit to author(s) of vJoy @ http://vjoystick.sourceforge.net/site/
;			evilC did the CvJoyInterface.ahk
;
version := "v1.0.0.1"
#NoEnv  																; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input															; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  											; Ensures a consistent starting directory.
;#Include CvJI/CvJoyInterface.ahk										; Credit to evilC.
#Include CvJI/CvGenInterface.ahk ; A Modifed Interface that CemuUser8 added the vXBox device and functions to.
#Include CvJI/MouseDelta.ahk ; Alternate way to see mouse movement
#Include CvJI/SelfDeletingTimer.ahk
; Settings
#MaxHotkeysPerInterval 210
#HotkeyInterval 1000
#InstallMouseHook
#SingleInstance Force
CoordMode,Mouse,Screen
SetMouseDelay,-1
SetBatchLines,-1

; On exit
OnExit("exitFunc")

IF (A_PtrSize < 8) {
	MsgBox,16,Now Requires 64bit. If you are getting this error you must be running the script directly and have 32bit AutoHotkey installed.`n`nPlease either use the released executable, or change your AutoHotkey installation to the 64bit Unicode version 
	ExitApp
}

;OrigMouseSpeed := ""
;DllCall("SystemParametersInfo", UInt, 0x70, UInt, 0, UIntP, OrigMouseSpeed, UInt, 0) ; Get Original Mouse Speed.

toggle:=1													; On/off parameter for the hotkey.	Toggle 0 means controller is on. The placement of this variable is disturbing.

; If no settings file, create, When changing this, remember to make corresponding changes after the setSettingsToDefault label (error handling) ; Currently at bottom of script
IfNotExist, settings.ini
{
	defaultSettings=
	(
		[General]
		usevXBox=1
		vJoyDevice=1
		vXBoxDevice=1
		gameExe=Ryujinx.exe
		autoActivateGame=1
		hideCursor=1
		[General>Setup]
		r=300
		k=0
		freq=50
		nnp=.8
		[General>Hotkeys]
		controllerSwitchKey=F1
		mainSetToggleKey=F2
		reloadKey=F3
		exitKey=F4
		[Mouse2Joystick>Axes]
		invertedX=0
		invertedY=0
		[Mouse2Joystick>Keys]
		joystickButtonKeyLists=Space^1^^,e^1^^|RButton & LButton^^^,LButton^^^|XButton2 & Tab^^^|v & Tab^^^|b & Tab^^^|Tab^1^1^,LShift^^^,q^^^,r^^^,RButton^^^|r & XButton2^^^|r & XButton1^^^,f^^^,4^2^1^,5^2^1^,z^^^,c^^^,r & WheelUp^^^|XButton2^^^,r & WheelDown^^^|XButton1^^^,r & LButton^^^|v^^1^,r & RButton^^^|b^^1^,v & RButton^^^|b & RButton^^^|q & RButton^^^200|XButton2 & RButton^^1^,q & XButton2^^^200,q & WheelUp^^^,,v & LButton^^^|b & LButton^^^|q & LButton^^^200|XButton2 & LButton^^1^,,q & WheelDown^^^,q & XButton1^1^1^200:Space^1^^|RButton^2^1^,LButton^^^|e^^^,Tab^^^,LShift^^^,q^^^,r^^^,,,4^2^1^,5^2^1^,,c^2^^,XButton2^^^,XButton1^^^,v^^^,b^^^,,,WheelUp^^^,,,,WheelDown^^^,::::::
		[Keyboard Movement>Keys]
		upKey=w
		leftKey=a
		downKey=s
		rightKey=d
		walkToggleKey=CapsLock
		increaseWalkKey=NumpadAdd
		decreaseWalkKey=NumpadSub
		walkSpeed=0.50
		gyroToggleKey=
		[Extra Settings]
		lockZL=0
		lockZLToggleKey=
		BotWmotionAim=0
		useAltMouseMethod=0
		alt_xSen=400
		alt_ySen=280
	)
	FileAppend,%defaultSettings%,settings.ini
	IF (ErrorLevel) {
		Msgbox,% 6+16,Error writing to file., There was a problem creating settings.ini
		, make sure you have permission to write to file at %A_ScriptDir%. If the problem persists`, try to run as administrator or change the script directory. Press retry to try again`, continue to set all settings to default or cancel to exit application.
		IfMsgBox Retry
			reload
		Else IfMsgBox Continue
			Goto, setSettingsToDefault	; Currently at bottom of script
		Else 
			ExitApp
	}
	firstRun := True ; Moved out of ini File.
}

; Read settings.
IniRead,allSections,settings.ini
IF (!allSections || allSections="ERROR") { ; Do not think this is ever set to ERROR.
	MsgBox, % 2+16, Error reading file, There was an error reading the settings.ini file`, press retry to try again`, continue to set all settings to default or cancel to exit application.
	IfMsgBox retry
		reload
	Else IfMsgBox Ignore
		Goto, setSettingsToDefault	; Currently at bottom of script
	Else 
		ExitApp
}
Loop,Parse,allSections,`n
{
	IniRead,pairs,settings.ini,%A_LoopField%
	Loop,Parse,pairs,`n
	{
		StringSplit,keyValue,A_LoopField,=
		%keyValue1%:=keyValue2
	}
}
readSettingsSkippedDueToError:	; This comes from setSettingsToDefault If there was an error.
	pi := 4 * ATan(1)	; Approx pi.
	; Constants and such. Some values are commented out because they have been stored in the settings.ini file instead, but are kept because they have comments.
	moveStickHalf := False
	ih := InputHook()
	ih.KeyOpt("{All}", "ES")
	dr := 0											; Bounce back when hit outer circle edge, in pixels. (This might not work any more, it is off) Can be seen as a force feedback parameter, can be extended to depend on the over extension beyond the outer ring.
	gyroToggleKey := False
	lockZL := 0
	useAltMouseMethod := 0
	; Hotkey(s).
	IF (controllerSwitchKey)
		Hotkey,%controllerSwitchKey%,controllerSwitch, on
	IF (reloadKey)
		Hotkey,%reloadKey%,reloadFunc, on
	IF (exitKey)
		Hotkey,%exitKey%,exitFunc, on
	IF (mouse2joystick := True) {
		Gosub, initCvJoyInterface
		Gosub, mouse2joystickHotkeys
	}
	IF (mainSetToggleKey) {
		Gosub, keyList2Array
		Gosub, calcTrigVals	
		Hotkey,%mainSetToggleKey%,toggleMainSet, on
	}
	; Icon
	Menu,Tray,Tip, Mouse2Joystick Advanced Settings
	Menu,Tray,NoStandard
	IF (!A_IsCompiled) { ; If it is compiled it should just use the EXE Icon
		IF (A_OSVersion < "10.0.15063") ; It appears that the Icon has changed number on the newest versions of Windows.
			useIcon := 26
		Else IF (A_OSVersion >= "10.0.16299")
			useIcon := 28
		Else
			useIcon := 27
		Try
			Menu,Tray,Icon,ddores.dll, %useIcon% 
	}
	;Menu,Settings,openSettings
	Menu,Tray,Add,Settings,openSettings
	Menu,Tray,Add,
	IF (vGenInterface.IsVBusExist())
		Menu,Tray,Add,Uninstall ScpVBus, uninstallBus
	Else
		Menu,Tray,Add,Install ScpVBus, installBus
	Menu,Tray,Add,
	Menu,Tray,Add,Reset to Ryujinx, selectGameMenu
	Menu,Tray,Add
	Menu,Tray,Add,About,aboutMenu
	; Menu,Tray,Add,Help,helpMenu
	Menu,Tray,Add
	Menu,Tray,Add,Reload,reloadMenu
	Menu,Tray,Add,Exit,exitFunc
	Menu,Tray,Default, Settings
	IF freq is not Integer
		freq := 75

	pmX:=invertedX ? -1:1							; Sign for inverting axis
	pmY:=invertedY ? -1:1
	snapToFullTilt:=0.005							; This needs to be improved.
	;nnp:=4	 										; Non-linearity parameter for joystick output, 1 = linear, >1 higher sensitivity closer to full tilt, <1 higher sensitivity closer to deadzone. Recommended range, [0.1,6]. 
	; New parameters
	; Mouse blocker
	; Transparent window that covers game screen to prevent game from capture the mouse.
	Gui, Controller: New
	Gui, Controller: +ToolWindow -Caption +AlwaysOnTop +HWNDstick
	Gui, Controller: Color, FFFFFF
	; Spam user with useless info, first time script runs.
	IF (firstRun)
		MsgBox,64,Welcome,Settings are accessed via Tray icon -> Settings.
Return
; End autoexec.

selectGameMenu:
	TrayTip, % "Game reset to Ryujinx.exe", % "If you want something different manually edit the settings, or 'settings.ini' file directly",,0x10
	gameExe := "Ryujinx.exe"
	IniWrite, %gameExe%, settings.ini, General, gameExe
Return

reloadMenu:
	Reload
Return

aboutMenu:
	Msgbox,32,About, Modified for Mouse2Joystick Custom for CEMU Settings by:`nAlchemist233`n`nVersion:`n%version%
Return

; helpMenu:
; 	Msgbox,% 4 + 32 , Open help in browser?, Visit Reddit post on /r/cemu for help?`n`nIt is helpful to know the version (%version%)`nand If possible a pastebin of your 'settings.ini' file will help me troubleshoot.`n`nWill Open link in default browser.
; 	IfMsgBox Yes
; 		Run, https://www.reddit.com/r/cemu/comments/5zn0xa/autohotkey_script_to_use_mouse_for_camera/
; Return

initCvJoyInterface:
	; Global vXBox := usevXBox
	Global usevXBox := 1
	Global vXBox := 1
	; Copied from joytest.ahk, from CvJoyInterface by evilC
	; Create an object from vJoy Interface Class.
	vGenInterface := new CvGenInterface()
	; Was vJoy installed and the DLL Loaded?
	; IF (!vGenInterface.vJoyEnabled()){
	; 	; Show log of what happened
	; 	Msgbox,% 4+16,vJoy Error,% "vJoy needs to be installed. Press no to exit application.`nLog:`n" . vGenInterface.LoadLibraryLog ; Error handling changed.
	; 	IfMsgBox Yesneed
	; 	{
	; 		;IniWrite, 0,settings.ini,General,mouse2joystick
	; 		reload
	; 	}
	; 	ExitApp
	; }
	; IF (vXBox AND !vGenInterface.IsVBusExist()) {
	; 	Msgbox,% 4 + 32 , Virtual xBox Bus not found, Press Yes If you would like to install ScpVBus, otherwise script will revert back to vJoy instead of vXBox.`n`nScript will reload after installing.
	; 	IfMsgBox Yes
	; 		InstallUninstallScpVBus(True)
	; 	Else {
	; 		vXBox := False
	; 		IniWrite,0, settings.ini, General, usevXBox ; Turn off the setting for the next run as well.
	; 	}
	; }
	ValidDevices := ""
	Loop 15 {
		IF (vGenInterface.Devices[A_Index].IsAvailable())
			ValidDevices .= A_Index . "|"
	}
	IF (vXBox) {
		IF (vXboxDevice != vstick.DeviceID OR !vstick.GetLedNumber()) {
			IF (isObject(vstick)) {
				vstick.Unplug()
				vstick.Relinquish()
			}
			;vGenInterface.UnPlugAll() ; Not sure how this interacts when a real controller is also plugged in. But I seem to notice that there is an issue if not ran.
			Global vstick := vGenInterface.xDevices[vXBoxDevice]
			vstick.Acquire()
			TrayTip,, % "Controller #" vstick.GetLedNumber() 
		}

	}
	Else {
		IF (isObject(vstick)) {
			vstick.Unplug()
			vstick.Relinquish()
		}
		Global vstick := vGenInterface.Devices[vJoyDevice]
	}
Return

; Hotkey labels
; This switches on/off the controller.
controllerSwitch:
	IF (toggle) { ; Starting controller
		; Gui, Main:Hide
		Gosub, MainGUIClose
		IF (autoActivateGame) {
			WinActivate,ahk_exe %gameExe%
			WinWaitActive, ahk_exe %gameExe%,,2
			IF (ErrorLevel) {	
				MsgBox,16,Error, %gameExe% not activated.
				Return
			}
			WinGetPos,gameX,gameY,gameW,gameH,ahk_exe %gameExe%									; Get game screen position and dimensions
			WinGet, gameID, ID, ahk_exe %gameExe%
		}
		Else {
			gameX:=0
			gameY:=0
			gameW:=A_ScreenWidth
			gameH:=A_ScreenHeight
		}
		
		; Controller origin is center of game screen or screen If autoActivateGame:=0.
		OX:=gameX+gameW/2				
		OY:=gameY+gameH/2
		
		IF (!OX OR !OY) {
			OX := 500
			OY := 500
		}

		; Move mouse to controller origin
		MouseMove,OX,OY	
		
		; The mouse blocker
		Gui, Controller: Show,NA x%gameX% y%gameY% w%gameW% h%gameH%,Controller
		WinSet,Transparent,1,ahk_id %stick%	
		
		IF (hideCursor)
			show_Mouse(False)
		;DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, 10, UInt, 0)
		
		IF (useAltMouseMethod) {
			; md.Start()
			LockMouseToWindow("ahk_id " . stick)
		}
		Else
			SetTimer,mouseTojoystick,%freq%
	}
	Else {	; Shutting down controller
		setStick(0,0)															; Stick in equilibrium.
		setStick(0,0, True)
		IF (useAltMouseMethod) {
			LockMouseToWindow(False)
			; md.Stop()
		}
		Else
			SetTimer,mouseTojoystick,Off
		
		IF (hideCursor)
			show_Mouse()				; No need to show cursor if not hidden.
		;DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, OrigMouseSpeed, UInt, 0)  ; Restore the original speed.
		; Gui, Controller:Hide
		Gui, Controller:Hide
	}
	toggle := !toggle
	Gosub, openSettings
Return

; Hotkeys mouse2joystick
#IF (!toggle && mouse2joystick)
#IF
mouse2joystickHotkeys:
	Hotkey, IF, (!toggle && mouse2joystick)
	SetStick(0,0, True)
	IF (walkToggleKey)
		HotKey,%walkToggleKey%,toggleHalf, on
	IF (decreaseWalkKey)
		HotKey,%decreaseWalkKey%,decreaseWalk, on
	IF (increaseWalkKey)
		HotKey,%increaseWalkKey%,increaseWalk, on
	IF (lockZLToggleKey AND lockZL)
		HotKey,%lockZLToggleKey%,toggleAimLock, on
	IF (gyroToggleKey) {
		HotKey,%gyroToggleKey%, GyroControl, on
		HotKey,%gyroToggleKey% Up, GyroControlOff, on
	}
	Hotkey,%upKey%, overwriteUp, on 
	Hotkey,%upKey% Up, overwriteUpup, on
	Hotkey,%leftKey%, overwriteLeft, on 
	Hotkey,%leftKey% Up, overwriteLeftup, on
	Hotkey,%downKey%, overwriteDown, on 
	Hotkey,%downKey% Up, overwriteDownup, on
	Hotkey,%rightKey%, overwriteRight, on 
	Hotkey,%rightKey% Up, overwriteRightup, on
	Hotkey, IF
Return

; Unbind all Hotkeys in 'Advanced Settings' and bind them to the Hotkeys in set1.
toggleMainSet:
	currSet := 1
	currDisMmState := "F"
	Gosub, unDisMm
	For setIdx, in joystickButtonKeyArray
		Gosub, forceUnBindSet
	Gosub, initSet
Return

; Generate the 3d array for storing key information.
keyList2Array:
	joystickButtonKeyArray := {}
	; keyInfo: keyName^togToSet^disMmState^holdDelay
	; keyName: The name of the key to be pressed. 
	; togToSet: The index of the toggle to set. If this is blank or 0, the key is not a setToggleKey.
	; disMmState: 0 or 1, If this is 1, mouse motion will be disabled while the key is held down or released.
	; holdDelay: The amount of time to hold the key down.
	Loop, Parse, joystickButtonKeyLists, :
	{
		setIndex := A_Index
		joystickButtonKeyList := A_LoopField
		If (!joystickButtonKeyList)
			Continue
		Loop, Parse, joystickButtonKeyList, CSV
		{
			joyButtonNumber := A_Index
			keyGroup := A_LoopField
			If (!keyGroup)
				Continue
			Loop, Parse, keyGroup, |
			{	
				keyInfo := A_LoopField
				Loop, Parse, keyInfo, ^
				{	
					infoIndex := A_Index
					infoValue := A_LoopField
					If (infoIndex = 1) {
						keyName := (InStr(infoValue, "&") ? "~" : "") . infoValue
						joystickButtonKeyArray[setIndex, keyName, infoIndex] := joyButtonNumber
					}
					Else
						joystickButtonKeyArray[setIndex, keyName, infoIndex] := infoValue = "" ? 0 : infoValue
				}
			}
		}
	}
Return

; Generate some trigonometric function constants.
calcTrigVals:
	commTrigVals := {}
	Loop 8
	{
		commTrigVals[A_Index - 1, "cos"] := Cos((A_Index - 1) / 4 * pi)
		commTrigVals[A_Index - 1, "sin"] := Sin((A_Index - 1) / 4 * pi)
	}
Return

; Execute when a Hotkey is pressed.
pressHotkey:
	useKeyName := A_ThisHotkey
	If (!(joyButtonNumber := joystickButtonKeyArray[currSet, useKeyName, 1]))
		Return
	Gosub, getKeyInfo
	Gosub, pressUpdateMm
	Gosub, pressJoyButton
	Gosub, setHoldDelay
Return

; Execute when a Hotkey is released.
releaseHotkey:
	useKeyName := RegExReplace(A_ThisHotkey, " Up$")
	If (!(joyButtonNumber := joystickButtonKeyArray[currSet, useKeyName, 1]))
		Return
	Gosub, getKeyInfo
	Gosub, releaseJoyButton
	If (!togToSet)
		Gosub, releaseUpdateMm
	Else {
		Gosub, unbindSet
		Gosub, releaseTogKeyUpdateMm
		Gosub, bindSet
	}
Return

; Get key information from the 3d array."
getKeyInfo:
	togToSet := joystickButtonKeyArray[currSet, useKeyName, 2]
	disMmState := joystickButtonKeyArray[currSet, useKeyName, 3]
	holdDelay := joystickButtonKeyArray[currSet, useKeyName, 4]
	addNum := "(" . joyButtonNumber . ")"
Return

; Set hold delay
setHoldDelay:
	If (holdDelay)
		DllCall("Sleep", Uint, holdDelay)
Return

; Update mouse motion state when a non-toggle HotKey is pressed
pressUpdateMm:
	If (!togToSet AND disMmState AND (FIndex := InStr(currDisMmState, "F"))) {
		If (FIndex = 1)
			Gosub, disMm
		If (!InStr(currDisMmState, addNum))
			currDisMmState := addNum . currDisMmState
	}	
Return

; Update mouse motion state when a non-toggle HotKey is released
releaseUpdateMm:
	If (disMmState AND InStr(currDisMmState, "F")) {
		currDisMmState := StrReplace(currDisMmState, addNum, "")
		If (InStr(currDisMmState, "F") = 1)
			Gosub, unDisMm
	}	
Return

; Update mouse motion state when a toggle HotKey is released
releaseTogKeyUpdateMm:
	If (!disMmState AND InStr(currDisMmState, "T")) {
	; If (!disMmState) {
		currDisMmState := "F"
		Gosub, unDisMm
	}	
	Else If (disMmState AND InStr(currDisMmState, "F")) {
		currDisMmState := "T"
		Gosub, disMm
	}
Return

; Disable mouse motion
disMm:
	SetTimer, mouseTojoystick, Off
	SetStick(0, 0)
	MouseMove, gameW/2, gameH/2
Return

; Enable mouse motion
unDisMm:
	MouseMove, gameW/2, gameH/2
	SetStick(0, 0)
	SetTimer, mouseTojoystick, On
Return

; Unbind current key set.
unBindSet:
	If (currSet = togToSet)
		Return
	setIdx := currSet
	; If (joyButtonNumber := joystickButtonKeyArray[setIdx, StrSplit(StrReplace(useKeyName, "~", "") , "&", " `t")[1], 1])
	; 	Gosub, releaseJoyButton
forceUnBindSet:
	Hotkey, IF, (!toggle && mouse2joystick)
	For keyName, keyInfo in joystickButtonKeyArray[setIdx]
	{	
		Hotkey,%keyName%, pressHotkey, Off
		If (joyButtonNumber := keyInfo[1])
			Gosub, releaseJoyButton
		Hotkey,%keyName% Up, releaseHotkey, Off
	}
	Hotkey, IF
Return

; Bind current key set.
bindSet:
	If (currSet = togToSet)
		Return
	currSet := togToSet
initSet:
	Hotkey, IF, (!toggle && mouse2joystick)
	For keyName, in joystickButtonKeyArray[currSet]
	{
		Hotkey,%keyName%, pressHotkey, On 
		Hotkey,%keyName% Up, releaseHotkey, On
	}
	Hotkey, IF
Return

; Labels for pressing joystick buttons.
pressJoyButton:
	If InStr(useKeyName, "wheel")
		new SelfDeletingTimer(100, "ReleaseWheel", joyButtonNumber)
	IF (!vXBox){
		IF (joyButtonNumber = 7 AND lockZL) {
			IF (ZLToggle)
				vstick.SetBtn(0,joyButtonNumber)
			Else
				vstick.SetBtn(1,joyButtonNumber)
		}
		Else IF (joyButtonNumber = 8 AND BotWmotionAim) {
			GoSub, GyroControl
			vstick.SetBtn(1,joyButtonNumber)
		}
		Else IF (joyButtonNumber)
			vstick.SetBtn(1,joyButtonNumber)
	}
	Else {
		Switch joyButtonNumber
		{
		Case 1,2,3,4,5,6:
			vstick.SetBtn(1, joyButtonNumber)
		Case 7:
			IF (lockZL AND ZLToggle)
				vstick.SetAxisByIndex(0, 6)
			Else
				vstick.SetAxisByIndex(100, 6)
		Case 8:
			vstick.SetAxisByIndex(100, 3)
		Case 9:
			vstick.SetBtn(1, 8)
		Case 10:
			vstick.SetBtn(1, 7)
		Case 11,12:
			vstick.SetBtn(1, joyButtonNumber - 2)
		Case 13:
			vstick.SetPOV(0)
		Case 14:
			vstick.SetPOV(180)
		Case 15:
			vstick.SetPOV(270)
		Case 16:
			vstick.SetPOV(90)
		Case 17,18,19,20,21,22,23,24:
			; setStick(0, 0)
			setStick(commTrigVals[joyButtonNumber - 17, "cos"], commTrigVals[joyButtonNumber - 17, "sin"])
		Default:
			MsgBox, 16, Error, Hotkey '%useKeyName%' binding failed. Please restart mouse2joystick or try another key.
		}
	}
Return

; Labels for releasing joystick buttons.
releaseJoyButton:
	IF (!vXBox){
		IF (joyButtonNumber = 7 AND lockZL) {
			IF (ZLToggle)
				vstick.SetBtn(1,joyButtonNumber)
			Else
				vstick.SetBtn(0,joyButtonNumber)
		}
		Else IF (joyButtonNumber = 8 AND BotWmotionAim) {
			vstick.SetBtn(0,joyButtonNumber)
			GoSub, GyroControlOff
		}
		Else IF (joyButtonNumber)
			vstick.SetBtn(0,joyButtonNumber)
	}
	Else {
		Switch joyButtonNumber
		{
			Case 1,2,3,4,5,6:
				vstick.SetBtn(0, joyButtonNumber)
			Case 7:
				IF (lockZL AND ZLToggle)
					vstick.SetAxisByIndex(100, 6)
				Else
					vstick.SetAxisByIndex(0, 6)
			Case 8:
				vstick.SetAxisByIndex(0, 3)
			Case 9:
				vstick.SetBtn(0, 8)
			Case 10:
				vstick.SetBtn(0, 7)
			Case 11,12:
				vstick.SetBtn(0, joyButtonNumber - 2)
			Case 13,14,15,16:
				vstick.SetPOV(-1)
			Case 17,18,19,20,21,22,23,24:
				setStick(0, 0)
			Default:
		}
	}
Return

; This is duplicated of the label below, it had to be added so I could release mouse wheel keys as they don't fire Up keystrokes.
ReleaseWheel(keyNum) {
	Global
	IF (!vXBox) {
		IF (keyNum = 7 AND lockZL) {
			IF (ZLToggle)
				vstick.SetBtn(1,keyNum)
			Else
				vstick.SetBtn(0,keyNum)
		}
		Else IF (keyNum = 8 AND BotWmotionAim) {
			vstick.SetBtn(0,keyNum)
			GoSub, GyroControlOff
		}
		Else IF (keyNum)
			vstick.SetBtn(0,keyNum)
	}
	Else {
		Switch keyNum
		{
			Case 1,2,3,4,5,6:
				vstick.SetBtn(0, joyButtonNumber)
			Case 7:
				IF (lockZL AND ZLToggle)
					vstick.SetAxisByIndex(100, 6)
				Else
					vstick.SetAxisByIndex(0, 6)
			Case 8:
				vstick.SetAxisByIndex(0, 3)
			Case 9:
				vstick.SetBtn(0, 8)
			Case 10:
				vstick.SetBtn(0, 7)
			Case 11,12:
				vstick.SetBtn(0, keyNum - 2)
			Case 13,14,15,16:
				vstick.SetPOV(-1)
			Case 17,18,19,20,21,22,23,24:
				setStick(0, 0)
			Default:
		}
	}
	Return
}

GyroControl:
	;DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, 4, UInt, 0) ; Slow mouse movement down a little bit
	; SetStick(0,0)
	; Gui, Controller:Hide
	; IF (!useAltMouseMethod) {
	; 	LockMouseToWindow("ahk_id " . gameID)
	; 	SetTimer, mouseTojoystick, Off
	; }
	; Click, Right, Down
Return

GyroControlOff:
	; Click, Right, Up
	; ;DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, 10, UInt, 0)  ; Restore the original speed.
	; Gui, Controller:Show, NA
	; IF (!useAltMouseMethod){
	; 	LockMouseToWindow()
	; 	SetTimer, mouseTojoystick, On
	; }
Return

toggleAimLock:
	IF (vXbox)
		vstick.SetAxisByIndex((ZLToggle := !ZLToggle) ? 100 : 0,6)
	Else
		vstick.SetBtn((ZLToggle := !ZLToggle),7)
Return

toggleHalf:
	moveStickHalf := !moveStickHalf
	KeepStickHowItWas()
Return

decreaseWalk:
	walkSpeed -= 0.05
	IF (walkSpeed < 0)
		walkSpeed := 0
	KeepStickHowItWas()
	IniWrite, % walkSpeed:= Round(walkSpeed, 2), settings.ini, Keyboard Movement>Keys, walkSpeed
	GUI, Main:Default
	GUIControl,,opwalkSpeedTxt, % Round(walkSpeed * 100) "%"
Return

increaseWalk:
	walkSpeed += 0.05
	IF (walkSpeed > 1)
		walkSpeed := 1
	KeepStickHowItWas()
	IniWrite, % walkSpeed := Round(walkSpeed, 2), settings.ini, Keyboard Movement>Keys, walkSpeed
	GUI, Main:Default
	GUIControl,,opwalkSpeedTxt, % Round(walkSpeed * 100) "%"
Return

KeepStickHowItWas() {
	Global moveStickHalf, walkSpeed, upKey, leftKey, downKey, rightKey
	IF (GetKeyState(downKey, "P"))
		SetStick("N/A",(moveStickHalf ? -1 * walkSpeed : -1), True)
	IF (GetKeyState(rightKey, "P"))
		SetStick((moveStickHalf ? 1 * walkSpeed : 1),"N/A", True)
	IF (GetKeyState(leftKey, "P"))
		SetStick((moveStickHalf ? -1 * walkSpeed : -1),"N/A", True)
	IF (GetKeyState(upKey, "P"))
		SetStick("N/A",(moveStickHalf ? 1 * walkSpeed : 1), True)
}

overwriteUp:
	Critical, On
	IF (moveStickHalf)
		SetStick("N/A",1 * walkSpeed, True)
	Else
		SetStick("N/A",1, True)
	Critical, Off
Return
overwriteUpup:
	Critical, On
	IF (GetKeyState(downKey, "P")) {
		IF (moveStickHalf)
			SetStick("N/A",-1 * walkSpeed, True)
		Else
			SetStick("N/A",-1, True)
	}
	Else
		SetStick("N/A",0, True)
	Critical, Off
Return
overwriteLeft:
	Critical, On
	IF (moveStickHalf)
		SetStick(-1 * walkSpeed,"N/A", True)
	Else
		SetStick(-1,"N/A", True)
	Critical, Off
Return
overwriteLeftup:
	Critical, On
	IF (GetKeyState(rightKey, "P")) {
		IF (moveStickHalf)
			SetStick(1 * walkSpeed,"N/A", True)
		Else
			SetStick(1,"N/A", True)
	}
	Else
		SetStick(0,"N/A", True)
	Critical, Off
Return
overwriteRight:
	Critical, On
	IF (moveStickHalf)
		SetStick(1 * walkSpeed,"N/A", True)
	Else
		SetStick(1,"N/A", True)
	Critical, Off
Return
overwriteRightup:
	Critical, On
	IF (GetKeyState(leftKey, "P")) {
		IF (moveStickHalf)
			SetStick(-1 * walkSpeed,"N/A", True)
		Else
			SetStick(-1,"N/A", True)
	}
	Else
		SetStick(0,"N/A", True)
	Critical, Off
Return
overwriteDown:
	Critical, On
	IF (moveStickHalf)
		SetStick("N/A",-1 * walkSpeed, True)
	Else
		SetStick("N/A",-1, True)
	Critical, Off
Return
overwriteDownup:
	Critical, On
	IF (GetKeyState(upKey, "P")) {
		IF (moveStickHalf)
			SetStick("N/A",1 * walkSpeed, True)
		Else
			SetStick("N/A",1, True)
	}
	Else
		SetStick("N/A",0, True)
	Critical, Off
Return

; Labels
mouseTojoystick:
	Critical, On
	mouse2joystick(r,dr,OX,OY)
	Critical, Off
Return

; Functions
mouse2joystick(r,dr,OX,OY) {
	; r is the radius of the outer circle.
	; dr is a bounce back parameter.
	; OX is the x coord of circle center.
	; OY is the y coord of circle center.
	Global k, nnp, AlreadyDown
	MouseGetPos,X,Y
	X-=OX										; Move to controller coord system.
	Y-=OY
	RR:=sqrt(X**2+Y**2)
	IF (RR>r) {								; Check If outside controller circle.
		X:=round(X*(r-dr)/RR)
		Y:=round(Y*(r-dr)/RR)
		RR:=sqrt(X**2+Y**2)
		MouseMove,X+OX,Y+OY 					; Calculate point on controller circle, move back to screen/window coords, and move mouse.
	}
	
	; Calculate angle
	phi:=getAngle(X,Y)							
	
	
	IF (RR>k*r AND !AlreadyDown) 								; Check If outside inner circle/deadzone.
		action(phi,((RR-k*r)/(r-k*r))**nnp)		; nnp is a non-linearity parameter.	
	Else
		setStick(0,0)							; Stick in equllibrium.

	MouseMove,OX,OY
}

action(phi,tilt) {	
	; This is for mouse2joystick.
	; phi ∈ [0,2*pi] defines in which direction the stick is tilted.
	; tilt ∈ (0,1] defines the amount of tilt. 0 is no tilt, 1 is full tilt.
	; When this is called it is already established that the deadzone is left, or the inner radius.
	; pmX/pmY is used for inverting axis.
	; snapToFullTilt is used to ensure full tilt is possible, this needs to be improved, should be dependent on the sensitivity.
	Global pmX,pmY,pi,snapToFullTilt

	; Adjust tilt
	tilt:=tilt>1 ? 1:tilt
	IF (snapToFullTilt!=-1)
		tilt:=1-tilt<=snapToFullTilt ? 1:tilt
	
	; Two cases with forward+right
	; Tilt is forward and slightly right.
	lb:=3*pi/2										; lb is lower bound
	ub:=7*pi/4										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=pmX*tilt*scale(phi,ub,lb)
		y:=pmY*tilt
		setStick(x,y)
		Return
	}
	; Tilt is slightly forward and right.
	lb:=7*pi/4										; lb is lower bound
	ub:=2*pi						; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=pmX*tilt
		y:=pmY*tilt*scale(phi,lb,ub)
		setStick(x,y)
		Return
	}
	
	; Two cases with right+downward
	; Tilt is right and slightly downward.
	lb:=0											; lb is lower bound
	ub:=pi/4										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=pmX*tilt
		y:=-pmY*tilt*scale(phi,ub,lb)
		setStick(x,y)
		Return
	}
	; Tilt is downward and slightly right.
	lb:=pi/4										; lb is lower bound
	ub:=pi/2										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=pmX*tilt*scale(phi,lb,ub)
		y:=-pmY*tilt
		setStick(x,y)
		Return
	}
	
	; Two cases with downward+left
	; Tilt is downward and slightly left.
	lb:=pi/2										; lb is lower bound
	ub:=3*pi/4										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=-pmX*tilt*scale(phi,ub,lb)
		y:=-pmY*tilt
		setStick(x,y)
		Return
	}
	; Tilt is left and slightly downward.
	lb:=3*pi/4										; lb is lower bound
	ub:=pi											; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=-pmX*tilt
		y:=-pmY*tilt*scale(phi,lb,ub)
		setStick(x,y)
		Return
	}
	
	; Two cases with forward+left
	; Tilt is left and slightly forward.
	lb:=pi											; lb is lower bound
	ub:=5*pi/4										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=-pmX*tilt
		y:=pmY*tilt*scale(phi,ub,lb)
		setStick(x,y)
		Return
	}
	; Tilt is forward and slightly left.
	lb:=5*pi/4										; lb is lower bound
	ub:=3*pi/2										; ub is upper bound
	IF (phi>=lb && phi<=ub)							
	{
		x:=-pmX*tilt*scale(phi,lb,ub)
		y:=pmY*tilt
		setStick(x,y)
		Return
	}
	; This should not happen:
	setStick(0,0)
	MsgBox,16,Error, Error at phi=%phi%. Please report.
	Return
}

scale(phi,lb,ub) {
	; let phi->f(phi) then, f(ub)=0 and f(lb)=1
	Return (phi-ub)/(lb-ub)
}

setStick(x,y, a := False) {
	; Set joystick x-axis to 100*x % and y-axis to 100*y %
	; Input is x,y ∈ (-1,1) where 1 would mean full tilt in one direction, and -1 in the other, while zero would mean no tilt at all. Using this interval makes it easy to invert the axis
	; (mainly this was choosen beacause the author didn't know the correct interval to use in CvJoyInterface)
	; the input is not really compatible with the CvJoyInterface. Hence this transformation:	
	IF (vXBox) {
		x:=(x+1)*50									; This maps x,y (-1,1) -> (0,100)
		y:=(y+1)*50
	}
	Else {
		x:=(x+1)*16384									; This maps x,y (-1,1) -> (0,32768)
		y:=(y+1)*16384
	}
	
	; Use set by index.
	; x = 1, y = 2.
	IF ( (!a AND vXbox) OR (a AND !vXBox) ) { ; IF (GetKeyState("RButton") OR a ) {
		axisX := 4
		axisY := 5
	}
	Else {
		axisX := 1
		axisY := 2
	}
	IF x is number
		vstick.SetAxisByIndex(x,axisX)
	IF y is number
		vstick.SetAxisByIndex(y,axisY)
}

; Shared functions
getAngle(x,y) {
	Global pi
	IF (x=0)
		Return 3*pi/2-(y>0)*pi
	phi:=atan(y/x)
	IF (x<0 && y>0)
		Return phi+pi
	IF (x<0 && y<=0)
		Return phi+pi
	IF (x>0 && y<0)
		Return phi+2*pi
	Return phi
}

reloadFunc() {
	Global
	IF (mouse2Joystick)	{
		setStick(0,0)
		SetStick(0,0, True)
		IF (vXBox)
			vstick.UnPlug()
		vstick.Relinquish()
	}
	show_Mouse()
	Reload
}

exitFunc() {
	Global
	IF (mouse2Joystick)	{
		setStick(0,0)
		SetStick(0,0, True)
		IF (vXBox)
			vstick.UnPlug()
		vstick.Relinquish()
	}
	; md.Delete()
	; md := ""
	show_Mouse() ; DllCall("User32.dll\ShowCursor", "Int", 1)
	;DllCall("SystemParametersInfo", UInt, 0x71, UInt, 0, UInt, OrigMouseSpeed, UInt, 0)  ; Restore the original speed.
	ExitApp
}

;
; End Script.
; Start settings.
;
openSettings:
	If (!toggle)		; This is probably best.
		Return
	tree := "
		(
			General|Setup,Hotkeys
			Mouse2Joystick|Axes,Keys
			Keyboard Movement|Keys
			Extra Settings
		)"
	groupBoxWidth := 380
	GUI, Main:New, -MinimizeBox, % "Mouse2Joystick Advanced Settings  -  " . version
	GUI, Add, Text,, Options:
	GUI, Add, TreeView, xm w150 r16 gTreeClick Section
	GUI, Add, Button,xs w73 gMainExit, Exit
	GUI, Add, Button,x+4 w73 gMainSave Default, Save
	GUI, Add, Tab2, +Buttons -Theme -Wrap vTabControl ys w%groupBoxWidth% h0 Section, General|General>Setup|General>Hotkeys|Mouse2Joystick|Mouse2Joystick>Axes|Mouse2Joystick>Keys|Keyboard Movement|Keyboard Movement>Keys|Extra Settings
	GUIControlGet, S, Pos, TabControl ; Store the coords of this section for future use.
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, General
		GUI, Add, GroupBox, x%SX% y%SY% w%groupBoxWidth% h96 Section, Output Mode
		GUI, Add, Radio, %  "Hidden h13 xp+10 yp+20 Group vopusevXBox Checked" . !usevXBox, Use vJoy Device (Direct Input)
		; GUI, Add, Radio, %  "h13 xp yp+20 Checked" . usevXBox, Use vXBox Device (XInput)
		GUI, Add, Radio, %  "h13 xp yp Checked" . usevXBox, Use vXBox Device (XInput)
		
		GUI, Add, GroupBox, Hidden xs+10 yp+20 w90 h50 Section,vJoy Device
		GUI, Add, DropDownList, Hidden xp+10 yp+20 vopvJoyDevice w70, % StrReplace(ValidDevices, vJoyDevice, vJoyDevice . "|")
		; GUI, Add, GroupBox, ys w90 h50,vXBox Device
		GUI, Add, GroupBox, xs ys w90 h50,vXBox Device
		GUI, Add, DropDownList, xp+10 yp+20 vopvXBoxDevice w70, % StrReplace("1|2|3|4|", vXBoxDevice, vXBoxDevice . "|")
		
		GUI, Add, GroupBox, x%SX% yp+45 w%groupBoxWidth% h50,Executable Name
		GUI, Add, Edit, xp+10 yp+20 vopgameName w90, % StrReplace(gameExe, ".exe", "") 
		GUI, Add, Text, x+m yp+3, The executable name for your Ryujinx
		
		GUI, Add, GroupBox, x%SX% yp+35 w%groupBoxWidth% h40,Auto Activate Executable
		GUI, Add, Radio, % "h13 xp+10 yp+20 Group vopautoActivateGame Checked" !autoActivateGame, No
		GUI, Add, Radio, % "h13 x+m Checked" autoActivateGame, Yes
		GUI, Add, Text, x+m, Switch to Ryujinx when toggling controller?

		GUI, Add, GroupBox, x%SX% yp+30 w%groupBoxWidth% h45,Hide Cursor
		GUI, Add, CheckBox, % "h13 xp+10 yp+20 vophideCursor Checked" . hideCursor, Hide cursor when controller toggled on?
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, General>Setup
		GUI, Add, GroupBox, x%SX% y%SY% w%groupBoxWidth% h50 Section, Sensitivity
		GUI, Add, Edit, xs+10 yp+20 w50 vopr gNumberCheck, %r%
		GUI, Add, Text, x+4 yp+3, Lower values correspond to higher sensitivity 

		GUI, Add, GroupBox, xs yp+30 w%groupBoxWidth% h50, Non-Linear Sensitivity
		GUI, Add, Edit, xs+10 yp+20 w50 vopnnp gNumberCheck, %nnp%
		GUI, Add, Text, x+4 yp+3, 1 is Linear ( < 1 makes center more sensitive )
		
		GUI, Add, GroupBox, xs yp+30 w%groupBoxWidth% h50, Deadzone
		GUI, Add, Edit, xs+10 yp+20 w50 vopk gNumberCheck, %k%
		GUI, Add, Text, x+4 yp+3, Range (0 - 1)
		
		GUI, Add, GroupBox, xs yp+30 w%groupBoxWidth% h50, Mouse Check Frequency
		GUI, Add, Edit, xs+10 yp+20 w50 vopfreq Number, %freq%
		GUI, Add, Text, x+4 yp+3, I recommend 50-100 ( Default:75 )
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, General>Hotkeys
		GUI, Add, GroupBox, x%SX% y%SY% w%groupBoxWidth% h50 Section, Toggle Controller On/Off
		GUI, Add, Hotkey, xs+10 yp+20 w50 Limit190 vopcontrollerSwitchKey, % StrReplace(controllerSwitchKey, "#")
		GUI, Add, CheckBox, % "h13 x+m yp+3 vopcontrollerSwitchKeyWin Checked" InStr(controllerSwitchKey, "#"), Use Windows key?
		
		GUI, Add, GroupBox, x%SX% yp+40 w%groupBoxWidth% h50 Section, Toggle Main Set
		GUI, Add, Hotkey, xs+10 yp+20 w50 Limit190 vopmainSetToggleKey, % StrReplace(mainSetToggleKey, "#")
		GUI, Add, CheckBox, % "h13 x+m yp+3 vopmainSetToggleKeyWin Checked" InStr(mainSetToggleKey, "#"), Use Windows key?

		GUI, Add, GroupBox, x%SX% yp+40 w%groupBoxWidth% h50 Section, Reload Application
		GUI, Add, Hotkey, xs+10 yp+20 w50 Limit190 vopreloadKey, % StrReplace(reloadKey, "#")
		GUI, Add, CheckBox, % "h13 x+m yp+3 vopreloadKeyWin Checked" InStr(reloadKey, "#"), Use Windows key?

		GUI, Add, GroupBox, x%SX% yp+40 w%groupBoxWidth% h50 Section, Quit Application
		GUI, Add, Hotkey, xs+10 yp+20 w50 Limit190 vopexitKey, % StrReplace(exitKey, "#")
		GUI, Add, CheckBox, % "h13 x+m yp+3 vopexitKeyWin Checked" InStr(exitKey, "#"), Use Windows key?
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Mouse2Joystick
		GUI, Add, Text, x%SX% y%SY% Section, How are you reading this?!?
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Mouse2Joystick>Axes
		GUI, Add, GroupBox, x%SX% y%SY% w150 h40 Section,Invert X-Axis
		GUI, Add, Radio, % "h13 xp+10 yp+20 Group vopinvertedX Checked" . !invertedX, No
		GUI, Add, Radio, % "h13 x+m Checked" . invertedX, Yes
		
		GUI, Add, GroupBox, xs+230 ys w150 h40,Invert Y-Axis
		GUI, Add, Radio, % "h13 xp+10 yp+20 Group vopinvertedY Checked" . !invertedY, No
		GUI, Add, Radio, % "h13 x+m Checked" . invertedY, Yes
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Mouse2Joystick>Keys
		GUI, Add, GroupBox, x%SX% y%SY% w440 h80 Section, Active KeyLists
		GUI, Add, Edit, xs+10 yp+20 w420 R1 vopjoystickButtonKeyLists, %joystickButtonKeyLists%
		GUI, Add, Button, xs+10 yp+30 w420 gAdvancedSettings, Advanced Settings
		GUI, Add, GroupBox, x%SX% yp+40 w440 h50, Saved KeyLists Manager
		IniRead,allSavedLists,SavedKeyLists.ini
		allSavedLists := StrReplace(allSavedLists, "`n", "|")
		GUI, Add, ComboBox, xs+10 yp+20 w210 vopSaveListName Choose1, %allSavedLists%
		GUI, Add, Button, x+m w60 gLoadSavedList, Load
		GUI, Add, Button, x+m w60 gSaveSavedList, Save
		GUI, Add, Button, x+m w60 gDeleteSavedList, Delete
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Keyboard Movement
		GUI, Add, Text, x%SX% y%SY% Section, How are you reading this?!?
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Keyboard Movement>Keys
		GUI, Add, GroupBox, x%SX% y%SY% w%groupBoxWidth% h120 Section, Keyboard Movement
		GUI, Add, Text, xs+10 yp+25 Right w90, Up:
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopupKey, %upKey%
		GUI, Add, Text, xs+10 yp+25 Right w90, Left:
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopleftKey, %leftKey%
		GUI, Add, Text, xs+10 yp+25 Right w90, Down:
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopdownKey, %downKey%
		GUI, Add, Text, xs+10 yp+25 Right w90, Right:
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 voprightKey, %rightKey%
		
		GUI, Add, GroupBox, xs w%groupBoxWidth% h80, Walking
		GUI, Add, Text, xs+10 yp+20 Right w90, Toggle Walk:
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopwalkToggleKey, %walkToggleKey%
		GUI, Add, Text, x+2 yp+3 Right w20, + :
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopincreaseWalkKey, %increaseWalkKey%
		GUI, Add, Text, x+2 yp+3 Right w20, - :
		GUI, Add, Hotkey, x+2 yp-3 w50 Limit190 vopdecreaseWalkKey, %decreaseWalkKey%
		GUI, Add, Text, xs+10 yp+35 Right w90, Walking Speed:
		GUI, Add, Slider, x+2 yp-8 w180 Range0-100 TickInterval10 Thick12 vopwalkSpeed gWalkSpeedChange AltSubmit, % walkSpeed*100
		GUI, Font, Bold 
		GUI, Add, Text, x+1 yp+8 w40 vopwalkSpeedTxt, % Round(walkSpeed*100) "%"
		GUI, Font

		GUI, Add, GroupBox, Hidden xs w%groupBoxWidth% h50, Gyro Control
		GUI, Add, Text, Hidden xs+10 yp+20 Right w80, Gyro Control:
		GUI, Add, Hotkey, Hidden x+2 yp-3 w50 Limit190 vopgyroToggleKey, %gyroToggleKey%
		; GUI, Font, cBlue Underline
		; GUI, Add, Text, x+15 yp+4 gAndroidPhoneLink, Click Here For Better Options
		; GUI, Font,
	;------------------------------------------------------------------------------------------------------------------------------------------
	GUI, Tab, Extra Settings
		GUI, Add, GroupBox, x%SX% y%SY% w320 h40 Section, Developing...

		GUI, Add, GroupBox, Hidden xs yp+30 w320 h50,Use ZL Lock Toggle Key
		GUI, Add, Radio, % "Hidden h13 xp+10 yp+20 Group voplockZL Checked" . !lockZL, No
		GUI, Add, Radio, % "Hidden h13 x+m Checked" . lockZL, Yes
		GUI, Add, Text, Hidden x+10 Right w80, ZL Lock Key:
		GUI, Add, Hotkey, Hidden x+2 yp-3 w50 Limit190 voplockZLToggleKey, %lockZLToggleKey%
		
		GUI, Font, cRed Bold
		GUI, Add, GroupBox, Hidden xs yp+35 w%groupBoxWidth% h65,EXPERIMENTAL Alternate Mouse Detection
		GUI, Font,
		GUI, Add, CheckBox, % "Hidden h13 xp+10 yp+20 vopuseAltMouseMethod Checked" . useAltMouseMethod, Use Mouse Delta? (Experimental)
		GUI, Add, Text, Hidden xs+10 yp+20 w40 Right, X-Sen:
		GUI, Add, Edit, Hidden x+2 yp-3 vopalt_xSen w40, %alt_xSen%
		GUI, Add, Text, Hidden x+10 yp+3 w30 Right, Y-Sen:
		GUI, Add, Edit, Hidden x+2 yp-3 vopalt_ySen w40, %alt_ySen%
		GUI, Add, Text, Hidden x+3 yp+3 w130 Left, Try 260-400? No Idea...
	GUI, Add, StatusBar
	BuildTree("Main", tree)
	Gui, Main: Show
Return	

TreeClick:
	IF (A_GUIEvent = "S") {
		useSection := selectionPath(A_EventInfo)
		IF (useSection = "Keyboard Movement") {
			useSection := "Keyboard Movement>Keys"
			TV_Modify(findByName(useSection), "Select")
		}
		Else IF (useSection = "Mouse2Joystick") {
			useSection := "Mouse2Joystick>Keys"
			TV_Modify(findByName(useSection), "Select")
		}
		SB_SetText(useSection)
		GUIControl, Choose, TabControl, %useSection%
	}
Return

WalkSpeedChange:
	GUIControlGet,tmpSpeed,,opwalkSpeed
	GUIControl,,opwalkSpeedTxt, %tmpSpeed%`%
Return

MainGUIClose:
	GUI, Main:Destroy
Return

mainExit:
	Gui, Main:Hide
mainSave:
	Gui, Main:Submit, NoHide
	Gosub, SubmitAll
	; Get old hotkeys.
	; Disable old hotkeys
	IF (controllerSwitchKey)
		Hotkey,%controllerSwitchKey%,controllerSwitch, off
	IF (mainSetToggleKey)
		Hotkey,%mainSetToggleKey%,toggleMainSet, off
	IF (reloadKey)
		Hotkey,%reloadKey%,reloadFunc, off
	IF (exitKey)
		Hotkey,%exitKey%,exitFunc, off

	; Joystick buttons
	Hotkey, If, (!toggle && mouse2joystick)
	IF (walkToggleKey)
		HotKey,%walkToggleKey%,toggleHalf, Off
	IF (decreaseWalkKey)
		HotKey,%decreaseWalkKey%,decreaseWalk, Off
	IF (increaseWalkKey)
		HotKey,%increaseWalkKey%,increaseWalk, Off
	IF (lockZLToggleKey AND lockZL)
		HotKey,%lockZLToggleKey%,toggleAimLock, Off
	IF (gyroToggleKey) {
		HotKey,%gyroToggleKey%, GyroControl, off
		HotKey,%gyroToggleKey% Up, GyroControlOff, off
	}
	Hotkey,%upKey%, overwriteUp, off
	Hotkey,%upKey% Up, overwriteUpup, off
	Hotkey,%leftKey%, overwriteLeft, off
	Hotkey,%leftKey% Up, overwriteLeftup, off
	Hotkey,%downKey%, overwriteDown, off
	Hotkey,%downKey% Up, overwriteDownup, off
	Hotkey,%rightKey%, overwriteRight, off
	Hotkey,%rightKey% Up, overwriteRightup, off
	Hotkey, If
	For setIdx, in joystickButtonKeyArray
		Gosub, forceUnBindSet

	; Read settings.
	IniRead,allSections,settings.ini
	Loop,Parse,allSections,`n
	{
		IniRead,pairs,settings.ini,%A_LoopField%
		Loop,Parse,pairs,`n
		{
			StringSplit,keyValue,A_LoopField,=
			%keyValue1%:=keyValue2
		}
	}

	pmX:=invertedX ? -1:1											; Sign for inverting axis
	pmY:=invertedY ? -1:1

	; Enable new hotkeys
	IF (controllerSwitchKey)
		Hotkey,%controllerSwitchKey%,controllerSwitch, on
	IF (reloadKey)
		Hotkey,%reloadKey%,reloadFunc, on
	IF (exitKey)
		Hotkey,%exitKey%,exitFunc, on
	IF (mouse2joystick) {
		GoSub, initCvJoyInterface
		GoSub, mouse2joystickHotkeys
	}
	IF (mainSetToggleKey) {
		Gosub, keyList2Array
		Hotkey,%mainSetToggleKey%,toggleMainSet, on
	}
Return

SubmitAll:
	;FileDelete, settings.ini ; Should I just delete the settings file before writing all settings to it? Guarantees a clean file, but doesn't allow for hidden options...
	; Write General
	IniWrite, % opusevXBox - 1, settings.ini, General, usevXBox
	IniWrite, % opvJoyDevice, settings.ini, General, vJoyDevice
	IniWrite, % opvXBoxDevice, settings.ini, General, vXBoxDevice
	IniWrite, % opgameName . ".exe", settings.ini, General, gameExe
	IniWrite, % opautoActivateGame - 1, settings.ini, General, autoActivateGame
	IniWrite, % ophideCursor, settings.ini, General, hideCursor
	; Write General>Setup
	IniWrite, % opr, settings.ini, General>Setup, r
	IniWrite, % opnnp, settings.ini, General>Setup, nnp
	IniWrite, % opk, settings.ini, General>Setup, k
	IniWrite, % opfreq, settings.ini, General>Setup, freq
	; Write General>Hotkeys
	IniWrite, % opcontrollerSwitchKeyWin ? "#" . opcontrollerSwitchKey : opcontrollerSwitchKey, settings.ini, General>Hotkeys, controllerSwitchKey
	IniWrite, % opmainSetToggleKeyWin ? "#" . mainSetToggleKey : mainSetToggleKey, settings.ini, General>Hotkeys, mainSetToggleKey
	IniWrite, % opreloadKeyWin ? "#" . opreloadKey : opreloadKey, settings.ini, General>Hotkeys, reloadKey
	IniWrite, % opexitKeyWin ? "#" . opexitKey : opexitKey, settings.ini, General>Hotkeys, exitKey
	; Write Mouse2Joystick>Axes
	IniWrite, % opinvertedX - 1, settings.ini, Mouse2Joystick>Axes, invertedX
	IniWrite, % opinvertedY - 1, settings.ini, Mouse2Joystick>Axes, invertedY
	; Write Mouse2Joystick>Keys
	IniWrite, % opjoystickButtonKeyLists, settings.ini, Mouse2Joystick>Keys, joystickButtonKeyLists
	; Write Keyboard Movement>Keys
	IniWrite, % opupKey, settings.ini, Keyboard Movement>Keys, upKey
	IniWrite, % opleftKey, settings.ini, Keyboard Movement>Keys, leftKey
	IniWrite, % opdownKey, settings.ini, Keyboard Movement>Keys, downKey
	IniWrite, % oprightKey, settings.ini, Keyboard Movement>Keys, rightKey
	IniWrite, % opwalkToggleKey, settings.ini, Keyboard Movement>Keys, walkToggleKey
	IniWrite, % opincreaseWalkKey, settings.ini, Keyboard Movement>Keys, increaseWalkKey
	IniWrite, % opdecreaseWalkKey, settings.ini, Keyboard Movement>Keys, decreaseWalkKey
	IniWrite, % Round(opwalkSpeed/100, 2), settings.ini, Keyboard Movement>Keys, walkSpeed
	IniWrite, % opgyroToggleKey, settings.ini, Keyboard Movement>Keys, gyroToggleKey
	; Write Extra Settings
	IniWrite, % oplockZL- 1, settings.ini, Extra Settings, lockZL
	IniWrite, % oplockZLToggleKey, settings.ini, Extra Settings, lockZLToggleKey
	IniWrite, % opuseAltMouseMethod, settings.ini, Extra Settings, useAltMouseMethod
	IniWrite, % opalt_xSen, settings.ini, Extra Settings, alt_xSen
	IniWrite, % opalt_ySen, settings.ini, Extra Settings, alt_ySen
Return

selectionPath(ID) {
	TV_GetText(name,ID)
	IF (!name)
		Return 0
	parentID := ID
	Loop
	{
		parentID := TV_GetParent(parentID)
		IF (!parentID)
			Break
		parentName=
		TV_GetText(parentName, parentID)
		IF (parentName)
			name := parentName ">" name
	}
	Return name
}

findByName(Name){
	retID := False
	ItemID = 0  ; Causes the loop's first iteration to start the search at the top of the tree.
	Loop
	{
		ItemID := TV_GetNext(ItemID, "Full")  ; Replace "Full" with "Checked" to find all checkmarked items.
		IF (!ItemID)  ; No more items in tree.
			Break
		temp := selectionPath(ItemID)
		IF (temp = Name) {
			retID := ItemID
			Break
		}
	}
	Return retID
}

BuildTree(aGUI, treeString, oParent := 0) {
	Static pParent := []
	Static Call := 0
	Loop, Parse, treeString, `n, `r
	{
		startingString := A_LoopField
		temp := StrSplit(startingString, ",")
		Loop % temp.MaxIndex()
		{
			useString := Trim(temp[A_Index])
			IF (!useString)
				Continue
			Else IF (useString = "||") {
				useIndex := A_Index+1
				While (useIndex < temp.MaxIndex() + 1) {
					useRest .= "," . temp[useIndex]
					useIndex++
				}
				useRest := SubStr(useRest, 2)
				BuildTree(aGUI, useRest, pParent[--Call])
				Break
			}
			Else IF InStr(useString, "|") {
				newTemp := StrSplit(useString, "|")
				pParent[Call++] := oParent
				uParent := TV_Add(newTemp[1], oParent, (oParent = 0 ) ? "Expand" : "")
				useRest := RegExReplace(useString, newTemp[1] . "\|(.*)$", "$1")
				useIndex := A_Index+1
				While (useIndex < temp.MaxIndex() + 1) {
					useRest .= "," . temp[useIndex]
					useIndex++
				}
				BuildTree(aGUI, useRest, uParent)
				Break
			}
			Else
				TV_Add(useString, oParent)
		}
	}
}

NumberCheck(hEdit) {
    static PrevNumber := []

    ControlGet, Pos, CurrentCol,,, ahk_id %hEdit%
    GUIControlGet, NewNumber,, %hEdit%
    StrReplace(NewNumber, ".",, Count)

    If NewNumber ~= "[^\d\.-]|^.+-" Or Count > 1 { ; BAD
        GUIControl,, %hEdit%, % PrevNumber[hEdit]
        SendMessage, 0xB1, % Pos-2, % Pos-2,, ahk_id %hEdit%
    }

    Else ; GOOD
        PrevNumber[hEdit] := NewNumber
}

; AndroidPhoneLink:
; 	Run, https://sshnuke.net/cemuhook/padudpserver.html
; Return

LoadSavedList:
	GUIControlGet, slName,, opSaveListName
	IniRead, ldKeyLists, SavedKeyLists.ini, %slName%, KeyLists
	IF (ldKeyLists != "ERROR")
		GUIControl,, opjoystickButtonKeyLists, %ldKeyLists%
Return

SaveSavedList:
	GUIControlGet, slName,, opSaveListName
	IF (!slName) {
		MsgBox, Please enter anything as an identifier
		Return
	}
	GUIControlGet, slList,, opjoystickButtonKeyLists
	IniWrite, %slList%, SavedKeyLists.ini, %slName%, KeyLists
	IniRead,allSavedLists,SavedKeyLists.ini
	allSavedLists := StrReplace(allSavedLists, "`n", "|")
	GUIControl,, opSaveListName, % "|" . allSavedLists
	GUIControl, Text, opSaveListName, %slName%
Return

DeleteSavedList:
	GUIControlGet, slName,, opSaveListName
	IniDelete, SavedKeyLists.ini, %slName%
	IniRead,allSavedLists,SavedKeyLists.ini
	allSavedLists := StrReplace(allSavedLists, "`n", "|")
	GUIControl,, opSaveListName, % "|" . allSavedLists
	GuiControl, Choose, opSaveListName, 1
Return

; Default settings in case problem reading/writing to file.
setSettingsToDefault:
	pairsDefault=
	(
		usevXBox=1
		vJoyDevice=1
		vXBoxDevice=1
		gameExe=Ryujinx.exe
		autoActivateGame=1
		hideCursor=1
		r=300
		k=0
		freq=50
		nnp=.8
		controllerSwitchKey=F1
		mainSetToggleKey=F2
		reloadKey=F3
		exitKey=F4
		invertedX=0
		invertedY=0
		joystickButtonKeyLists=Space^1^^,e^1^^|RButton & LButton^^^,LButton^^^|XButton2 & Tab^^^|v & Tab^^^|b & Tab^^^|Tab^1^1^,LShift^^^,q^^^,r^^^,RButton^^^|r & XButton2^^^|r & XButton1^^^,f^^^,4^2^1^,5^2^1^,z^^^,c^^^,r & WheelUp^^^|XButton2^^^,r & WheelDown^^^|XButton1^^^,r & LButton^^^|v^^1^,r & RButton^^^|b^^1^,v & RButton^^^|b & RButton^^^|q & RButton^^^200|XButton2 & RButton^^1^,q & XButton2^^^200,q & WheelUp^^^,,v & LButton^^^|b & LButton^^^|q & LButton^^^200|XButton2 & LButton^^1^,,q & WheelDown^^^,q & XButton1^1^1^200:Space^1^^|RButton^2^1^,LButton^^^|e^^^,Tab^^^,LShift^^^,q^^^,r^^^,,,4^2^1^,5^2^1^,,c^2^^,XButton2^^^,XButton1^^^,v^^^,b^^^,,,WheelUp^^^,,,,WheelDown^^^,::::::
		upKey=w
		leftKey=a
		downKey=s
		rightKey=d
		walkToggleKey=CapsLock
		increaseWalkKey=NumpadAdd
		decreaseWalkKey=NumpadSub
		walkSpeed=0.50
		gyroToggleKey=
		lockZL=0
		lockZLToggleKey=
		BotWmotionAim=0
		useAltMouseMethod=0
		alt_xSen=400
		alt_ySen=280
	)
	Loop,Parse,pairsDefault,`n
	{
		StringSplit,keyValue,A_LoopField,=
		%keyValue1%:=keyValue2
	}
	Goto, readSettingsSkippedDueToError
Return

#IF AdvancedSettingsRunning(setToggle)
#IF
AdvancedSettings:
	Hotkey, IF, AdvancedSettingsRunning(setToggle)
	HotKey, RButton, getControl, On
	Hotkey, IF
	GUI, Main:Default
	waitKey := "■■■"
	addNewKey := "■■■■■■■■■■■■■"
	blankOptions := "^^^"
	blankKeyList := ",,,,,,,,,,,,,,,,,,,,,,,"
	numSets := 8
	currSetGUI := 0
	browseMode := [] ; 0 = edit mode, 1 = browse mode, 2 = initialize browse mode
	keyGroupList := {}
	joyButtonNameList := []
	Gosub, getJoyButtonName
	GUIControlGet, getKeyLists,, opjoystickButtonKeyLists
	; getKeyLists := StrReplace(getKeyLists, "~", "")
	Loop, Parse, getKeyLists, :
	{
		setGUI := A_Index
		joystickButtonKeyList := A_LoopField
		If (joystickButtonKeyList = "")
			joystickButtonKeyList := blankKeyList
		Loop, Parse, joystickButtonKeyList, CSV
		{
			joyBtnNum := A_Index
			keyGroup := A_LoopField
			keyGroupList[setGUI, joyBtnNum] := keyGroup ? keyGroup . "|" : ""
		}
	}
	IF (vXBox) {
		textWidth := 80
		numEdits := 24
	}
	Else {
		textWidth := 50
		numEdits := 18
	}
	setToggle := False
	GUI, Main:+Disabled
	GUI, AdvancedSettings:New, +HWNDAdvancedSettingsHWND +OwnerMain -MinimizeBox
	GUI, Margin, 10, 7.5
	GUI, Font,, Lucida Sans Typewriter ; Courier New
	GUI, Add, Text, W0 H0 vLoseFocus, Hidden
	Gosub, initControls
	currSetGUI := 1
	GUI, Add, GroupBox, xm+6 yp+35 W329 H40 Section, Set Index
	GUI, Add, Radio, h13 xp+10 yp+20 Group Checked1 gtoggleSet, 1
	Loop, % numSets - 1
	{
		GUI, Add, Radio, h13 x+m gtoggleSet, % A_Index + 1
	}
	GUI, Add, Button, W87 H35 xp+154 yp-15 gSaveButton, Save
	GUI, Add, Button, W87 H35 x+9 gCancelButton, Cancel
	GUI, Add, Button, W87 H35 x+9 gClearButton, Clear		
	GUI, Show, W850, Advanced Settings
	GuiControl, Focus, LoseFocus
Return

getjoyButtonName:
	joyButtonNameList := StrSplit("B,A,Y,X,L,R,ZL,ZR,+,−,L-Click,R-Click,D-Up,D-Down,D-Left,D-Right,R-→,R-↗,R-↑,R-↖,R-←,R-↙,R-↓,R-↘", ",")
Return

disableEdit:
	GuiControl, Disabled, optogToSet%currjoyBtnNum%
	GuiControl, Disabled, opdisMmState%currjoyBtnNum%
	GuiControl, Disabled, opholdDelay%currjoyBtnNum%
	GuiControl, Disabled, ophDUD%currjoyBtnNum%
Return

enableEdit:
	GuiControl, Enabled, optogToSet%currjoyBtnNum%
	GuiControl, Enabled, opdisMmState%currjoyBtnNum%
	GuiControl, Enabled, opholdDelay%currjoyBtnNum%
	GuiControl, Enabled, ophDUD%currjoyBtnNum%
Return

; Input validation for hold delay. The gFunc on the UpDown control is automatically called when the GUI shows, and I(Alchemist233) don't know how to avoid it.
hDValidate:
	GUIControlGet, holdDelay,, % A_GuiControl
	If (!(holdDelay ~= "^[0-9]{1,3}$") OR holdDelay < 0)
		GuiControl, , % A_GuiControl, 0
	Else If (holdDelay > 500)
		GuiControl, , % A_GuiControl, 500
Return

; Input validation for key name. Not support ',' or '='.
keyNameValidate:
	currjoyBtnNum := SubStr(A_GuiControl, 9)
	GUIControlGet, keyName,, % A_GuiControl
	GUIControlGet, keyName1,, opkey1st%currjoyBtnNum%
	GUIControlGet, keyName2,, opkey2nd%currjoyBtnNum%
	If (keyName = waitKey)
		Gui, Font, c42e226 s14,
	Else If (keyName != "") {
		Gui, Font, , 
		If ((vk := GetKeyVK(keyName)) = 0 OR vk = 187 OR vk = 188)
			GuiControl, , % A_GuiControl,
	}
	GuiControl, Font, % A_GuiControl
	If (InStr(keyName1, "wheel")) {
		GuiControl, Disabled, opkey2nd%currjoyBtnNum%
		Gosub, disableEdit
	}
	Else If (InStr(keyName2, "wheel")) {
		GuiControl, Enabled, opkey2nd%currjoyBtnNum%
		Gosub, disableEdit
	}
	Else {
		GuiControl, Enabled, opkey2nd%currjoyBtnNum%
		Gosub, enableEdit
	}
Return

hideControls:
	If (!browseMode[currjoyBtnNum])
		browseMode[currjoyBtnNum] := 1
	GuiControl,, opeditBtn%currjoyBtnNum%, ✏️
	GuiControl,, opdelBtn%currjoyBtnNum%, -
	GuiControl, Show, opkeyInfo%currjoyBtnNum%
	GuiControl, Hide, opkey1st%currjoyBtnNum%
	GuiControl, Hide, opkey2nd%currjoyBtnNum%
	GuiControl, Hide, optogToSet%currjoyBtnNum%
	GuiControl, Hide, opdisMmState%currjoyBtnNum%
	GuiControl, Hide, opholdDelay%currjoyBtnNum%
	GuiControl, Hide, ophDUD%currjoyBtnNum%
Return

showControls:
	browseMode[currjoyBtnNum] := 0
	GuiControl,, opeditBtn%currjoyBtnNum%, √️
	GuiControl,, opdelBtn%currjoyBtnNum%, ×
	GuiControl, Hide, opkeyInfo%currjoyBtnNum%
	GuiControl, Show, opkey1st%currjoyBtnNum%
	GuiControl, Show, opkey2nd%currjoyBtnNum%
	GuiControl, Show, optogToSet%currjoyBtnNum%
	GuiControl, Show, opdisMmState%currjoyBtnNum%
	GuiControl, Show, opholdDelay%currjoyBtnNum%
	GuiControl, Show, ophDUD%currjoyBtnNum%
Return

; Dynamically load editing controls
addControls:
	GUI, Add, Edit, % "W66 x" . (currjoyBtnNum > 12 ? 564 : 164) . " y" . (currjoyBtnNum > 12 ? (currjoyBtnNum * numEdits - 302) : (currjoyBtnNum * numEdits - 14)) . " Center ReadOnly -TabStop gkeyNameValidate vopkey1st" . currjoyBtnNum,
	GUI, Add, Edit, % "W66 x+m yp Center ReadOnly -TabStop gkeyNameValidate vopkey2nd" . currjoyBtnNum,
	Gui, Add, DropDownList, % "W29 x+m yp -TabStop voptogToSet" . currjoyBtnNum, 0|1|2|3|4|5|6|7|8|
	Gui, Add, DropDownList, % "W29 x+m yp -TabStop vopdisMmState" . currjoyBtnNum, 0|1|
	Gui, Add, Edit, % "W40 x+m Center -TabStop ghDValidate vopholdDelay" . currjoyBtnNum,
	Gui, Add, UpDown, % "Range0-500 vophDUD" . currjoyBtnNum, 0
Return

; Toggle between editing or browsing state for '✏' button
editOrSubmit:
	currjoyBtnNum := SubStr(A_GuiControl, 10)
	GuiControlGet, keyInfoEdit,, opkeyInfo%currjoyBtnNum%
	keyInfoArray := StrSplit(keyInfoEdit = addNewKey ? blankOptions : keyInfoEdit , "^")
	If (browseMode[currjoyBtnNum]) {
		If (browseMode[currjoyBtnNum] = 2)
			Gosub, addControls
		Gosub, showControls
		keyName := StrSplit(keyInfoArray[1] , "&", " `t")
		GuiControl,, opkey1st%currjoyBtnNum%, % keyName[1]
		GuiControl,, opkey2nd%currjoyBtnNum%, % keyName[2]
		GuiControl, ChooseString, optogToSet%currjoyBtnNum%, % keyInfoArray[2] ? keyInfoArray[2] : 0
		GuiControl, ChooseString, opdisMmState%currjoyBtnNum%, % keyInfoArray[3] ? keyInfoArray[3] : 0
		GuiControl,, opholdDelay%currjoyBtnNum%, % keyInfoArray[4] ? keyInfoArray[4] : 0
	}
	Else {
		Gosub, hideControls
		GUIControlGet, keyName1,, opkey1st%currjoyBtnNum%
		GUIControlGet, keyName2,, opkey2nd%currjoyBtnNum%
		GUIControlGet, togToSet,, optogToSet%currjoyBtnNum%
		GUIControlGet, disMmState,, opdisMmState%currjoyBtnNum%
		GUIControlGet, holdDelay,, opholdDelay%currjoyBtnNum%
		If (keyName1 = waitKey)
			keyName1 := ""
		If (keyName2 = waitKey)
			keyName2 := ""
		If (keyName1 = keyName2) {
			If (keyName1 = "")
				Return
			keyName2 := ""
		}
		doubleKey := keyName1 = "" OR keyName2 = "" ? "" : " & "
		If (InStr(keyName1, "wheel"))
			newKeyInfo := keyName1 . blankOptions
		Else If (InStr(keyName2, "wheel"))
			newKeyInfo := keyName1 . doubleKey . keyName2 . blankOptions
		Else {
			If (!togToSet)
				togToSet := ""
			If (!disMmState)
				disMmState := ""
			If (!holdDelay)
				holdDelay := ""
			newKeyInfo := keyName1 . doubleKey . keyName2 . "^" . togToSet . "^" . disMmState . "^" . holdDelay
		}
		Gosub, delDupKeyInfos
		tempInfos := keyGroupList[currSetGUI, currjoyBtnNum]
		If ((keyInfoEdit = addNewKey) OR (keyInfoArray[1] = newKeyName))
			tempInfos .= newKeyInfo . "|"
		Else
			tempInfos := StrReplace(tempInfos, keyInfoEdit, newKeyInfo)
		keyGroupList[currSetGUI, currjoyBtnNum] := tempInfos
		GuiControl,, opkeyInfo%currjoyBtnNum%, % "|" . tempInfos . addNewKey
		GuiControl, ChooseString, opkeyInfo%currjoyBtnNum%, %newKeyInfo%
	}
Return

; Toggle between editing or browsing state for '-' button
delOrCancel:
	currjoyBtnNum := SubStr(A_GuiControl, 9)
	GuiControlGet, keyInfoDel,, opkeyInfo%currjoyBtnNum%
delDstKeyInfo:
    If (!browseMode[currjoyBtnNum]) {
		Gosub, hideControls
		Return
    }
	tempInfos := keyGroupList[currSetGUI, currjoyBtnNum]
	If (!tempInfos)
		Return
	tempInfoDel := "|" . keyInfoDel . "|"
	If (InStr(tempInfos, tempInfoDel))
		tempInfos := StrReplace(tempInfos, tempInfoDel, "|")
	Else
		tempInfos := StrReplace("|" . tempInfos, tempInfoDel, "")
	keyGroupList[currSetGUI, currjoyBtnNum] := tempInfos
	GuiControl,, opkeyInfo%currjoyBtnNum%, % "|" . tempInfos . addNewKey
	GuiControl, Choose, opkeyInfo%currjoyBtnNum%, 1
Return

; Delete duplicate KeyInfos
delDupKeyInfos:
	tempNum := currjoyBtnNum
	newKeyName := StrSplit(newKeyInfo , "^")[1]
	For joyBtnNum, keyGroup in keyGroupList[currSetGUI]
	{
		Loop, Parse, keyGroup, |
		{
			keyInfoDel := A_LoopField
			If (!keyInfoDel OR (newKeyName != StrSplit(keyInfoDel , "^")[1]))
				Continue
			currjoyBtnNum := joyBtnNum
			dstCurrMode := browseMode[joyBtnNum]
			Gosub, delDstKeyInfo
			If (!dstCurrMode) 
				Gosub, delDstKeyInfo
		}
	}
	currjoyBtnNum := tempNum
Return

; Toggle key set. Generate browsing mode controls
toggleSet:
	currSetGUI := A_GuiControl
	clearTag := -1
ClearButton:
	clearTag++
initControls:
	Loop, % numEdits
	{
		currjoyBtnNum := A_Index
		If (!currSetGUI) {
			browseMode[currjoyBtnNum] := 2
			GUI, Add, Text, % "W" . textWidth . " xs" . ((currjoyBtnNum = numEdits // 2 + 1) ? "+400 ys+7 Section" : "") . " Right", % joyButtonNameList[currjoyBtnNum]
			GUI, Add, Button, W22 H22 x+m yp-5 vopeditBtn%currjoyBtnNum% geditOrSubmit,
			GUI, Add, Button, W22 H22 x+m yp vopdelBtn%currjoyBtnNum% gdelOrCancel,
			Gui, Add, DropDownList, W181 x+m yp+1 -TabStop vopkeyInfo%currjoyBtnNum%,
		}
		Gosub, hideControls
		If (clearTag)
			keyGroupList[currSetGUI, currjoyBtnNum] := ""
		GuiControl,, opkeyInfo%currjoyBtnNum%, % "|" . keyGroupList[currSetGUI ? currSetGUI : 1, currjoyBtnNum] . addNewKey
		GuiControl, Choose, opkeyInfo%currjoyBtnNum%, 1
	}
Return

CancelButton:
AdvancedSettingsGUIClose:
	IF (setToggle)
		Return
	getKeyLists := ""
	browseMode := []
	keyInfoArray := []
	joyButtonNameList := []
	keyGroupList := {}
	; modKeyList := {}
	Hotkey, IF, AdvancedSettingsRunning(setToggle)
	HotKey, RButton, getControl, Off
	Hotkey, IF
	GUI, Main:-Disabled
	GUI, AdvancedSettings:Destroy
Return

; (Disabled) Get mod keys for adding tildes
getModKeyList:
	modKeyList := {}
	Loop, % numSets
	{
		setGUI := A_Index
		modKeyList.Push([])
		For joyBtnNum, keyGroup in keyGroupList[setGUI]
		{
			If (!keyGroup OR !InStr(keyGroup, "&"))
				Continue
			Loop, Parse, keyGroup, |
			{
				keyInfo := A_LoopField
				If (!keyInfo OR !InStr(keyInfo, "&"))
					Continue
				keyName := StrSplit(keyInfo, "&", " `t")[1]
				tag := 1
				For modKeyNum, modKey in modKeyList[setGUI]
				{
					If (keyName = modKey) {
						tag := 0
						Break
					}
				}
				If (tag)
					modKeyList[setGUI].Push(keyName)
			}
		}
	}
Return

; Assemble and save new keyLists, exit AdvancedSettings.
SaveButton:
assembleKeyLists:
	joystickButtonKeyLists := ""
	Loop, % numSets
	{
		setGUI := A_Index
		For joyBtnNum, keyGroup in keyGroupList[setGUI]
		{
			; If (keyGroup) {
			; 	Loop, Parse, keyGroup, |
			; 	{
			; 		keyInfo := A_LoopField
			; 		If (keyInfo) {
			; 			keyName := StrSplit(keyInfo, "^")[1]
			; 			For modKeyNum, modKey in modKeyList[setGUI]
			; 			{
			; 				If (keyName = modKey) {
			; 					keyInfo := "~" . keyInfo
			; 					Break
			; 				}
			; 			}
			; 		}
			; 		joystickButtonKeyLists .= keyInfo . "|"
			; 	}
			; }
			joystickButtonKeyLists .= SubStr(keyGroup, 1, StrLen(keyGroup) - 1)
			If (joyBtnNum < numEdits)
				joystickButtonKeyLists .= ","
		}
		If (setGUI < numSets)
			joystickButtonKeyLists .= ":"
	}
	; joystickButtonKeyLists := StrReplace(StrReplace(joystickButtonKeyLists, blankKeyList, ""), "||", "")
	joystickButtonKeyLists := StrReplace(joystickButtonKeyLists, blankKeyList, "")
exitAdvancedSettings:
	GUI, Main:Default
	GUIControl,, opjoystickButtonKeyLists, %joystickButtonKeyLists%
	GoSub, AdvancedSettingsGUIClose
Return

AdvancedSettingsRunning(setTog){
	Return (WinActive("Advanced Settings") AND !setTog)
}

getControl:
	GUI, AdvancedSettings:Default
	; KeyWait, LButton
	setToggle := True
	MouseGetPos,,, mouseWin, useControl, 1
	IF (InStr(useControl, "Edit") AND Mod(StrReplace(useControl, "Edit", ""), 3) != 0 AND mouseWin = AdvancedSettingsHWND)
		GetKey()
	setToggle := False
clearFocus:
	GuiControl, Focus, LoseFocus
Return

GetKey() {
	Global
	GoSub, TurnOn
	MousePressed := False
	GUIControl, -E0x200, %useControl%
	GuiControl, , %useControl%, % waitKey
	ih.Start()
	ErrorLevel := ih.Wait()
	singleKey := ih.EndKey
	GoSub, TurnOff
	IF (MousePressed)
		singleKey := MousePressed
	; singleKey := RegexReplace(singleKey, "Control", "Ctrl")
	GuiControl, , %useControl%, %singleKey%
	GUIControl, +E0x200, %useControl%
	Return singleKey
}

WM_LBUTTONDOWN() {
	Global useControl, MousePressed, ih
	ih.Stop()
	MousePressed := "LButton"
	Return 0
}

WM_RBUTTONDOWN() {
	Global useControl, MousePressed, ih
	ih.Stop()
	MousePressed := "RButton"
	Return 0
}

WM_MBUTTONDOWN() {
	Global useControl, MousePressed, ih
	ih.Stop()
	MousePressed := "MButton"
	Return 0
}

WM_XBUTTONDOWN(w) {
	Global useControl, MousePressed, ih
	ih.Stop()
	SetFormat, IntegerFast, Hex
	IF ((w & 0xFF) = 0x20)
		MousePressed := "XButton1"
	Else IF((w & 0xFF) = 0x40)
		MousePressed := "XButton2"
	Return 0
}

WM_MOUSEHWHEEL(w) {
	Global useControl, MousePressed, ih
	ih.Stop()
	SetFormat, IntegerFast, Hex
	IF ((w & 0xFF0000) = 0x780000)
		MousePressed := "WheelRight"
	Else IF((w & 0xFF0000) = 0x880000)
		MousePressed := "WheelLeft"
	Return 0
}

WM_MOUSEWHEEL(w) {
	Global useControl, MousePressed, ih
	ih.Stop()
	SetFormat, IntegerFast, Hex
	MousePressed := "" . w + 0x0
	IF ((w & 0xFF0000) = 0x780000)
		MousePressed := "WheelUp"
	Else IF((w & 0xFF0000) = 0x880000)
		MousePressed := "WheelDown"
	Return 0
}

TurnOn:
	OnMessage(0x0201, "WM_LBUTTONDOWN")
	OnMessage(0x0204, "WM_RBUTTONDOWN")
	OnMessage(0x0207, "WM_MBUTTONDOWN")
	OnMessage(0x020B, "WM_XBUTTONDOWN")
	OnMessage(0x020E, "WM_MOUSEHWHEEL")
	OnMessage(0x020A, "WM_MOUSEWHEEL")
Return

TurnOff:
	OnMessage(0x0201, "")
	OnMessage(0x0204, "")
	OnMessage(0x0207, "")
	OnMessage(0x020B, "")
	OnMessage(0x020E, "")
	OnMessage(0x020A, "")
Return

;-------------------------------------------------------------------------------
show_Mouse(bShow := True) { ; show/hide the mouse cursor
;-------------------------------------------------------------------------------
	; https://autohotkey.com/boards/viewtopic.php?p=173707#p173707
    ; WINAPI: SystemParametersInfo, CreateCursor, CopyImage, SetSystemCursor
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms724947.aspx
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648385.aspx
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648031.aspx
    ; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648395.aspx
    ;---------------------------------------------------------------------------
    static BlankCursor
    static CursorList := "32512, 32513, 32514, 32515, 32516, 32640, 32641"
        . ",32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650, 32651"
    local ANDmask, XORmask, CursorHandle

    IF (bShow) ; shortcut for showing the mouse cursor
        Return, DllCall("SystemParametersInfo"
            , "UInt", 0x57              ; UINT  uiAction    (SPI_SETCURSORS)
            , "UInt", 0                 ; UINT  uiParam
            , "Ptr",  0                 ; PVOID pvParam
            , "UInt", 0)                ; UINT  fWinIni

    IF (!BlankCursor) { ; create BlankCursor only once
        VarSetCapacity(ANDmask, 32 * 4, 0xFF)
        VarSetCapacity(XORmask, 32 * 4, 0x00)
        BlankCursor := DllCall("CreateCursor"
            , "Ptr", 0                  ; HINSTANCE  hInst
            , "Int", 0                  ; int        xHotSpot
            , "Int", 0                  ; int        yHotSpot
            , "Int", 32                 ; int        nWidth
            , "Int", 32                 ; int        nHeight
            , "Ptr", &ANDmask           ; const VOID *pvANDPlane
            , "Ptr", &XORmask)          ; const VOID *pvXORPlane
    }

    ; set all system cursors to blank, each needs a new copy
    Loop, Parse, CursorList, CSV, %A_Space%
    {
        CursorHandle := DllCall("CopyImage"
            , "Ptr", BlankCursor        ; HANDLE hImage
            , "UInt", 2                 ; UINT   uType      (IMAGE_CURSOR)
            , "Int",  0                 ; int    cxDesired
            , "Int",  0                 ; int    cyDesired
            , "UInt", 0)                ; UINT   fuFlags
        DllCall("SetSystemCursor"
            , "Ptr", CursorHandle       ; HCURSOR hcur
            , "UInt",  A_Loopfield)     ; DWORD   id
    }
}

LockMouseToWindow(llwindowname="") {
  IF (!llwindowname) {
	DllCall("ClipCursor", "UInt", 0)
	Return False
  }
  WinGetPos, llX, llY, llWidth, llHeight, %llwindowname%
  VarSetCapacity(llrectA, 16)
  IF (llWidth AND llHeight) {
	NumPut(llX+10,&llrectA+0),NumPut(llY+54,&llrectA+4),NumPut(llWidth-10 + llX,&llrectA+8),NumPut(llHeight-10 + llY,&llrectA+12)
	DllCall("ClipCursor", "UInt", &llrectA)
	Return True
  }
}

installBus:
	InstallUninstallScpVBus(True)
Return
uninstallBus:
	InstallUninstallScpVBus(False)
Return

InstallUninstallScpVBus(state:="ERROR") {
	IF (state == "ERROR")
		Return
	IF (state){
		RunWait, *Runas devcon.exe install ScpVBus.inf root\ScpVBus, % A_ScriptDir "\ScpVBus", UseErrorLevel Hide
		MsgBox,, Done Installing, reloading the script., 1
	} Else {
		RunWait, *Runas devcon.exe remove root\ScpVBus, % A_ScriptDir "\ScpVBus", UseErrorLevel Hide
		IniWrite,0, settings.ini, General, usevXBox ; Turn off the setting for future runs as well.
		MsgBox,, Done Un-Installing, reloading the script., 1
	}
	IF (ErrorLevel == "ERROR")
		return 0
	Reload
}