# DeviceSpoofX

将当前 Android 设备伪装为 **Xiaomi 17 Pro Max**，通过 OverlayFS 覆盖系统 `build.prop` 并结合 `resetprop` 注入属性，全面修改系统上报的设备型号、代号、品牌、营销名称等信息。适配 MIUI 12 至 HyperOS 3，支持 Magisk / KernelSU / APatch 三大 Root 方案，提供 WebUI 管理界面。


## 功能概述

- 覆盖 system、vendor、product、odm、system_ext 五个分区的 `build.prop`
- 对 `build.prop` 中不存在的属性使用 `resetprop` 补充注入
- 自动检测 HyperOS 3 并同步修改系统版本号
- 修改 Settings 数据库中的设备名称、蓝牙名称、WiFi Direct 名称
- 内置 WebUI 管理界面，可在 Root 管理器中直接查看伪装状态和属性详情
- 安装时自动清理旧版模块文件，支持平滑升级
- 卸载后重启即可完全恢复原始设备信息


## 伪装目标参数

| 属性         | 值                       |
|:-------------|:-------------------------|
| 营销名称     | Xiaomi 17 Pro Max        |
| 型号号码     | 2509FPN0BC               |
| 设备代号     | popsicle                 |
| 品牌         | Xiaomi                   |
| 制造商       | Xiaomi                   |
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
├── customize.sh               # 安装脚本（OverlayFS 覆盖生成）
├── post-fs-data.sh            # 早期启动属性注入（resetprop 补漏）
├── service.sh                 # 启动完成后修改 Settings 数据库
├── uninstall.sh               # 卸载清理
└── webroot/
    └── index.html             # WebUI 管理界面
```

### 工作原理

1. **安装阶段** (`customize.sh`)：复制各分区 `build.prop` 到模块目录，逐一替换目标属性值，由 Root 管理器通过 OverlayFS 在启动时覆盖原文件。

2. **早期启动** (`post-fs-data.sh`)：使用 `resetprop` 注入 `build.prop` 中可能不存在的属性（如 `ro.product.marketname`），以及 HyperOS 3 版本号属性。

3. **启动完成** (`service.sh`)：等待系统启动完毕后，通过 `settings put` 修改 Settings 数据库中的设备名称、蓝牙名称、WiFi Direct 设备名称，并通过 `resetprop` 设置持久化属性。

4. **卸载** (`uninstall.sh`)：清除持久化属性并删除模块文件，重启后系统自动恢复原始值。

### WebUI

基于 Vue 3 和 TDesign Mobile Vue 构建，通过 KernelSU/APatch 的 JavaScript Bridge 与系统交互。功能包括：

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
