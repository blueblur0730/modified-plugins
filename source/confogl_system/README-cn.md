**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2/Any?] Confogl System

这是一篇简单的 Confogl system 使用说明和介绍.  

## 需求

1. [log4sp 拓展](https://github.com/F1F88/sm-ext-log4sp).
2. (可选) l4d2_changelevel 插件.

## 安装

1. 将相对应的东西放入sourcemod文件夹.  

2. 在目录 `../cfg/cfgogl/<你的配置>` 下创建你自己的配置, [可参考例子](./source/confogl_system/cfg_template/).

3. 编辑 `matchmode.txt` 以匹配你的配置文件夹名称.

## 功能说明

### 选择配置 (MatchVote.sp/ReqMatch.sp)

Confogl System 通过指令 `sm_match` 来读取 `addons/sourcemod/configs/` 目录下的 `matchmode.txt` 来发起投票以选择配置. 文件是以 KeyValues 结构存储一系列配置. 正常情况下, 结构如下所示:  

```

"MatchModes"
{
    "ExampleConfig" // 一类配置的基本名称
    {
        // 配置所在的文件夹名称: ../cfg/cfgogl/<文件夹名称>
        "example_type"  
        {
            // 配置在投票菜单的展示名称: "Example Name"
            "name"  "Example Name"
        }

        ""
        {
            "name"  ""
        }
        ...
    }

    ""
    {
        ...
    }
    ...
}
```  

只有如上的结构才能成功在投票菜单上展示.  
管理员可以使用指令 `sm_forcematch <配置文件夹名称> <[可选] 地图名称>` 来强制加载某个配置.  
Confogl System 使用内置的 nativevote 来管理投票, 不依赖builtinvote拓展和nativevote插件.

### 加载配置 (ReqMatch.sp)
<hr>

这一部分简要介绍加载配置的过程.  

通过指令 `sm_match` 或 `sm_forcematch` 加载某个配置后, 插件会首先检查目录 `../cfg/cfgogl/<配置文件夹名称>/...`.  

一个配置文件夹内通常由3个cfg文件组成: `confogl.cfg`, `confogl_off.cfg`, `confogl_plugins.cfg`.  

首先, Confogl 会执行指令 `sm plugins load_unlock` 和 `sm plugins unload_all` 来卸载所有插件, 然后执行由 convar `confogl_match_execcfg_plugins` 提前设定的cfg文件.  

该 convar 的值表示应该用来加载插件的cfg文件. 默认上, Confogl 会搜索该路径下 `../cfg/cfgogl/<config_name>/confogl_pluigns.cfg` 的文件, 如果失败, Confogl 会搜索默认路径 `../cfg/confogl_pluigns.cfg`.  

确保 API 插件最先加载, 注意各个插件之间的依赖顺序, 并且总是让 `confogl_system.smx` 作为最后一个加载的插件, 否则配置将加载失败.  

注意: 你不必要在文件里写入 `sm plugins load_lock`, Confogl 之后会自动处理.  

随后，Confogl 会通过 convar `confogl_match_execcfg_on` 搜索该路径下的文件 `../cfg/cfgogl/<config_name>/confogl.cfg`, 如果失败, Confogl 会搜索默认路径 `../cfg/confogl.cfg`. 这个cfg文件存放着一系列你需要监视和限制的convar列表.  

最后, Confogl 会重启当前地图或加载制定地图, 并使用 `sm plugins load_lock` 来锁住插件加载.

### 卸载配置 (ReqMatch.sp/MatchVote.sp/predictable_unloader.sp)
<hr>

使用指令 `sm_rmatch` 来发起投票以卸载当前加载的配置. 管理员可以使用指令`sm_resetmatch` 来强制卸载.  
卸载时, Confogl 会搜索该路径下的文件 `../cfg/cfgogl/<config_name>/confogl_off.cfg`, 如果失败, Confogl 会搜索默认路径 `../cfg/confogl_off.cfg`.

该cfg文件提供给用户通过指令自行处理重置各项影响游戏或插件的改变. 然后 Confogl 会一个一个卸载除自身之外的所有插件, 最终卸载自身, 再执行 `sm plugins refresh` 来重新加载默认插件.  

这里就是为什么我建议你把 `confogl_system.smx` 放在除 `optional` 或 `disabled` 目录下的地方.

### ConVar 监视与限制 (CvarSetting.sp/ClientSettings.sp)
<hr>

你可以使用服务端指令 `confogl_addcvar <cvar> <值>` 将一个 convar 加入进监视列表.  
你可以使用服务端指令 `confogl_trackclientcvar <客户端cvar> <hasMin> <min> [<hasMax> <max> [<action>]]` 来追踪和限制某些客户端 convar.  

在所有列表完成加载后, 使用服务端指令 `confogl_setcvars` 来设置所有 convar 的设定值并启用监视, 使用服务端指令 `confogl_startclientchecking` 开始循环检查客户端 convar. 这些指令通常写在 `confogl.cfg`.  

要重置, 使用服务端指令 `confogl_resetcvars` 和 `confogl_resetclientcvars` 来清空列表并停止监视检查. 这些指令通常写在 `confogl_off.cfg`.

### 其他 (BotKick.sp/PasswordSystem.sp/UnreserveLobby.sp)
<hr>

1. Unreserve Lobby: 提供服务端指令 `sm_killlobbyers` 来手动移除大厅匹配. 提供 convar `confogl_match_killlobbyres` 来决定是否在加载配置后移除大厅匹配.

2. Bot Kick: 在L4D2中踢出链接进来的生还者或感染者bot.

3. Password System: 通过提供 convar `confogl_password` 为在服务器内的玩家设置 convar `sv_password` 并在新玩家连接时检查该convar的值.

## 什么是 Confogl?

Confogl 是一个基于可供选择的配置文件框架，用于管理插件加载, 在游戏中监视并限制 convar 值变动的sourcemod插件. 该项目最初目的适用于构造一个公平化竞技化的L4D2对抗模式.  

它最初是由 [ProdigySim](https://github.com/ProdigySim) 领导的项目 [Confogl Team](https://github.com/ConfoglTeam) 所创建.

Confogl 由两部分组成: 被称为 [LGOFNOC (League and Gaming Organization Framework for Normalized) (联赛组织标准系统框架)](https://github.com/ConfoglTeam/LGOFNOC) 的插件加载管理和convar监视限制框架和其他与L4D2相关的功能性插件.  

该项目的历史已由超过14年的历史, 见证了许许多多来自L4D2社区贡献者们的无偿奉献. 现在它更加广为人知的样貌是由 [L4D2 Competitive Rework 社区](https://github.com/SirPlease/L4D2-Competitive-Rework) 所维护的 [confoglcompmod (Confogl's Competitive Mod)](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/confoglcompmod.sp).  

Confogl System 由 [confoglcompmod (Confogl's Competitive Mod)](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/confoglcompmod.sp) 的分支开发而来, 即只保留插件加载与convar管理的框架部分, 并加入了许多功能改进.  

为兼容 L4D2 竞技对抗, confoglcompmod 的剩余部分被分开放在了该仓库里. 请总是将 confoglcompmod.smx 放在 confogl_system.smx 前加载, 这样可以保证例如zonemod的配置加载成功.  

Confogl System 以及它的框架是一个服务器拥有多种玩法的理想选择. 以 L4D2 为例, 你可以在不同的配置定义所加载的插件和监视的convar下在战役, 对抗, 清道夫等各种模式中切换自如.

## 有何更改

1. 为插件加入了日志系统, 要求加载拓展 [log4sp](https://github.com/F1F88/sm-ext-log4sp).
2. 合并了 MatchVote 以及 Predictable Unloader 进了 Confogl.
3. 自动在卸载配置时卸载插件.
4. 使用内置的nativevote替代builtinvote拓展.
5. 全翻译文本支持.
6. 更多加入的细节与更改.
7. 更多未来将加入的功能..

## 特别感谢

1. [Confogl Team](https://github.com/ConfoglTeam), 尤其是 [ProdigySim](https://github.com/ProdigySim) 对总体框架的建设.

2. [L4D2 Competitive Rework community](https://github.com/SirPlease/L4D2-Competitive-Rework) 对项目的长期维护.

3. Forgetest, 对他在 predictable unloader [的改进代码](https://github.com/Target5150/MoYu_Server_Stupid_Plugins/tree/master/The%20Last%20Stand/predictable_unloader).

4. Powerlord 和 fdxx 的 [nativevote代码](https://github.com/fdxx/l4d2_nativevote)

5. F1F88 的拓展 [log4sp](https://github.com/F1F88/sm-ext-log4sp).

6. 许多其他为Confogl项目贡献过而我没有提到过的用户.