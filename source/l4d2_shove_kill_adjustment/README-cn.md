**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Shove Kill Adjustment

## 说明

提供能修改游戏机制 "推死特感" 的功能.  

1. 允许你设置推死一个特感所需的最大推次数.

2. 允许你完全关闭推死特感的机制. (需要 Source Scramble 拓展)

3. 允许你修改游戏将特感被推次数消减一次所需的时间. (需要 Source Scramble 拓展, MidHook 拓展, 可选.)

## 依赖

* SourceMod 1.12+.
* [MidHook 拓展](https://github.com/Scags/SM-MidHooks) by Scags. (可选)
* [Source Scramble 拓展](https://github.com/nosoop/SMExt-SourceScramble) by nosoop. (必要)
* [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc) 用于编译.

## ConVars

见 [文件](./scripting/l4d2_shove_kill_adjustment.sp#L431C0-L431C20).

## 额外说明

见 [文件](./scripting/l4d2_shove_kill_adjustment.sp#L41C0-L44C114).