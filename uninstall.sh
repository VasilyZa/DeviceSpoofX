#!/system/bin/sh
# ============================================
# DeviceSpoofX
# uninstall.sh - 卸载清理脚本
# ============================================

MODDIR=${0%/*}

# 清除持久化属性
resetprop --delete persist.sys.device_name 2>/dev/null

# 恢复 ADB 调试属性 (重启后自动恢复，此处提前清理)
resetprop ro.debuggable 0 2>/dev/null
resetprop ro.secure 1 2>/dev/null
resetprop ro.adb.secure 1 2>/dev/null
resetprop ro.build.type user 2>/dev/null
resetprop service.adb.root 0 2>/dev/null

# 强制删除所有模块文件
rm -rf "$MODDIR/webroot" 2>/dev/null
rm -rf "$MODDIR/system" 2>/dev/null
rm -f "$MODDIR/adb_root_enabled" 2>/dev/null
rm -f "$MODDIR/is_hyperos3" 2>/dev/null
rm -f "$MODDIR/post-fs-data.sh" 2>/dev/null
rm -f "$MODDIR/service.sh" 2>/dev/null
rm -f "$MODDIR/customize.sh" 2>/dev/null
rm -f "$MODDIR/module.prop" 2>/dev/null

# 注意: ro.* 属性会在重启后自动恢复为原始值
# Settings 数据库中的设备名称需要用户手动修改
# 路径: 设置 > 关于手机 > 设备名称
