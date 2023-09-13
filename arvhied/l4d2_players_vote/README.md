# l4d2_players_vote
### Introduction
 - 这个插件大部分代码的原作者是: 东，Bred. 这是一个由两个插件源码合并的插件，99%代码来源自这两位作者各自的vote插件，我则进行了一些移植和稍加修改.
 - 提供完全文本中文输出和多语言输出支持.
 - 可执行cfg文件.
 - 踢人与封禁与使玩家成为旁观支持.
 - 提供Sourceban封禁功能选项

### Requirments
 - BuiltinVotes拓展 | CompetitiveRework版本
 - (可选)Sourceban, (AnneHappy)l4d_stats

### Source
 - https://github.com/fantasylidong/CompetitiveWithAnne/blob/master/addons/sourcemod/scripting/AnneHappy/vote.sp
 - https://gitee.com/honghl5/open-source-plug-in

<hr>

### Client Cmd
```
// 呼出投票菜单.
sm_vote

// 呼出踢人菜单.
sm_votekick

// 呼出封禁菜单. 封禁玩家一天
// 如果服务器配置了Sourceban和Anne的l4d_stats(积分统计), 则封禁结果将会通过Sourceban运作, 如果没有, 则通过sourcemod自带的baseban.smx运作.
sm_voteban

// 呼出投票旁观菜单, 投票使一名玩家成为旁观者.
sm_votespec
```
### Server ConVar
```
// 指定投票文件的路径. 投票文件的位置位于configs目录下
// 默认值: "configs/cfg.txt"
votecfgfile "configs/<你的txt文件.txt>"
```
### Admin Cmd
```
// 管理员终止此次投票
sm_votecancel

// 全体回满血(可以作为一个投票选项，也可以管理员手动执行，具体见cfg.txt)
sm_hp
```
<hr>
