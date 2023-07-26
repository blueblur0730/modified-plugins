# l4d2_fix_scav_issues

### Introduction
- 解决清道夫第一轮不生成油桶的问题.
- 允许设置局数限制.
- 提供管理员指令手动一次性生成所有油桶
- 检测是否安装readyup插件, 若安装, 采用另一种油桶生成方案, 否则使用原解决方案 (Credit to Eyal282)

### Source: 
https://github.com/nagadomi/l4d2_scavenge_1st_round_skip/issues/1

### Requirment
- Left4Dhooks 1.134+
- Readyup (Optional)

<hr>
### Admin Cmd
```
// 手动生成所有油桶 (注意, 可以叠加生成), 需要cvar为开.
sm_enrichgascan

```
### Server ConVar
```
// 允许管理员使用生成油桶命令?
// 默认值: 0
// min: 0; max: 1
l4d2_allow_enrich_gascan "0"

// 设置清道夫开局局数. 合法参数分别为1, 3, 5
// 默认值: 5
// min: 0; max: 5
l4d2_scavenge_rounds "5"
```
<hr>