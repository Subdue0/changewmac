include $(TOPDIR)/rules.mk

PKG_NAME:=changewmac
PKG_RELEASE:=1.0
PKG_MAINTAINER:=Subdue<1374700812@qq.com>
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Modify wireless mac
	DEPENDS:=+kmod-mtd-rw
endef

define Package/$(PKG_NAME)/description
	This package contains a shell script, the script can modify wireless mac.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) -R ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/storage/mac
	$(INSTALL_DIR) $(1)/etc/crontabs
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/etc/crontabs/root $(1)/etc/crontabs/root
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/etc/storage/mac/changewmac.sh $(1)/etc/storage/mac/changewmac.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
