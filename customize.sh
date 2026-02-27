#!/system/bin/sh
# ============================================
# DeviceSpoofX
# customize.sh - 模块安装脚本
# 支持 Magisk / KernelSU / APatch
# ============================================

# ============================================
# 加载设备配置文件
# ============================================

PROFILE_KEY=$(cat "$MODPATH/current_profile" 2>/dev/null | tr -d '\r\n')
PROFILE_CONF="$MODPATH/profiles/${PROFILE_KEY}.conf"

if [ ! -f "$PROFILE_CONF" ]; then
    ui_print "! 错误: 找不到配置文件 ${PROFILE_KEY}.conf"
    abort "! 安装中止"
fi

. "$PROFILE_CONF"

ui_print ""
ui_print "╔══════════════════════════════════════╗"
ui_print "║        DeviceSpoofX v2.0.0           ║"
ui_print "║  适配 MIUI 12 ~ HyperOS 3           ║"
ui_print "║  支持 Magisk / KernelSU / APatch     ║"
ui_print "╚══════════════════════════════════════╝"
ui_print ""
ui_print "- 当前配置: $PROFILE_NAME"
ui_print ""

# ============================================
# 升级: 强制清理旧版文件
# ============================================

OLD_MODULE="/data/adb/modules/DeviceSpoofX"
OLD_MODULE_LEGACY="/data/adb/modules/Xiaomi17ProMax"

# 清理当前版本旧文件
if [ -d "$OLD_MODULE" ]; then
    ui_print "- 检测到旧版模块，清理旧文件..."
    rm -rf "$OLD_MODULE/webroot" 2>/dev/null
    rm -rf "$OLD_MODULE/system" 2>/dev/null
    rm -f "$OLD_MODULE/is_hyperos3" 2>/dev/null
    ui_print "  旧版文件已清理"
fi

# 清理旧名称模块残留
if [ -d "$OLD_MODULE_LEGACY" ]; then
    ui_print "- 检测到旧版 Xiaomi17ProMax 模块，清理..."
    rm -rf "$OLD_MODULE_LEGACY" 2>/dev/null
    ui_print "  旧版模块已清理"
fi

# ============================================
# Root 方案检测
# ============================================

ROOT_SOLUTION="Unknown"

if [ -n "$KSU" ] && [ "$KSU" = "true" ]; then
    ROOT_SOLUTION="KernelSU"
    ui_print "- Root 方案: KernelSU ${KSU_VER:-unknown}"
elif [ -n "$APATCH" ] && [ "$APATCH" = "true" ]; then
    ROOT_SOLUTION="APatch"
    ui_print "- Root 方案: APatch ${APATCH_VER:-unknown}"
elif [ -n "$MAGISK_VER" ]; then
    ROOT_SOLUTION="Magisk"
    ui_print "- Root 方案: Magisk $MAGISK_VER"
else
    ui_print "- Root 方案: 未知"
fi

ui_print "- Android API: $API"
ui_print "- 架构: $ARCH"

# ============================================
# 当前设备信息
# ============================================

CURRENT_MODEL=$(getprop ro.product.model)
CURRENT_MARKET=$(getprop ro.product.marketname)
CURRENT_DEVICE=$(getprop ro.product.device)
ui_print "- 当前型号: $CURRENT_MODEL"
ui_print "- 当前营销名: $CURRENT_MARKET"
ui_print "- 当前代号: $CURRENT_DEVICE"
ui_print ""
ui_print "- 目标型号: $TARGET_MODEL"
ui_print "- 目标营销名: $TARGET_MARKETNAME"
ui_print "- 目标代号: $TARGET_DEVICE"
ui_print ""

# ============================================
# HyperOS 3 版本号检测
# ============================================

MIUI_VER=$(getprop ro.miui.ui.version.name)
DISPLAY_ID=$(getprop ro.build.display.id)
MI_OS_INC=$(getprop ro.mi.os.version.incremental)
BUILD_INC=$(getprop ro.build.version.incremental)

is_hyperos3="false"
case "$MIUI_VER" in V170*) is_hyperos3="true" ;; esac
case "$DISPLAY_ID" in OS3*|3.*) is_hyperos3="true" ;; esac
case "$MI_OS_INC" in OS3*|3.*) is_hyperos3="true" ;; esac
case "$BUILD_INC" in OS3*|3.*) is_hyperos3="true" ;; esac

if [ "$is_hyperos3" = "true" ]; then
    ui_print "- 检测到 HyperOS 3，将在启动时修改版本号"
    echo "true" > "$MODPATH/is_hyperos3"
else
    ui_print "- 未检测到 HyperOS 3，跳过版本号修改"
fi

# ============================================
# 设置权限
# ============================================

ui_print ""
ui_print "- 设置文件权限..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755

ui_print ""
ui_print "- 安装完成！重启后生效。"
ui_print "- 属性将通过 resetprop 在每次启动时注入。"
ui_print "- 如需恢复，请在 ${ROOT_SOLUTION} 中卸载本模块后重启。"
ui_print ""
