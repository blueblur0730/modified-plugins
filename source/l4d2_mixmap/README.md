**[English](./README.md) | [中文](./README-cn.md)**

# [L4D2] Mixmap

## Introduction

Randomly selects limited maps to build a mixed campaign or match.

This plugin reads map list from the game internally, and forms map pool in muiltple ways with a high customization ability provided.

<hr>

## Features

- You do not need a config file to to tell the plugin what the map list is. All you have to do is to choose your own map pool.

- Splendidly changes level between two different campaign maps. Just like a normal level transisition.

- Theoretically supports all gamemodes (mutations and community modes, even custom modes.) except for "Scavenge", "Survivor" and all of its related mutations and community modes.

- Flexible map pool. You can customize the size of the pool, the type of the pool. Even pick up your own map pool manully in the real-time game, or loads a pre-defined map pool from a file.

- Blacklist system provided. Add your hater into the list and you will never meet them in the map pool.

- Character status reserved between level transisition in coop based modes (coop modes), team scores are also reserved between level transisition (versus modes).

- Full translation provided. You can customize the phrases in the translation files.

- Easily debugging. See plugin info and errors through [Log4sp Extension](https://github.com/F1F88/sm-ext-log4sp) without actually recompiling them or accessing convar.

<hr>

## Requirements

- SourceMod 1.12+
- [Log4sp Extension 1.8.0+](https://github.com/F1F88/sm-ext-log4sp) by F1F88.
- [MidHook Extension](https://github.com/Scags/SM-MidHooks) by Scags.
- [SourceScramble Extension](https://github.com/nosoop/SMExt-SourceScramble) by nosoop.
- [l4d2_source_keyvalues Plugin](https://github.com/fdxx/l4d2_source_keyvalues) by fdxx.
- [l4d2_nativevote Plugin](https://github.com/fdxx/l4d2_nativevote) by fdxx.
- [Left 4 DHooks Direct Plugin](https://forums.alliedmods.net/showthread.php?t=321696) by Silvers and others.

- [colors.inc](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/include/colors.inc) to compile.
- [gamedata_wrapper.inc](https://github.com/blueblur0730/modified-plugins/blob/main/include/gamedata_wrapper.inc) to compile.

<hr>

## Known Conflicted Plugins

- [[L4D2] Transition Restore Fix](https://forums.alliedmods.net/showthread.php?t=336287) by soralll, due to hooking a same function `CTerrorPlayer::TransitionRestore` using DHooks.

- [Survivor Chat Select](https://forums.alliedmods.net/showthread.php?p=2607394) by DeatChaos25, Mi123456 & Merudo, Lux, SilverShot, due to hooking the same function `RestoreTransitionedSurvivorBots` using DHooks.

To resolve, we need to push an update to left4dhooks, and also update thses plugins.

<hr>

## Installation

Just put all the staff here in your folder.

<hr>

## Configuration

- Blacklist: Open file `configs/l4d2_mixmap_blacklist.cfg`, see documentation inside.

- Preset Map Pool File: Open folder `configs/mixmap_presets/`, the documentation is inside the file `preset1.cfg`. You can add unlimited number of preset files into this folder with correct format like `preset1.cfg`.

- Translation: Open folder `translations/`, there it lies two translation files here: `l4d2_mixmap.phrases.txt`, stores all chat info and menu texts, while `l4d2_mixmap_localizer.phrases.txt` stores the the translations of official map tags.  
  - You can also add third party map phrases into the translation. For example:

```
Unpack a third party map's vpk, head to directory `root/missions`, open the file and you will see a structure:

"mission"
{
    ...
    "DisplayTitle"	"Carried Off"   // This is the title of the campaign.
    ...

    "modes
    {
        "maps"
        {
            "1"
            {
                "Map"           "cwm1_intro"
                "DisplayName"   "The Riverbed"  // This is the display name of the map.
                "Image"         "maps/intro"
            }

            ...
        }
    }
}

Notice the key "DisplayTitle" and "DisplayName", these are the keys that we are translating for.
Now copy the values of the key, open file `l4d2_mixmap_localizer.phrases.txt`, draw down to the bottum, add the following lines:

...
    "Carried Off"
    {
        "en"    "Carried Off"
        "chi"   "绝境逢生"      // This is only for demostration. You should add this translation to your own translation file.
    }

    "The Riverbed"
    {
        "en"    "The Riverbed"
        "chi"   "河床"
    }
...

Now you have completed translating third party map's phrases.
```

<hr>

## Map Pool

This plugin has 3 types of pool: 

- Official
- Custom
- Mixtape

And 2 types of selection:

- Automatically Select
- Manually Select

And 1 special map pool:

- Defined by preset file.

### Automatically Selected

Just like its name, Official map pool selects only official maps, Custom map pool selects only custom maps, and Mixtape map pool selects both official and custom maps.

Map pool that is automatically selected following rules below:

- The first map is always the first map of some campaigns.
- The last map is always the last map of some campaigns.
- Each campaign can only have 1 map selected into the pool. (May change in the future.)

This means you should always have at least the same number of campaigns that you had have set the size for your map pool. Otherwise the operation will fail.

### Manually Selected

You can select a limited number defined by the size of the map pool of maps into the pool.

Map pool that is manually selected following rules below:

- Will first choose what kind of type the map pool is, which is Official, Custom, Mixtape.
- The last map can not be choosen if the map pool has not reached the end.
- The last map of the map pool will always the the last map of some campaign.
- Choice is irrevocable. Exits the select menu will abort the selection.
- Maps are selected sequentially.

This means you only need number of maps that the size of the map pool required.

### Defined By Preset File

Make sure you have at least one preset file, and contains at least one valid map name. See documentation in `preset1.cfg`.

Map pool that is defined by a preset file following the rules below:

- Invalid map name will always not be added into the pool.
- No restriction on the size of the pool.

Warning: You can put a finale map in the middle of the pool list but you should not do that! Otherwise the level transitioning will be suspended.

<hr>

## Commands & ConVars

See [file](./scripting/l4d2_mixmap/setup.sp).

## API

See [file](https://github.com/blueblur0730/modified-plugins/blob/main/include/l4d2_mixmap.inc).