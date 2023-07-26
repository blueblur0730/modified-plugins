# l4d2_setscores_scav

### Introduction
 - 清道夫版本的l4d2_setscores.
 - 玩家可以投票设置: 当前轮数, 两队小轮分数, 两队总得分, 比赛油桶目标数. (to do: 局数限制)

### Requirments
 - BuiltinVotes拓展 | CompetitiveRework版本
 - ReadyUp. (利用到其中的forward)
 - 编译库 scavenge_func

### Source
 - https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_setscores.sp (l4d2_setscores)
 - https://github.com/blueblur0730/modified-plugins/blob/main/include/scavenge_func.inc (scavenge_func)

<hr>

### Client Cmd
```

// 设置局数
sm_setrounds <round num>

// 设置一队的小局分数
sm_setroundscores <team> <round num> <score>

// 设置一队的比赛分数
sm_setmatchscores <team> <score>

// 设置油桶目标数
sm_setgaol <num>

其中<team> = 2 (生还) 3 (特感), <round num> = [1,5]
```

### Server ConVar
```
// 游戏中能够发起投票的最少人数
// 默认值: 2
l4d2_setscore_scav_player_limit "2"

// 玩家能否发起投票? 0关1开
// 默认值: 1
l4d2_setscore_scav_allow_player_vote "1"

// 管理员试图修改分数时, 是否需要发起投票? 0关1开
// 默认值: 0
l4d2_setscore_scav_force_admin_vote "0"

```
<hr>