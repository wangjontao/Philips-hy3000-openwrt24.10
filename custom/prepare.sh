#!/bin/bash
set -euo pipefail
mkdir -p work-sources
printf '%s\n' 'src-git istore https://github.com/linkease/istore.git;main' 'src-git nas_packages https://github.com/linkease/nas-packages.git;master' 'src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main' >> feeds.conf.default
./scripts/feeds update -a
# Exclude the optional speed-test package family whose Kconfig is recursive.
rm -rf feeds/nas_packages/utils/librespeed-cli feeds/nas_packages/utils/librespeed-cli-rust feeds/nas_packages/utils/librespeed-common
rm -rf package/feeds/nas_packages/librespeed-cli package/feeds/nas_packages/librespeed-cli-rust package/feeds/nas_packages/librespeed-common
rm -rf tmp
./scripts/feeds install -a
./scripts/feeds install -d y -p istore luci-app-store
./scripts/feeds install -d y -p nas_packages quickstart
./scripts/feeds install -d y -p nas_luci luci-app-quickstart
git clone --filter=blob:none --no-checkout https://github.com/Openwrt-Passwall/openwrt-passwall.git work-sources/pw
git -C work-sources/pw checkout --detach 6c45f659251fd91ac0e414db94710288ab9cda61
echo 'Openwrt-Passwall/openwrt-passwall 6c45f659251fd91ac0e414db94710288ab9cda61' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/Openwrt-Passwall/openwrt-passwall2.git work-sources/pw2
git -C work-sources/pw2 checkout --detach c613dc317bec3e3bf6ac920177fbe1e69495d1c8
echo 'Openwrt-Passwall/openwrt-passwall2 c613dc317bec3e3bf6ac920177fbe1e69495d1c8' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git work-sources/proxy
git -C work-sources/proxy checkout --detach 3e11c458c552aefd348232c627fd1ed9f8f08e41
echo 'Openwrt-Passwall/openwrt-passwall-packages 3e11c458c552aefd348232c627fd1ed9f8f08e41' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/immortalwrt/homeproxy.git work-sources/homeproxy
git -C work-sources/homeproxy checkout --detach edece28a0085f36d469ec82c8d45f562f602db53
echo 'immortalwrt/homeproxy edece28a0085f36d469ec82c8d45f562f602db53' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/vernesong/OpenClash.git work-sources/clash
git -C work-sources/clash checkout --detach c3a33c1d3407956fdf8f0e0b7c1a4c52e6ad9593
echo 'vernesong/OpenClash c3a33c1d3407956fdf8f0e0b7c1a4c52e6ad9593' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/jerrykuku/luci-theme-argon.git work-sources/argon
git -C work-sources/argon checkout --detach ddefe5f05ca334dba10d2d65d25ebf14e986ee88
echo 'jerrykuku/luci-theme-argon ddefe5f05ca334dba10d2d65d25ebf14e986ee88' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/coolsnowwolf/luci.git work-sources/lean
git -C work-sources/lean checkout --detach 3af75fcd74bac12e771e788ea41994f9b57e20cd
echo 'coolsnowwolf/luci 3af75fcd74bac12e771e788ea41994f9b57e20cd' >> source-lock.txt
git clone --filter=blob:none --no-checkout https://github.com/djylb/nps-openwrt.git work-sources/nps
git -C work-sources/nps checkout --detach 480f2e502575641a0c9280d6fad971550621316d
echo 'djylb/nps-openwrt 480f2e502575641a0c9280d6fad971550621316d' >> source-lock.txt

for name in luci-app-passwall luci-app-passwall2 luci-app-homeproxy luci-app-openclash luci-theme-argon luci-app-nps npc; do
  find package/feeds -type l -name "$name" -delete
  find feeds -type d -name "$name" -prune -exec rm -rf {} +
done
cp -a work-sources/pw/luci-app-passwall package/
cp -a work-sources/pw2/luci-app-passwall2 package/
cp -a work-sources/homeproxy package/luci-app-homeproxy
cp -a work-sources/clash/luci-app-openclash package/
cp -a work-sources/argon package/luci-theme-argon
sed -i -E 's/\+wget(-ssl)?/\+wget/g; s/\+wget-any/\+wget/g' package/luci-theme-argon/Makefile
cp -a work-sources/lean/applications/luci-app-nps package/
cp -a work-sources/nps/npc package/
sed -i 's#include ../../luci.mk#include $(TOPDIR)/feeds/luci/luci.mk#' package/luci-app-nps/Makefile
for d in work-sources/proxy/*; do
  [ -f "$d/Makefile" ] || continue
  name="$(basename "$d")"
  find package/feeds -type l -name "$name" -delete
  find feeds -type d -name "$name" -prune -exec rm -rf {} +
  cp -a "$d" "package/$name"
done
grep -qx 'PKG_VERSION:=26.3.6' package/luci-app-passwall/Makefile
grep -qx 'PKG_RELEASE:=1' package/luci-app-passwall/Makefile
grep -qx 'PKG_VERSION:=26.3.5' package/luci-app-passwall2/Makefile
grep -qx 'PKG_RELEASE:=1' package/luci-app-passwall2/Makefile
curl -fL --retry 3 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o work-sources/clash-core.tar.gz
mkdir -p work-sources/clash-core
tar -xzf work-sources/clash-core.tar.gz -C work-sources/clash-core
install -Dm755 work-sources/clash-core/clash files/etc/openclash/core/clash_meta
sha256sum files/etc/openclash/core/clash_meta >> source-lock.txt
cp -a custom/files/. files/
chmod 0755 files/etc/uci-defaults/99-dulwifi files/etc/init.d/dulwifi-firstboot files/usr/libexec/dulwifi-firstboot
ROOT_HASH="$(openssl passwd -6 password)"
sed -i "s#^root:[^:]*:#root:$ROOT_HASH:#" package/base-files/files/etc/shadow
cat > .config <<'CONFIG'
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_philips_hy3000=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-app-quickstart=y
CONFIG_PACKAGE_quickstart=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-nps=y
CONFIG_PACKAGE_npc=y
CONFIG_PACKAGE_dnsmasq-full=y
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=n
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client=n
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
CONFIG_PACKAGE_sing-box=y
CONFIG_PACKAGE_xray-core=y
CONFIG
make defconfig 2>&1 | tee config-resolve.log
! grep -q 'recursive dependency detected' config-resolve.log
./scripts/diffconfig.sh > hy3000.config
for pkg in luci-app-store luci-app-quickstart quickstart luci-app-ttyd luci-theme-argon luci-app-passwall luci-app-passwall2 luci-app-homeproxy luci-app-openclash luci-app-nps npc kmod-mt7915e sing-box xray-core; do
  grep -qx "CONFIG_PACKAGE_$pkg=y" .config || { echo "Required package dropped: $pkg"; exit 1; }
done
grep -qx 'CONFIG_TARGET_mediatek_filogic_DEVICE_philips_hy3000=y' .config
./scripts/diffconfig.sh > hy3000.config
