**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Mixmap

## 简介

随机选取有限数量的地图组成一张战役或者比赛.

该插件从游戏内部读取地图列表, 并提供高度的可配置能力，以多种方式组建地图池.

<hr>

## 特点

- 你不需要用一个配置文件来告诉插件地图列表是什么. 你所要做的只有选择你自己的地图池.

- 能够流畅地在两张不同战役的地图中切图. 就像正常过关一样.

- 理论上支持除 "清道夫" 和 "生还者" (以及其相关的突变模式) 之外的所有游戏模式. (包括突变模式和社区自制模式, 甚至自定义模式.)

- 地图池有一定的灵活性. 你可以自定义图池大小和图池的类型. 甚至实时地在游戏中选择自己的图池, 或者从预设文件中加载一个提前设定好的图池.

- 提供黑名单系统. 将你不喜欢的地图加入黑名单中, 你将不会再图池中遇见它.

- 角色状态在关卡切换中能够得以保存 (战役模式), 队伍比赛得分同样能够在关卡切换中保存下来 (对抗模式).

- 全部文本翻译提供. 你可以在翻译文件中自定义翻译语句.

- 轻松Debug. 可通过 [Log4sp拓展](https://github.com/F1F88/sm-ext-log4sp) 轻松管理日志或报错而不用重新编译或开关convar来进行debug.

<hr>

## 需求

- SourceMod 1.12+
- [MidHook 拓展](https://github.com/Scags/SM-MidHooks) by Scags.
- [SourceScramble 拓展](https://github.com/nosoop/SMExt-SourceScramble) by nosoop.
- [l4d2_source_keyvalues 插件](https://github.com/fdxx/l4d2_source_keyvalues) by fdxx.
- [l4d2_nativevote 插件](https://github.com/fdxx/l4d2_nativevote) by fdxx.
- [Left 4 DHooks Direct 插件 1.159+](https://forums.alliedmods.net/showthread.php?t=321696) by Silvers 以及其他贡献者.
- [colors.inc](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/include/colors.inc) 用于编译.
- [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc) 用于编译.

- 日志 (二选一)
  - [Log4sp 拓展 1.8.0+](https://github.com/F1F88/sm-ext-log4sp) by F1F88.
  - [Logger](https://github.com/PencilMario/L4D2-Not0721Here-CoopSvPlugins) by 夜羽真白 / Sir.P.
  
<hr>

## 已知存在冲突插件

- [[L4D2] Transition Restore Fix (修复过关装备属性混乱)](https://forums.alliedmods.net/showthread.php?t=336287) by soralll, 因使用 DHooks 挂钩相同的函数 `CTerrorPlayer::TransitionRestore`. 使用[此仓库内](https://github.com/blueblur0730/modified-plugins/tree/main/source/transition_restore_fix)修改版本可解决该问题.

- [Survivor Chat Select (8角色共存)](https://forums.alliedmods.net/showthread.php?p=2607394) by DeatChaos25, Mi123456 & Merudo, Lux, SilverShot, 因使用 DHooks 挂钩相同的函数 `RestoreTransitionedSurvivorBots`.使用[此仓库内](https://github.com/blueblur0730/modified-plugins/tree/main/source/survivor_chat_select)修改版本可解决该问题.

<hr>

## 安装

只需将所有文件扔在相应位置即可.

<hr>

## 配置

- 黑名单: 打开文件 `configs/l4d2_mixmap_blacklist.cfg`, 见内部说明.

- 预设图池文件: 打开文件夹 `configs/mixmap_presets/`, 内部说明写在 `preset1.cfg` 中. 你可以添加不限数量的与 `preset1.cfg` 格式一致的预设文件.

- 翻译文件: 打开文件夹 `translations/`, 里面存放着两个翻译文件: `l4d2_mixmap.phrases.txt`, 保存所有聊天框语句和菜单语句, `l4d2_mixmap_localizer.phrases.txt` 保存所有官方地图标签翻译和三方图名称翻译.  
  - 你可以添加三方图地图名称在翻译文件中. 例如:

```
解包三方图的 vpk 文件, 找到目录 `root/missions`, 打开文件, 你会见到如下结构:

"mission"
{
    ...
    "DisplayTitle"	"Carried Off"   // 这是这张战役的展示名称.
    ...

    "modes
    {
        "maps"
        {
            "1"
            {
                "Map"           "cwm1_intro"
                "DisplayName"   "The Riverbed"  // 这是这张地图的展示名称.
                "Image"         "maps/intro"
            }

            ...
        }
    }
}

注意到键 "DisplayTitle" 与 "DisplayName", 这些就是我们需要翻译的键值.
现在复制这些键值, 打开文件 `l4d2_mixmap_localizer.phrases.txt`, 拉到底部, 添加如下语句:

...
    "Carried Off"
    {
        "en"    "Carried Off"
        "chi"   "绝境逢生"      // 这里只是为了展示写在这里, 你应该将你的语言添加进对应的翻译文件中.
    }

    "The Riverbed"
    {
        "en"    "The Riverbed"
        "chi"   "河床"
    }
...

现在你已经完成三方图名称的翻译.
```

<hr>

## Map Pool

该插件拥有三种类型的图池: 

- 官方图池
- 三方图池
- 混合图池

以及两种选择类型:

- 自动选择
- 手动选择

和一种特殊图池:

- 由预设文件而定.

### 自动选择

就像名字一样, 官方图池只选择官方地图进入图池, 三方图池只选择三方图进入图池, 而混合图池选择官方图和三方图进入图池.

自动选择的图池遵循以下原则:

- 第一张图一定是某张战役的第一张图.
- 最后一张图一定是某张图的救援.
- 每个战役只能有一张地图进入图池. (后续可能会更新.)

这意味着你必须有与你对图池大小设定的数值相同的战役数才能构建一个图池. 否则构建会失败.

### 手动选择

你可以手动选择设定的有限数量的地图进入图池.

手动选择的图池遵循以下原则:

- 会先选择图池的类型: 即官方, 三方, 混合.
- 如果图池选择还未进行到最后一张图, 不能选择一张救援图在中间.
- 图池的最后一张图只可以是救援.
- 操作不可撤销. 退出选择菜单会终止本次选择.
- 地图按顺序选择.

这意味着你只需要有与图池大小的地图数即可.

### 由预设文件决定

确保你至少拥有一个预设文件, 并至少拥有一个有效的地图. 见文件 `preset1.cfg` 内部说明.

由预设文件决定的图池遵循以下原则:

- 无效地图名总是不会加入进图池中.
- 对图池大小不做限制.

警告: 你可以将一张救援图放在图池中间, 但你不应该! 否则关卡切换将会暂停.

<hr>

## 指令 & ConVars

见 [文件](./scripting/l4d2_mixmap/setup.sp).

## API

见 [文件](https://github.com/blueblur0730/modified-plugins/blob/main/include/l4d2_mixmap.inc).