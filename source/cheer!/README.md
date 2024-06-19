# [L4D2] Cheer!

### Introduction
 - Original author: dalto. Syntax is updated and the logic is more compatiable in L4D2.
 - Removed config file and using cvars to load the target sounds
 - More new functions added.
 - More new convars added and some was removed
 - Tranlslations added.

### Source
 - https://forums.alliedmods.net/showthread.php?t=59952&highlight=cheer%21

### Requirements
 - Left4DHooks
 - colors.inc to compile from [here](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/include/colors.inc)
 - Custom sound files (optional)

### Related Plugins or Links
- [FastDL](https://developer.valvesoftware.com/w/index.php?title=FastDL:zh-cn&uselang=zh)
- [sm_downloader by Harry Porter](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/sm_downloader)
- [L4D2 Black Screen Fix aka Delayed downloader by BHaType](https://forums.alliedmods.net/showthread.php?t=318739)
- [EasyDownloader (V1.03, 09/12/2017) by Byte](https://forums.alliedmods.net/showthread.php?t=292207)
<hr>

### ConVars
```
// Plugin Version
l4d2_cheer_version

// The way to play sounds.  
// 1 = global chances is limited by cvars below,  
// 2 = global chance will regain with the time passing, which means global chance is only affected by these 2 cvars below.  
cheer_way_to_play 2

// The time to regain a chance to use command    
cheer_regain_time 20.0

// Max chance to use command. The chance will regain    
cheer_max_chance 3

// Enables the cheer  
// 0 = disable all, 
// 1 = enable cheer, 
// 2 = enable jeer, 
// 3 = enable both cheer and jeer.
cheer_enable 3

// Sound file directory under the directory 'sound/...'
cheer_sound_dir nepu/cheer

// The maximum number of cheers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on  
cheer_limit 10

// Cheer volume: should be a number between 0.0. and 1.0  
cheer_volume 1.0

// Sound file directory under the directory 'sound/...' 
jeer_sound_dir nepu/jeer

// The maximum number of jeers per round. This cvar is ignored if 'cheer_way_to_play' is set to 2 or 'cheer_competitive_mode_enable' is on  
jeer_limit 10

// Jeer volume: should be a number between 0.0. and 1.0  
jeer_volume 1.0

// The way we print chat messages.
// The way we print chat messages. 
// 0 = Dont print message at all, 
// 1 = Print to teammates, 
// 2 = To all players
cheer_chat 2

// Play sounds only to who?
// 1 = to the player that used the command, 
// 2 = to the team that the player that used the command is on, 
// 3 = to all players.
cheer_play_to_who 2

// Enable command interval? This cvar is ignored if 'cheer_competitive_mode_enable' is enabled  
cheer_cmd_interval_enable 1

// Interval to cheer or jeer next time  
cheer_cmd_interval 3.0

// Enables the command in competitive mode when the round begins? This cvar is ignored if 'cheer_way_to_play' is set to 2  
cheer_competitive_mode_enable 0
```
<hr>

### Client Cmd
```
sm_cheer

sm_jeer
```
<hr>

### Notice
 - Both server and client must have the same file there would be a sound played.
 - Custom sound file is not a necessity. You can use the original game sound files.
 - FastDL is recommended.
 - If your server is played by only several friends just let them put the custom sound file on their client folder it would make things much easier.
 - .mp3 and .wav format is restricted. [See more information here about file quality](https://forums.alliedmods.net/archive/index.php/t-331070.html#:~:text=This%20is%20usually%20an%20error%20in%20the%20audio,to%20change%20the%20audio%20name%20and%20update%20FastDL.).
 - If client says `Failed to load sound ".../... .mp3", file probably missing from disk/repository` and the file is indeed on the position it should be there and you have ensured everything is done right, try change the file directory cvar and both server-side and client-side file's directory. See more informations below.  
[*1](https://forums.alliedmods.net/showthread.php?t=237472)  
[*2](https://forums.alliedmods.net/showthread.php?t=272147)

### ChangeLog
```
l4d2_cheer.sp

Description:
	The Cheer! plugin allows players to cheer random cheers per round.

Versions:
	1.0
		* Initial Release

	1.1
		* Added cvar to control colors
		* Added cvar to control chat
		* Added team color to name

	1.2
		* Added jeers
		* Added admin only support for jeers
		* Made config file autoload

	1.3
		* Added *DEAD* in front of dead people's jeers
		* Added volume control cvar sm_cheer_jeer_volume
		* Added jeer limit cvar sm_cheer_jeer_limit
		* Added count information to limit displays
2007
------------------------------------------------------------
2023
	r1.0: 8/1/23
		* updated to sm1.11 new syntax.
		* reformatted to support L4D2.

	r1.1: 8/2/23
		* check the gamemode in L4D2. we dont use this plugin if the round has already started in versus or scavenge.
		* split cheer and jeer into two commands separately rather than checking whether a player is dead or not.

	r1.1.1: 8/2/23
		* if round is lived, tell them we cannot use commands.

	r1.2: 8/2/23
		* fix an issue message didn't print to chat.
		* add team prefixes.

	r1.2.1: 8/2/23
		* now cheer or jeer counts restore to 0 if round ends.

	r1.3: 8/6/23
		* Optimized code format.
		* Added in round check. We allow players to use cheer or jeer in scavenge or versus mode while round is live, switch and limits is controlled by new added cvar.

	r1.3.1: 8/6/23
		* Added a cvar to control whether a client should download sound files. (there's more other efficient ways to download files, we don't recommend to do this on this plugin.)

	r1.3.2: 8/7/23
		* Added a cvar to control the interval we can cheer or jeer next time, preventing chat spamming.
		* more mutation gamemode detections.

	r1.3.3: 9/13/23
		* Added a cvar to control the sound file number we can load. Now we can load each cheer or jeer files up to 128 at a time. (still confusing if there is anyway to turn this 128 into a valid variable.)

	to do:
		* unlock the limit of sound files we can load.
------------------------------------------------------------
2024
	r2.0.0: 6/7/24
		* Finished to do. Credits to MapChanger by Alex Dragokas.
			- Removed config file. Now plugin will precache file automatically by the preset path in the sound/.. directory.
				- Added new convar "cheer_sound_dir" and "jeer_sound_dir" to specify the sound path to precache.
				- Removed convar "sm_cheer_sound_number" and "sm_cheer_colors". 谁不在colors啊我也在colors啊colors就得应该是colors而不是不colors
		* Renamed convars.
		* Reformatted codes.
		* Code optimizations and simplifizations.
		* Translations reformatted. Removed two non-color phrases.
		* Added Left4DHooks to identify gamemode. (More directly isn't ?)
		* Removed sourcemod cfg cvar file. I dont like it.
	  + to do:
		* New choice. Added more convar to control the way we use.
		* Add a way to use. Player only have 3 chances to use commands, but the chance will regain with the time passing. Like what ExG ze dose.
		* Let user himself choose whether to unlimit the chance or other things in competitive gamemodes.
	
	r2.1.0: 6/9/24
		* Added cvar change hook.
		* Removed cvar "cheer_in_round_limit", "jeer_in_round_limit".
		* Added cvar "cheer_way_to_play", "cheer_regain_time", "cheer_max_chance" (to do *3/1).
		* Renamed cvar "cheer_in_round_enable" to "cheer_competitive_mode_enable".
		* No longer limit while round began when in competitive mod.

	r2.1.1: 6/10/24
		* Removed team name prefix tag translations and unused translations.
		* Finished to do *2.
		* Added new translation phrase "Rechargeing".
		* If "cheer_competitive_mode_enable" is on, ignore cvar "cheer_cmd_interval_enable" "cheer_limit" "jeer_limit"
		* Logic optimized.

	r2.1.2: 6/12/24
		* Fixed an issue that cvars didn't initialize on plugin start up.
		* Use ArrayList instead of StringMap.
		* Fixed that regain time didn't work.
		* Translation phrase "Rechargeing" should be "Recharging". 玩apex玩的
		* Fixed when client first entered the server the index wasn't initialized correctly.
		* Fixed the sound path prefix tag to write in.
		* Fixed an issue that chance calculations doesn't work correctly.
		* Fixed that the directory didn't format correctly to pass to the functions.

	r2.1.3: 6/12/24
		* Fixed an issue caused by improperly using DataPack.

	r2.1.4: 6/13/24
		* Allow players to have command interval limit when "cheer_way_to_play" is set to 2.

	r2.1.5: 6/13/24
		* Added new convar "cheer_play_to_team" to choose whether play sounds and send chat message to your teammates or to all players. default off.
		* On last version we forgot to replace version tag lmao.
		* Credits to Microsoft to let me know I'm writing Shit English and shamefully to correct every wrong words I've written in the documents.

	r2.1.6: 6/13/24
		* Minor change with message variable.
			* Translation phrases "Cheered!!!" and "Jeered!!!" now use client index to specify client's name.

	r2.2.0: 6/19/24
		* Renamed plugin to "l4d2_cheer" finally.
		* Convar changes:
			* Merged cvar "cheer_enable" and "jeer_enable" into "cheer_enable" alone with 4 values to choose. You can disable both, enable both, or enable one of them.
			* Extented cvar "cheer_chat" to have 3 values to choose. You can print message to teammates or all players, or not.
			* Replaced cvar "cheer_play_to_team" with "cheer_play_to_who" to have 3 values to choose. You can play sounds on yourself, teammates or all players.
			* Removed cvar "cheer_download_enable".
		* Added new translation phrase "disabled"
		* If sound directory is not found, the plugin will log the message to the error log instead of printing server message.
		* If no files was found in the relative directory, plugin won't prechache and play the sounds of the command but the chat message will still be sent. The error message will be logged to the error log.
		* Replaced event "player_left_start_area" with forward L4D_OnFirstSurvivorLeftSafeArea_Post.
		* Code cleanings. Variables renamed
```
