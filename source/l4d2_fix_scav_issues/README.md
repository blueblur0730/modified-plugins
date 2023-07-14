# l4d2_fix_scav_issues

### Introduction

- 全部代码由 Eyal282 编写, 来源于作者 Eyal282 对于一个解决方案的一个回复, 回复中作者直接给上了自己一个有关清道夫项目的源代码, 并指出在这个项目里已经附带了可行的利用检测并设置游戏内部的签名解决清道夫开局无油桶的问题. 我将其中有利用到修复功能的代码提出编写成了一个单独的插件, 实践证明在没有readyup_scav插件 (主体思路是第一轮重置清道夫比赛两次) 的加载下, 通过/match以confogl加载插件的形式, 第一轮油桶确实存在, bug被修复了. (该签名已收录至left4dhooks 1.134)
- 注意，请不要在confogl服务器中的server.cfg里使用sm_forcematch使服务器启动时便加载清道夫配置! 会导致的已知bug有: ①第一轮油桶过量生成. ②当一方赢得 (比如已经五局三胜)比赛时, 比赛将会无穷无尽继续.
- 移植了readyup_scav设置局数的代码.

### Source: 
https://github.com/nagadomi/l4d2_scavenge_1st_round_skip/issues/1

### Requirment
- Left4Dhooks 1.134+

<hr>

### Server ConVar
```
// 设置清道夫开局局数. 合法参数分别为1, 3, 5
// 默认值: 5
// min: 0; max: 5
l4d2_scavenge_rounds "5"
```
<hr>