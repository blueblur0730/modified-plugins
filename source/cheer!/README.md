# Cheer!

### Introduction
 - Original author: dalto. Syntax is updated and the logic is more compatiable in L4D2.
 - Use Command to play sounds to all players.
 - More new ConVars added and some was removed

### Source
 - https://forums.alliedmods.net/showthread.php?t=59952&highlight=cheer%21

### Requirements
 - Left4DHooks
 - Custom sound files (optional)

### Related Plugins or Links
- [FastDl](https://developer.valvesoftware.com/w/index.php?title=FastDL:zh-cn&uselang=zh)
- [sm_downloader by Harry Porter](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/sm_downloader)
- [L4D2 Black Screen Fix aka Delayed downloader by BHaType](https://forums.alliedmods.net/showthread.php?t=318739)
- [EasyDownloader (V1.03, 09/12/2017) by Byte](https://forums.alliedmods.net/showthread.php?t=292207)
<hr>

### ConVars

cheer_enable
cheer_sound_dir
cheer_limit
cheer_volume    range: 0.0 - 1.0

jeer_enable
jeer_sound_dir
jeer_limit
jeer_volume     range: 0.0 - 1.0

cheer_chat
cheer_cmd_interval_enable
cheer_cmd_interval

cheer_in_round_enable
cheer_in_round_limit
jeer_in_round_limit

cheer_download_enable

see descriptions in file.
cvars are not hooked with in game changes, prepare cfg file yourself.

<hr>

### Client Cmd
sm_cheer
 - Player cheer sound.

sm_jeer
- Player jeer sound.


### Notice
 - Both server and client must have the same file there would be a sound played.
 - Custom sound file is not a necessity. You can use the original game sound files.
 - FastDL is recommended.
 - If your server is played by only several friends just let them put the custom sound file on their client folder it would make things esaier.
 - .mp3 and .wav format is recommended. [See more information here](https://forums.alliedmods.net/archive/index.php/t-331070.html#:~:text=This%20is%20usually%20an%20error%20in%20the%20audio,to%20change%20the%20audio%20name%20and%20update%20FastDL.).
