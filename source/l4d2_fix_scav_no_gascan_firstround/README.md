# l4d2_fix_scav_no_gascan_firstround

### Introduction

- 全部代码由 Eyal282 编写, 来源于作者 Eyal282 对于一个解决方案的一个回复, 回复中作者直接给上了自己一个有关清道夫项目的源代码, 并指出在这个项目里已经附带了可行的利用检测并设置游戏内部的签名方法来解决清道夫开局无油桶的问题. 我将其中有利用到修复功能的代码提出编写成了一个单独的插件, 实践证明在没有readyup_scav插件 (主体思路是第一轮重置清道夫比赛两次) 的加载下, 通过/match以confogl加载插件的形式, 第一轮油桶确实存在, bug被修复了.

### Source: 
https://github.com/nagadomi/l4d2_scavenge_1st_round_skip/issues/1
