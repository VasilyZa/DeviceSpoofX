#!/system/bin/sh
# ============================================
# Xiaomi 17 Pro Max Device Spoofer
# uninstall.sh - 卸载清理脚本
# ============================================

# 清除持久化属性
resetprop --delete persist.sys.device_name 2>/dev/null

# 恢复 ADB 调试属性 (重启后自动恢复，此处提前清理)
resetprop ro.debuggable 0 2>/dev/null
resetprop ro.secure 1 2>/dev/null
resetprop ro.adb.secure 1 2>/dev/null
resetprop service.adb.root 0 2>/dev/null

# 注意: ro.* 属性会在重启后自动恢复为原始值
# Settings 数据库中的设备名称需要用户手动修改
# 路径: 设置 > 关于手机 > 设备名称
