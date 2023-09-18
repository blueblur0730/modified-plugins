# l4d2_fix_scav_issues

### Introduction
- 解决清道夫第一轮不生成油桶的问题.
- 允许设置局数限制.
- 提供管理员指令手动一次性生成所有油桶.
- 提供对局结束后是否重置对局的功能.

### Source: 
- https://github.com/nagadomi/l4d2_scavenge_1st_round_skip/issues/1 (L4D2_SpawnAllScavengeItems()所使用的签名的发现者)
- https://github.com/lechuga16/scavogl_rework/blob/master/addons/sourcemod/scripting/readyup_scav.sp (重置局数函数来源)

### AlliedModders
- https://forums.alliedmods.net/showthread.php?t=343602

### Requirment
- Left4Dhooks 1.134+

<hr>

### Admin Cmd
```
// 手动生成所有油桶 (注意, 可以叠加多次生成), 需要cvar为开.
sm_enrichgascan

```
<hr>

<hr>

### Server ConVar
```
// 允许管理员使用生成油桶命令?
// 默认值: 0
// min: 0; max: 1
l4d2_scavenge_allow_enrich_gascan "0"

// 设置清道夫开局局数. 合法参数分别为1, 3, 5
// 默认值: 5
// min: 0; max: 5
l4d2_scavenge_rounds "5"

// 对局结束后是否重置比赛?
// 默认值: 1
// 0关1开
l4d2_scavenge_match_end_restart "1"
```
<hr>
