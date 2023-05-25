### Introduction
 - 这个插件的原作者是devilesk, 我在此插件的基础上进行了修改, 包括:
   - 去除了原插件自带的投票重启地图功能, 保留管理员指令供玩家使用.
   - 提供翻译功能.
   - 检测是否是对抗以外的模式, 如果是, 则不使用分数设置功能.
   - 提示玩家并在5s延迟后重启地图.
 - 提供指令让管理员或者投票重启地图.
 - 如果游戏模式是对抗, 则重启地图后将保留当前一m双方的得分.
 - 自动检测地图进度问题并重启.
 - 检测是否加载l4d2_changelevel, 否则使用sm_map指令重置地图.

### Source
https://github.com/devilesk/rl4d2l-plugins

### Requirements
 - Left4Dhooks
 - Builtinvotes (用以发起投票, 源文件我已注释, 请根据自己需求取消注释)
 - l4d2_changelevel (可选)
 - 特殊编译库 (影响源码编译, 原作者仓库可自取)
   - team_consistency.inc
   - l4d2_changelevel.inc
   - rl4d2l_util.inc

<hr>

### Server ConVars
```
// 开启插件debug模式
// 默认值 : 0
// min: 0, max: 1
sm_restartmap_debug

// 开启地图进度破损修复重置
// 默认值 : 0
// min: 0, max: 1
sm_restartmap_autofix

// 自动进度破损重置最大尝试次数
// 默认值: 1
// min: 0, max: 不限
sm_restartmap_autofix_max_tries
```

### Admin Cmd
```
// 重置地图
sm_restartmap

<hr>
