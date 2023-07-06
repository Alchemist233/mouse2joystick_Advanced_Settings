
# The project is renamed to mouse2joystick_Advanced_Settings and add new features
## Version 1.0.0.0
 * You can specify a key combination of up to two keys to simulate a joy button.
 * You can specify multiple keys or key combinations to simulate the same joy button.
 * You can specify when the key is held down or after pressing the mouse to pause the simulated right stick.
 * You can add a delay of 1-500ms to the keys, and even if the keys are actually released, they will still be considered held down for a while.
 * You can press the toggle key to disable current set, and specify another set to enable.

***
# Script last updated on May 20, 2020.
Version 0.4.1.4

 * Added ability to map the mouse wheel to keys in the keylist helper
 	* Wheel keys can't be used to hold down buttons, since wheels don't send an UP keystroke like all the other keys.
 * Added a Save button to the settings, so you can save and apply your settings without closing the window. This should make it easier to tweak and play with settings while testing.
 * Added ability to adjust the walking speed, no longer set to 50%. [Keybinds work on the fly as you are moving.](https://imgur.com/25brjqd)
 	* You can change the speed by setting and pressing the `+` and `-` keybinds
 * I believe I have finally fixed the controller profiles for the Wii U Pro Controller for both vJoy and vXbox.

&nbsp;

Older Changes:
 * Completely re-wrote settings code
 	* Allows me to more easily manage adding and/or changing the settings for the script
 * [Added ability to save keylists](https://i.imgur.com/E6Bualc.png), in pretty much the exact way CEMU lets you manage Controller Profiles
 * From this version on **64bit is required**, this shouldn't' be an issue since CEMU already has that requirement.
 * Updated included ScpVBus, as the version I had was outdated, and probably 32bit.
 
 I highly recommend deleting your `settings.ini` file when upgrading to this version. Things have moved, and one section changed names ever so slightly. The way this works shouldn't cause any actual issues, but still the file will be cleaner if you: make note your settings -> delete the file -> re-input your changes.
 

&nbsp;

[Updated Video - April 5, 2018]  [BSoD Gaming made a video](https://www.youtube.com/watch?v=bOJy67OJfZI) that shows how to set this up. It is incomplete, but for the most part it shows the initial process very well. It doesn't get into details about anything, and while it recommends using the alternate mouse movement detection **be aware that this is still experimental** and already implemented slightly different from the version used in the video. Also, changing your mouse sensitivity will only really have an effect with this experimental mode, not really on the normal mode. Along the same lines, the sensitivity he has in the settings are invalid (negative values make no sense with how it is implemented and might even cause issues), but again since he is using the alternate method they have zero effect on the program. 

***
# Initial Setup (Updated to include vXBox images)
***
1. Install the latest [vJoy](https://sourceforge.net/projects/vjoystick/files/latest/download) 
2. Run the [vJoy Configuration](http://i.imgur.com/vvHW0yz.png) (Not necessary if you only plan on using vXBox)
	* Set it up so it has **at least 18 Buttons**, I set mine to 32.
3. 	[Download controller profiles](https://bitbucket.org/CemuUser8/files/downloads/controllerProfiles.zip)  for CEMU > 1.9.0   &nbsp;&nbsp;&nbsp;&nbsp; *(Also included in GitHub release zip)*
	* Extract these text files into your [CEMU controllerProfiles folder](https://i.imgur.com/Mf5L6km.png)
4. Then open CEMU and goto the [input settings](http://i.imgur.com/N5Nibtq.png)
	* Choose the type of controller you want to use, [either 'Wii U Pro Controller' or 'Wii U GamePad'](http://i.imgur.com/sfKWlgu.png)
	* If using standard vJoy Device
		* Choose [DirectInput for the Controller API](http://i.imgur.com/KKCLqs8.png)
		* Make sure to [choose the device as `vJoy Device` and confirm it says connected](http://i.imgur.com/Zx9pTmK.png)
	* If using vXBox Device 
		* **Run the script FIRST and [choose 'Use vXBox Device'](https://i.imgur.com/s2TnMep.png) on the General Page of settings**
			* If this is the first time you will be prompted to Install ScpVBus, choose yes, then yes again on the security prompt to run `DevCon`
			* Script will reload and if the message box doesn't show up again you should be ready to use vXBox.
		* Choose [XInput for the Controller API](https://i.imgur.com/2sPQM3e.png)
		* Make sure to [choose a controller and confirm it says connected](https://i.imgur.com/syOuO0f.png) (May need to press refresh for Controller to show up)
			* If it doesn't say connected try [switching the vXBox device number in the script settings](https://i.imgur.com/3MC3B9L.png) one of them WILL say connected in CEMU (this seems to be a CEMU quirk as other applications don't care which vXBox device is selected it will always grab the active one)
	* *Not sure if necessary but [Press Calibrate](http://i.imgur.com/3E6UrZX.png)*
	* Choose the [appropriate Profile](https://i.imgur.com/zMdtNwy.png) for the type of controller you are setting up.
	* [Click Load](http://i.imgur.com/PQFlfr1.png)
	
&nbsp; 

* For vJoy devices -- The input setup should look [like this](http://i.imgur.com/SvBR4BN.png)

* For vXBox devices -- The input setup should look [like this](https://i.imgur.com/ZAVpvMa.png)
	* *Note: feel free to manually remap the blow mic and showscreen buttons here, as the vXBox controller doesn't have enough buttons for them to be included.*

### If it doesn't look like this, you are going to have a problem

***
# Using the Script and changing the key mapping
***
1. Visit the [GitHub release page](https://github.com/CemuUser8/mouse2joystick_custom_CEMU/releases) and download the latest release (0.4.1.4 currently)
2. Launch the script:
	* Double click the `.ahk` file if you have AutoHotKey installed.
	* Run the exe if you don't. 
3. IF you don't want to customize anything you are ready to use the Script.
	* Press `F1` to toggle the controller ( CEMU and Script must be running )

**Mapping your keys**

* Open the script settings by right clicking on the [controller icon in your system tray](http://i.imgur.com/fPBWOsU.png) (Bottom Right) and choose 'settings'
* Goto the [Mouse2Joystick->Keys](http://i.imgur.com/eMMnEGj.png) page:
	* You can set the [KeyList](http://i.imgur.com/JSJ1KsH.png) here 
		* This is a comma separated list of [AHK valid keys](https://autohotkey.com/docs/KeyList.htm) in order of vJoy Buttons
			* The first key is mapped to `Button 0` and so on.
		* Manually setting the list has an advantage in that you can add more than one key to the same button (New as of 0.2.0.3)
			* This is accomplished by adding the keys together using the `|` symbol.
				* i.e. you'll notice `Xbutton1|e,` is what I have set for `A` -- allowing `Mouse4` and `e` to both work.
		* I recommend setting up the keys with the Helper as below, then adding in any desired secondary keys manually.
	* [KeyList Helper](http://i.imgur.com/VF2vwfE.png)
		* This is an [interface that closely matches CEMU input layout](http://i.imgur.com/ewQL8ff.png), which will make it easy to create your KeyList.
		* You just need to click each box and then press the key you would like to use
			* Can be mouse buttons
		* AutoCycle will go through each key one by one allowing you to quickly set the keys
		* When you click save you will see the KeyList string update itself with any changes you've made.
			* If you'd like to add secondary keys now is a great time to do it.

Note: you can still keep KeyList strings for different games saved to a text file locally, and just paste it in (like it used to have to be done)

***

**Other Settings Overview**

* Open the script settings by right clicking on the [controller icon in your system tray](http://i.imgur.com/fPBWOsU.png) (Bottom Right) and choose 'settings'
	* On the [General](http://i.imgur.com/hmMxz21.png) page:
		* Input Destination
			* If you changed the name of your cemu executable enter it here
		* Activate Executable
			* Choose to have the script automatically activate cemu when controller is toggled on
		* vJoy Device
			* Choose which vJoy device to control, if you have more than one set up.
	* On the [General->Setup](http://i.imgur.com/ROm9GO4.png) page:
		* Sensitivity
			* Controls how far the mouse needs to move to tilt the stick
			* Lower values are more sensitive, I recommend 30-100
		* Non-Linear Sensitivity
			* Lower values cause the sensitivity to be raised near the center
		* Deadzone
			* Can be set very close to 0, I recommend setting to the smallest possible value where your camera doesn't wander.
		* Mouse Check Frequency
			* This is how often the mouse position is checked and reset back to the center.
	* On the [General->Hotkeys](http://i.imgur.com/fkbmOvP.png) page:
		* Quit Application
			* A Master Hotkey to quit out of the script immediately
		* Toggle the controller on/off
			* Set the key to choose the Toggle for the controller (Default F1)
	* On the [Mouse2Joystick->Axes](http://i.imgur.com/EEiTuJM.png) page:
		* Invert Axis, is self explanatory
			* Apparently I initally mapped my y-axis as inverted, so 'Yes' here means 'No' (Sorry)
	*  On the [Mouse2Joystick->Keys](http://i.imgur.com/eMMnEGj.png) page:
		*  This is the Most important page as it is where you change your assigned keys
			*  **Covered in more detail above**
	*  On the [KeyboardMovement->Keys](http://i.imgur.com/okKlFwE.png) page:
		*  Keyboard Movement
			*  Set your movement keys here.
		*  Extra Keyboard Keys
			*  Set your Toggle Walk, ZL Lock, Gyro keys here
	* On the [Extra Settings](http://i.imgur.com/FvFEeVQ.png) page:
		* Enable BotW MouseWheel Weapon Change Feature
			* Choose yes if you would like to be able to use the mouse wheel to change weapons in BotW
				* Should be off for all other games obviously
		* Enable ZL Lock Key Feature
			* Also for BotW, will allow you use a separate key to toggle ZL On, until pressed again.
				* Pressing the regularily assigned ZL key will always toggle from current state
		* Cursor
			* Choose if you would like cursor hidden
				* Sometimes useful for troubleshooting to make it visible again.


***
# Script Downloads
***
**[GitHub Releases](https://github.com/CemuUser8/mouse2joystick_custom_CEMU/releases) will be the best place to find the latest version of the script** 


**[Alternate Direct Download](https://bitbucket.org/CemuUser8/files/downloads/mouse2joystick_Custom_CEMU.zip)**

***
# Extra Reminders
***

* **Changing your keys within CEMU isn't recommended as it is tedious and finicky. The script allows you to easily change which key is assigned to which vJoy button. Then the button assignment in CEMU doesn't matter at all as long as each key has something.**



* **Note that the in-game camera settings affect the camera speed the most, so try changing there if camera speed is your only issue.**

* **If you run CEMU as an admin, then you need to run the script as an admin as well.**

***
***Please feel free to comment here for help, or send me a PM.***

&nbsp;

&nbsp;

## Instructions for rpcs3 (or any non CEMU XInput use):

* Install the [latest version of vJoy](https://sourceforge.net/projects/vjoystick/files/latest/download)
* Run the downloaded program (or AutoHotkey script if you download the source)
* Open the program settings by on the [controller icon in your system tray](http://i.imgur.com/fPBWOsU.png) (Bottom Right) and choose 'settings'
* [Choose to use vXBox.](https://i.imgur.com/s2TnMep.png) AND [Choose "No" under the "Activate Executable" Section](https://i.imgur.com/vlB7qXm.png) - Press "Ok" to reload the script with the option enabled.
* If the first time, a prompt will come up asking to install ScpVBus, Press Yes, then on the security prompt to run DevCon Press Yes again.
* The script will reload and connect a virtual XBox controller, drivers may be installed automatically on Windows10, or you will need them pre-installed on Windows7.
* To remap your keys Open the settings and goto the[ "Mouse2Joystick -> Keys"](http://i.imgur.com/eMMnEGj.png) section.
* Press the [KeyList Helper Button](http://i.imgur.com/VF2vwfE.png)
* You can map your [keys on this screen](https://i.imgur.com/IhTR03m.png), read the ReadMe for how to add a second key to the same button
* Set your movement keys on the ["KeyboardMovement -> Keys"](http://i.imgur.com/okKlFwE.png) settings screen. (Clear the Toggle ZL Lock and Toggle Gyro keys by clicking them and pressing `Backspace` - they aren't needed in rpcs3)
* In rpcs3, set your controller to use XInput
* When you want to use the controller Press "F1" (default but customizable) to toggle using the virtual Controller.

That should be it, your mouse should now control the Right Analog stick, and your movement keys the Left.

I will be honest I have not done this myself, I have just helped someone else do it and they said it works perfectly just needed a quick guide on how to set it up for this.
***
