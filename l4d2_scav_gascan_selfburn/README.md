# l4d2_scav_gascan_selfburn
### Introduction
 - 插件原作者 Ratchet. 插件原名叫l4d2_fix_scav_nm5. 我对插件功能进行了拓展.
 - 插件会在清道夫模式下 (战役和对抗中的清道夫事件不会触发插件) 对特定地图检测油桶xyz轴位置是否非法并点燃.
 - 可限制最大自燃油桶数量.
 - 检测玩家高度并强制使其死亡.
 - 支持文字输出翻译.

### Requirments
 - Left4dhooks

### Source
 - https://forums.alliedmods.net/showthread.php?t=178125

<hr>

### Server ConVar
```
// 开启插件
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_enable "1"

// 开启x轴检测
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_x "1"

// 开启y轴检测
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_detect_y "1"

// 开启z轴检测
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_detect_z "1"

// 开启插件Debug
// 默认值: 0
// min: 0, max: 1
l4d2_scav_gascan_selfburn_debug "0"

// 开启油桶自燃数量限制
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_burned_limit_enable "1"

// 开启检测玩家超界使其死亡的功能(只检测z轴)
// 默认值: 0
// min: 0, max: 1
l4d2_scav_kill_player "0"

// 每一次油桶检测所需的时间间隔
// 默认值: 10.0
// min: 0.0, max: 不限
l4d2_scav_gascan_selfburn_interval "10.0"

// 每一次玩家超界使其死亡检测的时间间隔(只检测z轴)
// 默认值: 3.0
// min: 0.0, max: 不限
l4d2_scav_kill_player_interval "3.0"

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
		"height_zlimit_max"		"6000.0"
		"width_xlimit_max"		"8100.0"
		"width_ylimit_max"		"9800.0"
		"width_xlimit_min"		"4700.0"
		"width_ylimit_min"		"7200.0"
	}

下面对引索进行一一说明:
 - 控制台输入 cl_showpos 1 开启坐标显示, 进入你的服务器寻找你认为的边界坐标.
 - 所有引索后面的数字应该为浮点型数字, 即都要带小数点.
 - height_zlimit_min指油桶在z轴不能低于的垂直边界, 低于这个垂直边界油桶会被点燃.
 - height_zlimit_max指油桶在z轴不能高于的垂直边界, 高于这个垂直边界油桶会被点燃.
 - width_xlimit_max指油桶在x轴上不能大于的水平边界, 大于这个水平边界油桶会被点燃.
 - width_ylimit_max指油桶在y轴上不能大于的水平边界, 大于这个水平边界油桶会被点燃.
 - width_xlimit_min指油桶在x轴上不能小于的水平边界, 小于这个水平边界油桶会被点燃.
 - width_ylimit_min指油桶在y轴上不能小于的水平边界, 小于这个水平边界油桶会被点燃.
 - 所有引索后面的参数如果在特定轴检测开启的情况下不填, 即没有数值, 其他数值也不会检测, 即插件相当于未开启.
 - 如果坐标是负的该怎么办? 只要遵循负数比大小法则就行.
   例如:y轴上有两个我想设置的界限坐标-9000.0和-5000.0, 因为-9000.0 < -5000.0, 所以我会把-9000.0填在"width_ylimit_min"内, 把-5000.0填在"width_ylimit_max"内, 其他轴类似.

```
<hr>
