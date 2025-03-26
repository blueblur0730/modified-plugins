**[English](./README.md) | [中文](./README-cn.md)**

* [L4D2] Shove Kill Adjustment

## 说明

提供能修改游戏机制 "推死特感" 的功能.  

1. 允许你设置推死一个特感所需的最大推次数.

2. 允许你完全关闭推死特感的机制.

3. 允许你修改游戏将特感累计推次数消减一次所需的时间. (需要 [MidHook 拓展](https://github.com/Scags/SM-MidHooks))

## 依赖

* SourceMod 1.12+
* [Left 4 DHooks Direct 插件](https://forums.alliedmods.net/showthread.php?t=321696) by Silvers 以及其他人.
* [MidHook Extention](https://github.com/Scags/SM-MidHooks) (可选)
* [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc) 用于编译.

## ConVars

见 [文件](./scripting/l4d2_shove_kill_adjustment.sp#L542C0 -L542C20).

## 额外说明

见 [文件](./scripting/l4d2_shove_kill_adjustment.sp#L30C0 -L37C114).