#!/system/bin/sh
# ============================================
# Xiaomi 17 Pro Max Device Spoofer
# service.sh - 启动完成后执行
# 修改 Settings 数据库及持久化属性
# 支持 Magisk / KernelSU / APatch
# ============================================

MODDIR=${0%/*}

TARGET_MARKETNAME="Xiaomi 17 Pro Max"

# ============================================
# resetprop 自动寻址（兼容三大 Root 方案）
# ============================================

find_resetprop() {
    if command -v resetprop >/dev/null 2>&1; then
        echo "resetprop"
        return
    fi
    if command -v magisk >/dev/null 2>&1; then
        echo "magisk resetprop"
        return
    fi
    if [ -f /data/adb/magisk/magisk64 ]; then
        echo "/data/adb/magisk/magisk64 resetprop"
        return
    fi
    if [ -f /data/adb/magisk/magisk32 ]; then
        echo "/data/adb/magisk/magisk32 resetprop"
        return
    fi
    if [ -f /data/adb/ksu/bin/resetprop ]; then
        echo "/data/adb/ksu/bin/resetprop"
        return
    fi
    if [ -f /data/adb/ap/bin/resetprop ]; then
        echo "/data/adb/ap/bin/resetprop"
        return
    fi
    echo ""
}

RESETPROP_BIN=$(find_resetprop)

# 等待系统启动完成
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

# 额外等待，确保 Settings Provider 服务就绪
sleep 3

# ============================================
# 修改 Settings 数据库中的设备名称
# ============================================

# 全局设备名称（设置 > 关于手机 > 设备名称）
settings put global device_name "$TARGET_MARKETNAME"

# 持久化设备名称属性
if [ -n "$RESETPROP_BIN" ]; then
    $RESETPROP_BIN persist.sys.device_name "$TARGET_MARKETNAME"
    # 网络主机名
    $RESETPROP_BIN net.hostname "Xiaomi-17-Pro-Max"
else
    # 回退: 使用 setprop（service 阶段可用，但无法修改 ro.* 属性）
    setprop persist.sys.device_name "$TARGET_MARKETNAME"
    setprop net.hostname "Xiaomi-17-Pro-Max"
fi

# ============================================
# 修改蓝牙及网络显示名称
# ============================================

# 蓝牙名称
settings put secure bluetooth_name "$TARGET_MARKETNAME"

# WIFI Direct 设备名称
settings put global wifi_p2p_device_name "$TARGET_MARKETNAME"

# ============================================
# ADB Root 调试 (WebUI 开关控制)
# ============================================

if [ -f "$MODDIR/adb_root_enabled" ] && [ -n "$RESETPROP_BIN" ]; then
    # 补充设置 (post-fs-data 可能未覆盖到的)
    $RESETPROP_BIN ro.debuggable 1
    $RESETPROP_BIN ro.secure 0
    $RESETPROP_BIN ro.adb.secure 0
    $RESETPROP_BIN service.adb.root 1
    setprop ctl.restart adbd
fi
