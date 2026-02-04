# 1. 创建固件目录
mkdir -p /lib/firmware/mediatek

# 2. 将 factory 分区完整内容复制为驱动需要的文件名
dd if=/dev/mmcblk0p3 of=/lib/firmware/mediatek/mt7981_eeprom_mt7976_dbdc.bin bs=1M count=2

# 3. 验证文件存在
ls -lh /lib/firmware/mediatek/mt7981_eeprom_mt7976_dbdc.bin

# 4. 重新加载驱动（需通过串口操作，否则 SSH 会断）
# 如果只能 SSH，重启设备：
reboot