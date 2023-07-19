# l4d2_tank_control_scav

### Introduntion
- 在清道夫模式下达到一定的油桶数量时生成tank.
- l4d_tank_control_eq的清道夫版本, 同时继承了l4d2_scavenge_tank的思路. 
[l4d2_scavenge_tank]作者: Mrs. Campanula, Die Teetasse
[l4d_tank_control_eq]作者: arti(以及其他未署名的贡献者)
- 在设定的油桶分数区间内进行随机选取来生成tank (区间最大值为本地图的油桶目标数 - 1)
- 生成tank时关闭灌油功能(to do)
- 鉴于tank由导演系统生成, 完善两种思路来控制tank在44 33 22 11中的血量(to do)

### Source
- http://forums.alliedmods.net/showthread.php?p=1058610 [l4d2_scavenge_tank]
- https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d_tank_control_eq.sp [l4d_tank_control_eq]

<hr>
```
### Server ConVars

// 开启插件
// 默认值:1
// min: 0; max: 1
l4d2_tank_control_scav_enabled "1"

// 选取随机油桶区间的最小值
// 默认值: 5
// min: 0; max: 不限
l4d2_tank_control_scav_random_count_min "5"

// 谁会看到谁成为tank?
// 默认值: 0
// min: 0(感染者); max: 1(所有人)
tankcontrol_print_all "0"

// 插件版本
l4d2_tank_control_scav_version PLUGIN_VERSION (见源码)

### Client Cmd

// 谁会成为tank? 油桶点数为多少?
sm_tank
```

<hr>