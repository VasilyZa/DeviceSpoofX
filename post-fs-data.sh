#!/system/bin/sh
# ============================================
# DeviceSpoofX (OverlayFS)
# post-fs-data.sh - OverlayFS 补漏
# 仅处理 build.prop 覆盖无法生效的属性
# ============================================

MODDIR=${0%/*}

TARGET_MARKETNAME="Xiaomi 17 Pro Max"
TARGET_DISPLAY_ID="OS3.0.45.0.WPBCNXM"

# ============================================
# resetprop 自动寻址
# ============================================

find_resetprop() {
    if command -v resetprop >/dev/null 2>&1; then
        echo "resetprop"; return
    fi
    if command -v magisk >/dev/null 2>&1; then
        echo "magisk resetprop"; return
    fi
    for bin in \
        /data/adb/magisk/magisk64 \
        /data/adb/magisk/magisk32 \
        /data/adb/ksu/bin/resetprop \
        /data/adb/ap/bin/resetprop; do
        if [ -f "$bin" ]; then
            echo "$bin"; return
        fi
    done
    echo ""
}

RESETPROP_BIN=$(find_resetprop)
[ -z "$RESETPROP_BIN" ] && exit 0

# ============================================
# 补漏: build.prop 中可能不存在的属性
# OverlayFS 只能修改文件中已有的行
# 不在 build.prop 中的属性需要 resetprop 注入
# ============================================

# 营销名称 (部分机型 build.prop 中无此属性)
$RESETPROP_BIN -n ro.product.marketname "$TARGET_MARKETNAME"
$RESETPROP_BIN -n ro.product.odm.marketname "$TARGET_MARKETNAME"
$RESETPROP_BIN -n ro.product.vendor.marketname "$TARGET_MARKETNAME"
$RESETPROP_BIN -n ro.product.system.marketname "$TARGET_MARKETNAME"

# HyperOS 3 补漏 (仅在安装时检测到 HyperOS 3 时执行)
if [ -f "$MODDIR/is_hyperos3" ]; then
    $RESETPROP_BIN -n ro.mi.os.version.incremental "$TARGET_DISPLAY_ID"
    $RESETPROP_BIN -n ro.mi.os.version.name "OS3.0"
    $RESETPROP_BIN -n ro.mi.os.version.code "17"
    $RESETPROP_BIN -n ro.build.display.id "$TARGET_DISPLAY_ID"
fi

# ============================================
# ADB Root 调试 (WebUI 开关控制)
# 在非 userdebug 构建上启用 adb root
# ============================================

if [ -f "$MODDIR/adb_root_enabled" ]; then
    # 必须先 delete 再设置，否则 ro.* 只读区可能无法覆盖
    $RESETPROP_BIN --delete ro.debuggable 2>/dev/null
    $RESETPROP_BIN ro.debuggable 1
    $RESETPROP_BIN --delete ro.secure 2>/dev/null
    $RESETPROP_BIN ro.secure 0
    $RESETPROP_BIN --delete ro.adb.secure 2>/dev/null
    $RESETPROP_BIN ro.adb.secure 0
    $RESETPROP_BIN --delete ro.build.type 2>/dev/null
    $RESETPROP_BIN ro.build.type userdebug
fi
