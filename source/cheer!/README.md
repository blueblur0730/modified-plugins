# Cheer!

### Introduction
 - 原作者dalto. 我翻新了语法并修改逻辑使得插件更适合在L4D2使用.
 - 玩家可以使用命令来进行Cheer或者Jeer进行随机音效播放和文本输出.
   * 若游戏模式为对抗模式或清道夫模式, 只能在每局开局前或者对局结束后进行Cheer或Jeer.

### Source
 - https://forums.alliedmods.net/showthread.php?t=59952&highlight=cheer%21

### Requirements
 - Left4Dhooks
 - 自定义声音文件

<hr>

### Server ConVars
以下cvar可在cfg/sourcemod/cheer.cfg中编辑.
```
// 开启插件
// 默认值: 1 
// 0关1开
sm_cheer_enable "1"

// 每轮Cheer次数限制
// 默认值: 3
// min:0
sm_cheer_limit "3"

// 1开启文本彩色输出, 0无色输出
// 默认值: 1
sm_cheer_colors "1"

// 开启文本输出提示
// 默认值: 1
// 0关1开
sm_cheer_chat "1"

// 开启jeer
// 默认值:1
// 0关1开, 2仅限管理员
sm_cheer_jeer "1"

// 每轮jeer次数限制
// 默认值: 1
// min:0
sm_cheer_jeer_limit "1"

// 播放Jeer音效时的音量
// 默认值: 1.0
// 数值应在0.0至1.0之间
sm_cheer_jeer_volume "1.0"

// 播放Cheer音效时的音量
// 默认值: 1.0
// 数值应在0.0至1.0之间
sm_cheer_volume "1.0"

### Client Cmd

// 播放Cheer音效
sm_cheer

// 播放Jeer音效
sm_jeer
```

### Config File
```
在cheersoundlist.cfg中, 你需要做如下编辑.
例如:

"cheer sounds"
{
	"cheer sound 1"		"cheers/xxx.wav"
}

"cheer sounds"代表以下方括号的音效仅给sm_cheer播放.
"cheer sound x"为固定句式, 请不要修改.
"cheers/xxx.wav"为你的自定义文件路径. 文件或文件夹应位于`left4dead2/sound`中
```

<hr>

### Notice
 - 为了使玩家有更好的进服体验, 请先提前在server.cfg中设置好 sv_allowdownload 1 和 sv_downloadurl "<你的服务器http链接资源点>".
 - Cheer和Jeer每个最多只支持12个音频文件, 如果需要扩增请依据源码修改.
 - 音频文件应该 (建议) 为.wav格式或.mp3格式, 且码率要求为44100Hz (否则游戏内没声音).
