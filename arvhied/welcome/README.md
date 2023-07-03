# welcome
### 该插件不再进行工作
### Introduction
 - 这个插件大部分代码的原作者是: A1R, 东. 我进行了一些调整和功能新增.
 - 聊天框显示玩家连接服务器信息
 - 显示玩家时长
 - 显示玩家国家地区
 - 聊天框显示玩家断开连接信息

### Requirments
 - l4d2_playtime_interface插件
 - GeoIP拓展 (Sourcemod已自带)

### Source
 - https://github.com/A1oneR/AirMod/blob/main/addons/sourcemod/scripting/Welcome.sp 原插件
 - https://github.com/Target5150/MoYu_Server_Stupid_Plugins/tree/master/The%20Last%20Stand/l4d2_playtime_interface (l4d2_playtime_interface, 作者: Forgetest)

<hr>

### Admin Cmd
```
// 显示玩家的时长和国家地区
sm_playerinfo
```

### Server ConVar
```
// 是否开启插件
// 默认值: 1
// min: 0, max: 1
l4d2_enable_welcome "1"

// 是否开启时长显示
// 默认值: 1
// min: 0, max: 1
l4d2_show_welcome_playtime "1"

// 是否开启国家或地区显示
// 默认值: 1
// min: 0, max: 1
l4d2_show_welcome_country "1"

// 是否开启城市显示
// 默认值: 1
// min: 0, max: 1
l4d2_show_welcome_city "1"

// 是否开启玩家身份显示 (若开启会区分玩家是否为管理员, 若未开启则默认显示玩家)
// 默认值: 1
// min: 0, max: 1
l4d2_show_welcome_identity "1"

// 是否开启断开连接信息提示
// 默认值: 1
// min: 0, max: 1
l4d2_show_welcome_disconnect_info "1"
```

<hr>
