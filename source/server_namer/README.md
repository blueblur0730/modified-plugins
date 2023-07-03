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

### Requirements
 - Readyup插件.(如果你的服务器没有Confogl配置, 可以不加, 或者依照自己喜好配置).

<hr>

### Server ConVars
```
// 设置服务器主名称(注意: 只有当txt文件不能读取时这个cvar才会起作用), 对应下文参数{hostname}
// 默认值: Hostname
sn_main_name "Hostname"

// 设置服务器序号, 对应下文参数{servernum}
// 默认值: 0
sn_host_num "0"

// 设置txt文件路径, 插件主要从这个txt文件读取主服名, 文件应位于sourcemod/内, 对应下文参数{hostname}
// 默认值: 无 (建议设置为hostname/hostname.txt)
sn_main_name_path ""

// 设置当Confogl配置可用时或难度固定时的Vanilla模式的(官版对抗, 生还者等)服务器名称
// 默认值: [{hostname} #{servernum}] {gamemode}. {gamemode}参数在这里指代l4d_ready_cfg_name的值
// 例如: [Servername #1] ZoneMode 2.x 或 Servername #1 | ZoneMod 2.x 
sn_hostname_format1 "[{hostname} #{servernum}] {gamemode}"

// 设置Vanilla模式(官版战役, 写实)下的服务器名称
// 默认值: [{hostname} #{servernum}] {gamemode} - {difficulty}. {difficulty}参数指代难度, {gamemode}参数在这里指代游戏模式(详见server_namer.txt)
// 例如: Servername #1 | Realism - Expert
sn_hostname_format2 "[{hostname} #{servernum}] {gamemode} - {difficulty}"

// 设置服务器无人时的服务器名称
// 默认值: [{hostname} #{servernum}]
// 例如: Servername #1
sn_hostname_format3 "[{hostname} #{servernum}]"

// 设置当服务器加载AnneHappy配置时的服务器名称
// 默认值: [{hostname} #{servernum}] {hardcoop}{AnneHappy}{Full}. {hardcoop}参数指代l4d_ready_cfg_name的值, {AnneHappy}参数指代几特几秒, {Full}参数指代两边是否满人.
// 例如: Servername #1 | [普通药役][6特16秒][缺人]
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
 - 如果你的服务器是一个CompetitiveRework(药抗)服务器, 建议将插件写入sharedplugins.cfg加载.
 - 请在自己设定的路径里编辑服务器名称

<hr>




