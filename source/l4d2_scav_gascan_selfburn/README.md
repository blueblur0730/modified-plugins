# l4d2_scav_gascan_selfburn

### Introduction
 - 插件原作者 Ratchet. 插件原名叫l4d2_fix_scav_nm5.
 - 插件会在清道夫模式下 (战役和对抗中的清道夫事件不会触发插件) 对特定地图检测油桶xyz轴位置是否非法并点燃.
 - 可限制最大自燃油桶数量.
 - 支持文字输出翻译.

### Source
 - https://forums.alliedmods.net/showthread.php?t=178125

<hr>

### Server ConVar
```
// 开启插件
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_enable "1"

// 开启x轴检测 (min)
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_x_min "1"

// 开启x轴检测 (max)
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_x_max "1"

// 开启y轴检测 (min)
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_y_min "1"

// 开启y轴检测 (max)
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_y_max "1"

// 开启z轴检测 (min)
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_detect_z_max "1"

// 开启z轴检测 (max)
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_detect_z_min "1"

// 开启油桶自燃数量限制
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_burned_limit_enable "1"

// 每一次油桶检测所需的时间间隔
// 默认值: 10.0
// min: 0.0, max: 不限
l4d2_scav_gascan_selfburn_interval "10.0"

// 最大自燃油桶数量限制?
// 默认值: 4
// min: 0, max: 不限
l4d2_scav_gascan_burned_limit "4"

```
<hr>

<hr>

### Config File

```
在sourcemod/configs/l4d2_scav_gascan_selfburn.txt里, 你需要做如下编辑:

	"c8m5_rooftop"		//这里是你需要进行边界设置的清道夫地图名
	{
		"height_zlimit_min"		"500.0"		//这一条同时影响强迫玩家死亡的检测
		"height_zlimit_max"		"0.0"
		"width_xlimit_max"		"0.0"
		"width_ylimit_max"		"0.0"
		"width_xlimit_min"		"0.0"
		"width_ylimit_min"		"0.0"
	}

 - 控制台输入 cl_showpos 1 开启坐标显示, 进入你的服务器寻找你认为的边界坐标.
 - 所有引索后面的数字应该为浮点型数字, 即都要带小数点.
 - 所有引索后面的参数如果在特定轴检测开启的情况下填0.0, 插件不会在这一边界进行检测.
 - 超过max数字的，小于min数字的值的油桶会被点燃.
 - 遵循正负数比大小法则.

```
<hr>
