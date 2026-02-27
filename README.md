# DeviceSpoofX

将当前 Android 设备伪装为指定机型，通过 `resetprop` 在每次启动时直接注入系统属性，全面修改系统上报的设备型号、代号、品牌、营销名称、运行内存等信息。适配 MIUI 12 至 HyperOS 3，支持 Magisk / KernelSU / APatch 三大 Root 方案，提供 WebUI 管理界面。


## 功能概述

- 使用 `resetprop` 直接注入 system、vendor、product、odm、system_ext 全部分区的设备属性
- 伪装运行内存 (RAM) 显示大小
- 自动检测 HyperOS 3 并同步修改系统版本号
- 修改 Settings 数据库中的设备名称、蓝牙名称、WiFi Direct 名称
- 设备配置文件独立存放，支持多机型扩展
- 内置 WebUI 管理界面，自动读取当前配置文件展示伪装状态
- 安装时自动清理旧版模块文件，支持平滑升级
- 卸载后重启即可完全恢复原始设备信息


## 当前内置机型

| 属性         | 值                       |
|:-------------|:-------------------------|
| 营销名称     | Xiaomi 17 Pro Max        |
| 型号号码     | 2509FPN0BC               |
| 设备代号     | popsicle                 |
| 品牌         | Xiaomi                   |
| 制造商       | Xiaomi                   |
| 运行内存     | 16GB                     |
| HyperOS 版本 | OS3.0.45.0.WPBCNXM       |


## 兼容性

### Root 方案

| Root 方案      | 最低版本   | 支持状态 |
|:---------------|:-----------|:---------|
| Magisk         | v20.4+     | 支持     |
| KernelSU       | 任意版本   | 支持     |
| APatch         | 任意版本   | 支持     |

### 系统版本

| 系统版本          | 支持状态                     |
|:------------------|:-----------------------------|
| MIUI 12 / 13 / 14 | 支持                        |
| HyperOS 1.0 / 2.0 | 支持                        |
| HyperOS 3.0       | 支持（自动修改系统版本号）   |


## 技术实现

### 模块结构

```
DeviceSpoofX/
├── META-INF/                  # Magisk 刷入框架
│   └── com/google/android/
│       ├── update-binary
│       └── updater-script
├── module.prop                # 模块元信息
├── current_profile            # 当前激活的配置名
├── profiles/                  # 设备配置文件目录
│   └── xiaomi-17-pro-max.conf
├── customize.sh               # 安装脚本（加载配置、环境检测）
├── post-fs-data.sh            # 早期启动属性注入（resetprop 主力）
├── service.sh                 # 启动完成后修改 Settings 数据库
├── uninstall.sh               # 卸载清理
└── webroot/
    └── index.html             # WebUI 管理界面
```

### 设备配置文件

每个机型对应一个 `.conf` 文件，存放在 `profiles/` 目录下，格式如下：

```bash
PROFILE_NAME="Xiaomi 17 Pro Max"
TARGET_MODEL="2509FPN0BC"
TARGET_DEVICE="popsicle"
TARGET_NAME="popsicle"
TARGET_BRAND="Xiaomi"
TARGET_MANUFACTURER="Xiaomi"
TARGET_MARKETNAME="Xiaomi 17 Pro Max"
TARGET_DISPLAY_ID="OS3.0.45.0.WPBCNXM"
TARGET_HOSTNAME="Xiaomi-17-Pro-Max"
TARGET_RAM="17179869184"
```

`current_profile` 文件中存放当前激活的配置名（如 `xiaomi-17-pro-max`），所有脚本和 WebUI 根据此文件加载对应配置。新增机型只需添加 `.conf` 文件并修改 `current_profile`。

### 工作原理

1. **安装阶段** (`customize.sh`)：加载设备配置文件，检测当前设备信息和 Root 方案，判断是否为 HyperOS 3 并写入标记文件，清理旧版模块残留。

2. **早期启动** (`post-fs-data.sh`)：加载设备配置文件，使用 `resetprop -n` 直接注入所有目标属性，包括型号、代号、品牌、营销名称、运行内存等。若检测到 HyperOS 3 标记，同时注入系统版本号属性。

3. **启动完成** (`service.sh`)：加载设备配置文件，等待系统启动完毕后，通过 `settings put` 修改 Settings 数据库中的设备名称、蓝牙名称、WiFi Direct 设备名称，并通过 `resetprop` 设置持久化属性和网络主机名。

4. **卸载** (`uninstall.sh`)：清除持久化属性并删除模块文件，重启后系统自动恢复原始值。

### WebUI

基于 Vue 3 和 TDesign Mobile Vue 构建，通过 KernelSU/APatch 的 JavaScript Bridge 与系统交互。功能包括：

- 动态读取 `current_profile` 和对应配置文件，展示当前伪装目标
- 显示模块激活状态和 Root 方案信息
- 展示伪装目标参数和当前系统属性对比
- 分组展示所有已修改的系统属性及其当前值
- 支持暗黑模式（自动跟随系统）


## 安装方法

1. 从 [Releases](https://github.com/VasilyZa/DeviceSpoofX/releases) 页面下载最新版本的 ZIP 文件
2. 打开 Magisk / KernelSU / APatch 管理器
3. 选择「从本地安装」，选中下载的 ZIP 文件
4. 等待安装完成后重启设备

如需恢复原始设备信息，在管理器中卸载本模块后重启即可。


## 构建

项目通过 GitHub Actions 自动构建。推送到 `main` 分支时自动触发 CI 流程：

1. **变更检测** — 检查模块文件是否有改动
2. **代码检查** — ShellCheck 静态分析和模块结构验证
3. **构建发布** — 自动递增版本号、打包 ZIP、上传 Artifact

通过手动触发 workflow 并选择发布模式可创建正式 Release。


## 版本号规则

- 基础版本号（如 `v2.0`）在 `module.prop` 中手动维护
- Patch 版本号由 GitHub Actions 根据已有 tag 自动递增
- CI 构建版本带 `-ci` 后缀（如 `v2.0.1-ci`），正式发布不带后缀
- `versionCode` 随版本号同步递增


## 许可证

本项目基于 [GNU General Public License v3.0](LICENSE) 开源。
