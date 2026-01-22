**[English](./README.md) | [中文](./README-cn.md)**

# modified-plugins

All Compiled with

- sm1.13-7288
  
Written or modified in interest, feel free to use these codes by **keeping their original author name**.

You can fetch the plugin binaries through [releases here](https://github.com/blueblur0730/modified-plugins/releases) compiling against different sourcemod version.

## Build

This respository uses [nosoop's NinjaBuild-SMPlugins](https://github.com/nosoop/NinjaBuild-SMPlugin) template project to build plugins. Big thanks to him. Check out his repo for more detail about the build system. `modified-plugins` repo uses a modified template version to build plugins.

- Requirements
  - Python 3.6 or newer.
  - Ninja Build System.
  - A clean copy of the SourceMod compiler. It should not contain any third-party includes.
    - You only need the `addons/sourcemod/scripting/` directory from the SourceMod package.

- Steps
  - Make a folder for the repo.
  - Run `git clone --recursive https://github.com/blueblur0730/modified-plugins` to clone the repo to your folder.
  - Open the file `configure.py` in the cloned repo, configure the settings:
    - `destination_dir` is the directory where a plugin and its component lie in. Only compiles the plugins with its path inside of it.
    - `include_dirs` is the directory where all the plugins' dependencies lie in. You do not have to edit this line.
    - `release_include_dirs` is the directory that place the generated include files from a plugin. You do not have to edit this line.
    - `spcomp_min_version` indicates the oldest version that the SourcePawn compiler is for build system to operate on. This repo requires at least sm1.12 to compile, of course you can lower it by yourself.
  - After all setup, run `python3 configure.py --spcomp-dir ${dir}`, `${dir}` indicates the path where the compiler sit.
  - Run `ninja`, the results are in the `./build` directory.

- Other

All steps runs in command line environment in both Windows and Linux platform.
You can run `ninja -t cleandead` or `ninja -t clean` to remove the build folder if you want to rebuild.
