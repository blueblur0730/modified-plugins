**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Shove Kill Adjustment

## Introduction

Provides ability to modify the mechanics of "shoving special infecteds to death".  

1. Allows you to set the maximum count to get the SI to be shoved to death.

2. Allows you completely disable the shove kill mechanics. (Required Source Scramble Extention, Optional.)

3. Allows you to adjust the time that the game needs to decrement the shove count for once. (Required Source Scramble Extention and MidHook Extention, Optional.)

## Requirements

* SourceMod 1.12+.
* [MidHook Extention](https://github.com/Scags/SM-MidHooks) by Scags. (Optional)
* [Source Scramble Extention 0.7.2+](https://github.com/nosoop/SMExt-SourceScramble) by nosoop. (Optional)
* [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc) to compile.

## ConVars

See [file](./scripting/l4d2_shove_kill_adjustment.sp#L431C0-L431C20).

## Additional Comments

See [file](./scripting/l4d2_shove_kill_adjustment.sp#L41C0-L44C114).