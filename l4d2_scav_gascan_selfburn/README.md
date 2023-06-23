# l4d2_scav_gascan_selfburn
### Introduction
 - 插件原作者 Ratchet. 插件原名叫l4d2_fix_scav_nm5. 我对插件功能进行了拓展.
 - 插件会在清道夫模式下 (战役和对抗中的清道夫事件不会触发插件) 对特定地图检测油桶位置是否非法并点燃.
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

// 开启xy轴检测
// 默认值: 1
// min: 0, max:1
l4d2_scav_gascan_selfburn_square "1"

// 开启z轴检测
// 默认值: 1
// min: 0, max: 1
l4d2_scav_gascan_selfburn_height "1"

```
<hr>

<hr>

### Config File

```
在sourcemod/config/l4d2_scav_gascan_selfburn.txt里, 你需要做如下编辑:

	"c8m5_rooftop"		//这里是你需要进行边界设置的清道夫地图名
	{
		"height_zlimit_down"		"500.0"		//这一条同时影响强迫玩家死亡的检测
		"height_zlimit_up"		"6000.0"
		"width_xlimit_one"		""
		"width_ylimit_one"		""
		"width_xlimit_two"		""
		"width_ylimit_two"		""
	}

下面对引索进行一一说明:
 - 所有引索后面的数字应该为浮点型数字, 即都要带小数点
 - height_zlimit_down指油桶在z轴不能低于的垂直边界, 低于这个垂直边界油桶会被点燃.
 - height_zlimit_up指油桶在z轴不能高于的垂直边界, 高于这个垂直边界油桶会被点燃.
 - width_xlimit_one指油桶在x轴上不能大于的水平边界, 大于这个水平边界油桶会被点燃.
 - width_ylimit_one指油桶在y轴上不能大于的水平边界, 大于这个水平边界油桶会被点燃.
 - width_xlimit_two指油桶在x轴上不能小于的水平边界, 小于这个水平边界油桶会被点燃.
 - width_ylimit_two指油桶在y轴上不能小于的水平边界, 小于这个水平边界油桶会被点燃.
 - 所有引索后面的参数如果不填, 即没有数值, 插件不会在这个方向检测油桶并点燃油桶.

```
<hr>
