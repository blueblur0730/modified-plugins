# Cheer!

### Introduction
 - 原作者dalto. 我翻新了语法并修改逻辑使得插件更适合在L4D2使用.
 - 玩家可以使用命令来进行Cheer或者Jeer进行随机音效播放和文本输出.
 - 若游戏模式为对抗模式或清道夫模式, 可以选择是否在局内进行Cheer或Jeer.
 - 增加一系列cvar对原有或新增功能进行控制.

### Source
 - https://forums.alliedmods.net/showthread.php?t=59952&highlight=cheer%21

### Requirements
 - 自定义声频文件

<hr>

### Server ConVars
以下cvar可在cfg/sourcemod/cheer.cfg中编辑.
```
// 开启插件
// 默认值: 1 
// 0关1开
sm_cheer_enable "1"

// 开启jeer
// 默认值:1
// 0关1开, 2仅限管理员
sm_cheer_jeer "1"

// 1开启文本彩色输出, 0无色输出
// 默认值: 1
sm_cheer_colors "1"

// 开启文本输出提示
// 默认值: 1
// 0关1开
sm_cheer_chat "1"

// 每轮Cheer次数限制
// 默认值: 10
// min:0
sm_cheer_limit "10"

// 每轮jeer次数限制
// 默认值: 10
// min:0
sm_cheer_jeer_limit "10"

// 播放Jeer音效时的音量
// 默认值: 1.0
// 数值应在0.0至1.0之间
sm_cheer_jeer_volume "1.0"

// 播放Cheer音效时的音量
// 默认值: 1.0
// 数值应在0.0至1.0之间
sm_cheer_volume "1.0"

// 是否开启指令时间间隔? (有效阻止刷屏)
// 默认值: 1
// 0关1开
sm_cheer_cmd_interval_enable "1"

// 每次Cheer或Jeer的时间间隔
// 默认值:5.0
sm_cheer_cmd_interval "5.0"

// 游戏模式为对抗或清道夫时 (包括同类型突变), 是否允许对局开始后使用插件?
// 默认值: 1
// 1开0关
sm_cheer_in_round_enable "1"

// 对局开始后最多能使用的Cheer次数
// 默认值: 5
sm_cheer_in_round_cheer_limit "5"

// 对局开始后最多能使用的Jeer次数
// 默认值: 5
sm_cheer_in_round_jeer_limit "5"

// 是否启用插件自带的自动下载音频文件功能? (不建议开启, 有更高效的方式进行下载处理, 如Fasdl, 其他下载辅助插件)
// 默认值: 0
// 1开0关
sm_cheer_download_enable "0"
```

<hr>

### Client Cmd
```
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
	"cheer sound 1"		"cheers/xxx.mp3"
}

"cheer sounds"代表以下方括号的音效仅给sm_cheer播放.
"cheer sound x"为固定句式, 请不要修改.
"cheers/xxx.mp3"为你的自定义文件路径. 文件或文件夹应位于`left4dead2/sound`中
```

### Notice
 - 注意: 不需要第三方音频文件也是可以运作的, 可以将路径设置为游戏原有的音频文件.
 - 为了使玩家有更好的进服体验, 请部署自己的[FastDl](https://developer.valvesoftware.com/w/index.php?title=FastDL:zh-cn&uselang=zh)或按照其他[下载辅助插件](https://github.com/fbef0102/L4D1_2-Plugins/tree/master/sm_downloader)步骤进行操作.
 - 若不使用FasDl或其他插件进行自动下载操作, 则请先提前在server.cfg中设置好 sv_allowdownload 1, 或让客户端和服务端提前装好相同的文件.
 - Cheer和Jeer每个最多只支持12个音频文件, 如果需要扩增请依据源码修改.
 - 音频文件应该为.mp3格式 (建议) 或.wav格式, 且码率要求为44100Hz, 采样率要求为64kbps. [否则游戏内没声音](https://forums.alliedmods.net/archive/index.php/t-331070.html#:~:text=This%20is%20usually%20an%20error%20in%20the%20audio,to%20change%20the%20audio%20name%20and%20update%20FastDL.).
