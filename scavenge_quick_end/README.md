# Scavenge Quick End
### Introduntion
 - 插件原作者 ProdigySim, 我对插件语法进行了翻新和一些修改.
   - 新增Cvar开关清道夫提前结束.
   - 新增支持多语言输出.
 - 支持使用命令查询当前清道夫对局时间.
 - 支持比较两边的分数和时间来对对局进行提前结束.

### Source
https://github.com/lechuga16/scavogl_rework/blob/master/addons/sourcemod/scripting/scavenge_quick_end.sp

<hr>

### Server Cvars
```
// 是否开启提前结束
// 默认值: 1
// min: 0, max: 1
l4d2_enable_scavenge_quick_end 1
```

### Client Cmd
// 查询当前回合所用时间和上一轮所用时间
sm_time
```

<hr>