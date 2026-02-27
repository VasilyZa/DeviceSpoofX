#!/system/bin/sh
# ============================================
# DeviceSpoofX
# customize.sh - OverlayFS 模块安装脚本
# 安装时复制并修改各分区 build.prop
# 支持 Magisk / KernelSU / APatch
# ============================================

ui_print ""
ui_print "╔══════════════════════════════════════╗"
ui_print "║        DeviceSpoofX v2.0.0           ║"
ui_print "║  适配 MIUI 12 ~ HyperOS 3           ║"
ui_print "║  支持 Magisk / KernelSU / APatch     ║"
ui_print "║  模式: OverlayFS                     ║"
ui_print "╚══════════════════════════════════════╝"
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
    if [ -f "$OLD_MODULE/adb_root_enabled" ]; then
        ADB_ROOT_WAS_ON="true"
        ui_print "  保留 ADB Root 配置"
    fi
    ui_print "  旧版文件已清理"
fi

# 清理旧名称模块残留
if [ -d "$OLD_MODULE_LEGACY" ]; then
    ui_print "- 检测到旧版 Xiaomi17ProMax 模块，清理..."
    if [ -f "$OLD_MODULE_LEGACY/adb_root_enabled" ]; then
        ADB_ROOT_WAS_ON="true"
    fi
    rm -rf "$OLD_MODULE_LEGACY" 2>/dev/null
    ui_print "  旧版模块已清理"
fi

# ============================================
# 目标设备参数
# ============================================

TARGET_MODEL="2509FPN0BC"
TARGET_DEVICE="popsicle"
TARGET_NAME="popsicle"
TARGET_BRAND="Xiaomi"
TARGET_MANUFACTURER="Xiaomi"
TARGET_MARKETNAME="Xiaomi 17 Pro Max"

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
# OverlayFS: 修改 build.prop 的通用函数
# ============================================

# 在 build.prop 中替换或追加属性
# 用法: patch_prop <文件路径> <属性名> <属性值>
patch_prop() {
    local file="$1"
    local key="$2"
    local value="$3"
    if grep -q "^${key}=" "$file" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

# 复制并修改指定分区的 build.prop
# 用法: overlay_partition <源路径> <模块内目标目录> <分区前缀>
overlay_partition() {
    local src_prop="$1"
    local dest_dir="$2"
    local prefix="$3"

    if [ ! -f "$src_prop" ]; then
        ui_print "  跳过: $src_prop (不存在)"
        return
    fi

    mkdir -p "$dest_dir"
    cp -af "$src_prop" "${dest_dir}/build.prop"

    local f="${dest_dir}/build.prop"

    # 型号
    patch_prop "$f" "ro.product.${prefix}model" "$TARGET_MODEL"
    # 设备代号
    patch_prop "$f" "ro.product.${prefix}device" "$TARGET_DEVICE"
    # 产品名
    patch_prop "$f" "ro.product.${prefix}name" "$TARGET_NAME"
    # 品牌
    patch_prop "$f" "ro.product.${prefix}brand" "$TARGET_BRAND"
    # 营销名称
    patch_prop "$f" "ro.product.${prefix}marketname" "$TARGET_MARKETNAME"

    ui_print "  已覆盖: $src_prop ($(wc -l < "$f") 行)"
}

# ============================================
# OverlayFS: 逐分区复制并修改 build.prop
# ============================================

ui_print "- 生成 OverlayFS 覆盖文件..."

# /system/build.prop
SYS_PROP="$MODPATH/system/build.prop"
if [ -f /system/build.prop ]; then
    mkdir -p "$MODPATH/system"
    cp -af /system/build.prop "$SYS_PROP"
    patch_prop "$SYS_PROP" "ro.product.model" "$TARGET_MODEL"
    patch_prop "$SYS_PROP" "ro.product.device" "$TARGET_DEVICE"
    patch_prop "$SYS_PROP" "ro.product.name" "$TARGET_NAME"
    patch_prop "$SYS_PROP" "ro.product.brand" "$TARGET_BRAND"
    patch_prop "$SYS_PROP" "ro.product.manufacturer" "$TARGET_MANUFACTURER"
    patch_prop "$SYS_PROP" "ro.product.marketname" "$TARGET_MARKETNAME"
    patch_prop "$SYS_PROP" "ro.build.product" "$TARGET_DEVICE"
    patch_prop "$SYS_PROP" "ro.build.description" "${TARGET_NAME}-user 16 BP1A.250305.001 release-keys"
    # system 分区前缀属性
    patch_prop "$SYS_PROP" "ro.product.system.model" "$TARGET_MODEL"
    patch_prop "$SYS_PROP" "ro.product.system.device" "$TARGET_DEVICE"
    patch_prop "$SYS_PROP" "ro.product.system.name" "$TARGET_NAME"
    patch_prop "$SYS_PROP" "ro.product.system.brand" "$TARGET_BRAND"
    patch_prop "$SYS_PROP" "ro.product.system.marketname" "$TARGET_MARKETNAME"
    ui_print "  已覆盖: /system/build.prop"
fi

# /vendor/build.prop
overlay_partition /vendor/build.prop "$MODPATH/system/vendor" "vendor."

# /product/build.prop
overlay_partition /product/build.prop "$MODPATH/system/product" "product."

# /odm/build.prop
overlay_partition /odm/build.prop "$MODPATH/system/odm" "odm."

# /system_ext/build.prop
overlay_partition /system_ext/build.prop "$MODPATH/system/system_ext" "system_ext."

# 也尝试 /system/vendor 等路径（部分设备使用此布局）
if [ ! -f /vendor/build.prop ] && [ -f /system/vendor/build.prop ]; then
    overlay_partition /system/vendor/build.prop "$MODPATH/system/vendor" "vendor."
fi
if [ ! -f /product/build.prop ] && [ -f /system/product/build.prop ]; then
    overlay_partition /system/product/build.prop "$MODPATH/system/product" "product."
fi
if [ ! -f /odm/build.prop ] && [ -f /system/odm/build.prop ]; then
    overlay_partition /system/odm/build.prop "$MODPATH/system/odm" "odm."
fi

# ============================================
# HyperOS 3 版本号检测与修改
# ============================================

MIUI_VER=$(getprop ro.miui.ui.version.name)
DISPLAY_ID=$(getprop ro.build.display.id)
MI_OS_INC=$(getprop ro.mi.os.version.incremental)
BUILD_INC=$(getprop ro.build.version.incremental)
TARGET_DISPLAY_ID="OS3.0.45.0.WPBCNXM"

is_hyperos3="false"
case "$MIUI_VER" in V170*) is_hyperos3="true" ;; esac
case "$DISPLAY_ID" in OS3*|3.*) is_hyperos3="true" ;; esac
case "$MI_OS_INC" in OS3*|3.*) is_hyperos3="true" ;; esac
case "$BUILD_INC" in OS3*|3.*) is_hyperos3="true" ;; esac

if [ "$is_hyperos3" = "true" ]; then
    ui_print ""
    ui_print "- 检测到 HyperOS 3，修改版本号为 $TARGET_DISPLAY_ID"

    # 将版本号写入所有已覆盖的 build.prop
    for bp in \
        "$MODPATH/system/build.prop" \
        "$MODPATH/system/vendor/build.prop" \
        "$MODPATH/system/product/build.prop" \
        "$MODPATH/system/odm/build.prop" \
        "$MODPATH/system/system_ext/build.prop"
    do
        if [ -f "$bp" ]; then
            patch_prop "$bp" "ro.build.display.id" "$TARGET_DISPLAY_ID"
            patch_prop "$bp" "ro.build.version.incremental" "$TARGET_DISPLAY_ID"
            patch_prop "$bp" "ro.mi.os.version.incremental" "$TARGET_DISPLAY_ID"
            patch_prop "$bp" "ro.mi.os.version.name" "OS3.0"
            patch_prop "$bp" "ro.mi.os.version.code" "17"
        fi
    done

    # 记录标记供 post-fs-data.sh 使用
    echo "true" > "$MODPATH/is_hyperos3"
    ui_print "  版本号已写入所有 build.prop"
fi

# ============================================
# 恢复用户配置
# ============================================

if [ "$ADB_ROOT_WAS_ON" = "true" ]; then
    echo "1" > "$MODPATH/adb_root_enabled"
    ui_print "- 已恢复 ADB Root 配置"
fi

# ============================================
# 设置权限
# ============================================

ui_print ""
ui_print "- 设置文件权限..."
set_perm_recursive $MODPATH 0 0 0755 0644

# build.prop 必须与原始权限一致
for bp in $(find "$MODPATH/system" -name "build.prop" 2>/dev/null); do
    set_perm "$bp" 0 0 0644
done

set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755

# 统计
OVERLAY_COUNT=$(find "$MODPATH/system" -name "build.prop" 2>/dev/null | wc -l)
ui_print "- OverlayFS 覆盖文件: ${OVERLAY_COUNT} 个 build.prop"
ui_print ""
ui_print "- 安装完成！重启后生效。"
ui_print "- 如需恢复，请在 ${ROOT_SOLUTION} 中卸载本模块后重启。"
ui_print ""
