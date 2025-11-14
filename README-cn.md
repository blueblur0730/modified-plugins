**[English](./README.md) | [中文](./README-cn.md)**

# modified-plugins

均在以下环境完成编译:

- sm1.13-7250
  - (SourceMod 引入虚拟地址 'Virtual Address' 的第一个版本)
  
依兴趣撰写或修改, 请在 **保留代码原作者名称** 的条件下随意使用这些代码.

你可以在 [发布页面这儿](https://github.com/blueblur0730/modified-plugins/releases) 直接获取不同sourcemod版本下编译的二进制文件.

## 构建

此仓库使用了 [nosoop 的 NinjaBuild-SMPlugins](https://github.com/nosoop/NinjaBuild-SMPlugin) 模板项目来构建编译插件. 在此十分感谢他. 你可以前往他的仓库去了解更多有关构建系统的信息. `modified-plugins` 仓库使用了修改后的模板版本来编译构建插件.

- 要求
  - Python 3.6 或更新版本.
  - Ninja Build System.
  - 一份干净完整的 SourceMod 编译器拷贝. 该目录下不应该有任何其他第三方的头文件库.
    - 你只需要 SourceMod 安装包下的 `addons/sourcemod/scripting/` 目录.

- 步骤
  - 为仓库创建一个文件夹.
  - 运行 `git clone --recursive https://github.com/blueblur0730/modified-plugins` 将仓库克隆至你的文件夹.
  - 打开文件克隆仓库下的文件 `configure.py`, 进行配置:
    - `destination_dir` 存放着一个插件以及它其他附带文件路径地址. 构建系统只会编译在这里定义下的插件路径.
    - `include_dirs` 存放着所有插件编译需要的头文件. 你不需要编辑这一栏.
    - `release_include_dirs` 存放着编译插件所提供的接口头文件. 你不需要编辑这一栏.
    - `spcomp_min_version` 标志着构建系统能够运行的最老的编译器版本. 此仓库要求编译器版本至少为sm1.12, 当然你也可以手动降低版本.
  - 配置好后, 运行 `python3 configure.py --spcomp-dir ${dir}`, `${dir}` 指代你的编译器路径.
  - 运行 `ninja`, 结果会存放在 `./build` 目录下.

- 其他

所有步骤在 Windows 和 Linux 平台下都以命令行形式运行.
你可以运行 `ninja -t cleandead` 或 `ninja -t clean` 来删除构建文件夹如果你想要重新构建编译.
