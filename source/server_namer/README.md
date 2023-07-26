# Server Namer
### Introduction
 - 这个插件大部分代码的原作者是: sheo, Forgetest, 东. 这是一个由两个插件源码合并的插件. 我则进行了一些移植和稍加修改.
 - 动态服务器名称. 
    - 当服务器没有人时, 只显示基础服名.
    - 当服务器加载一个Confogl配置(药抗配置)时, 通过检测Readyup插件的cvar在服名旁显示当前配置名称.
	- 当Confogl配置为AnneHappy药役时, 显示格式依照的AnneHappy格式显示服名.
    - 当服务器有人而未加载Confogl配置(Vanilla模式, 也就是所谓的官方模式)时, 显示当前Vanilla模式名称.
 - 支持读取txt文件以支持UTF-8字符(意味着会有部分中文服名插件相似的功能, 建议只选其中一个用).
 - 只有当txt文件读取失败时才会从插件自带cvar sn_main_name 读取服务器主名称.

### Source
 - https://github.com/Target5150/MoYu_Server_Stupid_Plugins/tree/master/The%20Last%20Stand/server_namer
 - https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/addons/sourcemod/scripting/extend/server_name.sp

### Requirements
 - Readyup插件.(如果你的服务器没有Confogl配置, 可以不加, 或者依照自己喜好配置).

<hr>

### Server ConVars
```
参数作用一览:
- {hostname} : 代表sn_main_name的值和hostname.txt文本的值, 即你的服务器名称.
- {servernum} : 代表sn_host_num的值.
- {gamemode} : 当服务器加载Confogl模式时 (简单来说就是普遍的药抗模式), 代表cvar l4d_ready_cfg_name的值. (这个cvar来自readyup.smx). 当服务器没有加载Confogl模式, 运行在任意官方模式时, 显示该官方模式名称. (详见configs/server_namer.txt)
- {difficulty} : 代表战役或者任何有可调节难度的模式的难度名称. (详见configs/server_namer.txt)
- {Mixmap} : 当使用l4d2_mixmap插件时, 在服名显示 "Mixmap" 字样.

// 以下三条仅限AnneHappy药役.
- {hardcoop} : 指代cvar l4d_ready_cfg_name的值, 当且仅当值为 "AnneHappy" "AllCharger" "1vHunters" "WitchParty" "Alone"时才会显示对应字样. (对应字样为[普通药役], [牛牛冲刺], [HT训练], [女巫派对], [单人装逼])
- {AnneHappy} : 显示当前刷特数量与时间, 字样为[x特x秒]
- {Full} : 若两边阵容未满, 显示[缺人]字样, 否则不显示字样

// 设置服务器主名称(注意: 只有当txt文件不能读取时这个cvar才会起作用)
// 默认值: Hostname
sn_main_name "Hostname"

// 设置服务器序号
// 默认值: 0
sn_host_num "0"

// 设置txt文件路径, 插件主要从这个txt文件读取主服名, 文件应位于sourcemod/configs内.
// 默认值: 无 (建议设置为hostname/hostname.txt)
sn_main_name_path ""

// 设置当Confogl配置可用时或难度固定时的Vanilla模式的(官版对抗, 生还者等)服务器名称
// 默认值: [{hostname} #{servernum}] {gamemode}.
sn_hostname_format1 "[{hostname} #{servernum}] {gamemode} {Mixmap}"

// 设置Vanilla模式(官版战役, 写实)下的服务器名称
// 默认值: [{hostname} #{servernum}] {gamemode} - {difficulty}
sn_hostname_format2 "[{hostname} #{servernum}] {gamemode} - {difficulty}"

// 设置服务器无人时的服务器名称
// 默认值: [{hostname} #{servernum}]
// 例如: Servername #1
sn_hostname_format3 "[{hostname} #{servernum}]"

// 设置当服务器加载AnneHappy配置时的服务器名称
// 默认值: [{hostname} #{servernum}] {hardcoop}{AnneHappy}{Full}
sn_hostname_format4 "[{hostname} #{servernum}] {hardcoop}{AnneHappy}{Full}"

// 插件版本
// 默认值: 4.2
l4d2_server_namer_version "4.2"
```

### Admin Cmd
```
// 管理员手动刷新服务器名称
sn_hostname
```
<hr>

### Installation
 - 安装好插件后, 将以上的Server ConVars全部写入server.cfg, 建议所有cvar开头冠以sm_cvar, 并依照你的喜好修改格式.
 - 如果你的服务器是一个Confogl(药抗)服务器, 建议将插件写入sharedplugins.cfg加载.
 - 请在自己设定的路径里编辑服务器名称

<hr>




