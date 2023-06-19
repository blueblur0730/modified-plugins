# changelog
### Introduction
 - 插件原作者Spoon. 我进行了一些功能增添.
 - 提供命令输入以查看当前配置文本说明的链接.
   - 通过检测l4d_readyup_cfg_name的值来匹配keyvalue显示对应的链接.
 - 提供广告循环功能提示命令功能.
 - 提供可选MOTD说明功能.

# Source
 - https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/changelog.sp

<hr>

### Client Cmd
```
// 在聊天框显示连接
sm_info
```

### Server ConVars
```
// 开启插件
// 默认值: 1
// min: 0, max: 1
sm_enable_changelog "1"

// 开启广告功能
// 默认值: 1
// min: 0, max: 1
sm_changelog_advertisement "1"

// 广告循环间隔(数值必须是浮点数, 也就是必须要带小数点)
// 默认值: 60.0
// min: 0.0, max: 不限
sm_changelog_advertisement_interval "60.0"

// 输入命令时是否同时打开对应的MOTD界面?
// 默认值: 0
// min: 0, max: 1
sm_changelog_cmd_show_MOTD "0"
```

<hr>