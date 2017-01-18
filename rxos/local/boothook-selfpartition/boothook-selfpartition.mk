################################################################################
#
# selfpartition
#
################################################################################

BOOTHOOK_SELFPARTITION_VERSION = 1.4
BOOTHOOK_SELFPARTITION_LICENSE = GPLv3+
BOOTHOOK_SELFPARTITION_SITE = $(BR2_EXTERNAL)/local/boothook-selfpartition/src
BOOTHOOK_SELFPARTITION_SITE_METHOD = local

BOOTHOOK_SELFPARTITION_LIBC_VER = $(call qstrip,$(BR2_GLIBC_VERSION_STRING))
BOOTHOOK_SELFPARTITION_CPIO_SED_CMDS = s|%PREFIX%|$(TARGET_DIR)|g;
BOOTHOOK_SELFPARTITION_CPIO_SED_CMDS += s|%BINDIR%|$(BINARIES_DIR)|g;
BOOTHOOK_SELFPARTITION_CPIO_SED_CMDS += s|%LIBC_VER%|$(BOOTHOOK_SELFPARTITION_LIBC_VER)|g;

BOOTHOOK_SELFPARTITION_HOOK_SED_CMDS = s|%CONF%|$(call qstrip,$(BR2_BOOTHOOK_SELFPARTITION_CONFIG_SIZE))|g;
BOOTHOOK_SELFPARTITION_HOOK_SED_CMDS += s|%CACHE%|$(call qstrip,$(BR2_BOOTHOOK_SELFPARTITION_CACHE_SIZE))|g;
BOOTHOOK_SELFPARTITION_HOOK_SED_CMDS += s|%APPDATA%|$(call qstrip,$(BR2_BOOTHOOK_SELFPARTITION_APPDATA_SIZE))|g;

BOOTHOOK_SELFPARTITION_FSTABL_SED_CMDS += s|%PRIMARY%|$(call qstrip,$(BR2_STORAGE_PRIMARY))|g;

BOOTHOOK_SELFPARTITION_STORAGE = $(call qstrip,$(BR2_RAMFSINIT_INIT_TYPE))

BOOTHOOK_SELFPARTITION_MPOINTS = conf,external,downloads

ifeq ($(BOOTHOOK_SELFPARTITION_STORAGE),nand)

define BOOTHOOK_SELFPARTITION_INSTALL_TARGET_CMDS
	$(SED) '$(BOOTHOOK_SELFPARTITION_FSTABL_SED_CMDS)' \
		$(@D)/fstab.nand
	$(INSTALL) -Dm644 $(@D)/fstab.nand $(TARGET_DIR)/etc/fstab
	$(INSTALL) -dm755 $(TARGET_DIR)/mnt/{$(BOOTHOOK_SELFPARTITION_MPOINTS)}
	$(INSTALL) -Dm755 $(@D)/attachswap.sh \
		$(TARGET_DIR)/etc/setup.d/attachswap.sh
	$(INSTALL) -Dm755 $(@D)/attachcache.sh \
		$(TARGET_DIR)/etc/setup.d/attachcache.sh
	$(INSTALL) -Dm755 $(@D)/attachappdata.sh \
		$(TARGET_DIR)/etc/setup.d/attachappdata.sh
endef

else

ifeq ($(BR2_PACKAGE_BOOTHOOK_SELFPARTITION),y)
INIT_CPIO_LISTS += selfpartition.cpio.in
endif

define BOOTHOOK_SELFPARTITION_INSTALL_TARGET_CMDS
	$(SED) '$(BOOTHOOK_SELFPARTITION_HOOK_SED_CMDS)' \
		$(@D)/partition-hook.sdcard.sh
	$(SED) '$(BOOTHOOK_SELFPARTITION_CPIO_SED_CMDS)' \
		$(@D)/init.sdcard.cpio.in
	$(SED) '$(BOOTHOOK_SELFPARTITION_FSTABL_SED_CMDS)' \
		$(@D)/fstab.sdcard

	$(INSTALL) -Dm644 $(@D)/partition-hook.sdcard.sh \
		$(BINARIES_DIR)/initramfs/partition-hook.sh
	$(INSTALL) -Dm644 $(@D)/init.sdcard.cpio.in \
		$(BINARIES_DIR)/initramfs/selfpartition.cpio.in
	$(INSTALL) -Dm644 $(@D)/fstab.sdcard $(TARGET_DIR)/etc/fstab

	$(INSTALL) -dm755 $(TARGET_DIR)/mnt/{$(BOOTHOOK_SELFPARTITION_MPOINTS)}
	$(INSTALL) -Dm755 $(@D)/attachcache.sh \
		$(TARGET_DIR)/etc/setup.d/attachcache.sh
	$(INSTALL) -Dm755 $(@D)/attachappdata.sh \
		$(TARGET_DIR)/etc/setup.d/attachappdata.sh
endef

endif # BOOTHOOK_SELFPARTITION_STORAGE == nand

$(eval $(generic-package))
