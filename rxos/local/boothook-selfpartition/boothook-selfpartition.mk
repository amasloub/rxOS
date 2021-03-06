################################################################################
#
# selfpartition
#
################################################################################

BOOTHOOK_SELFPARTITION_VERSION = 1.5
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

define BOOTHOOK_SELFPARTITION_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm644 $(@D)/fstab $(TARGET_DIR)/etc/fstab
	$(INSTALL) -dm755 $(TARGET_DIR)/mnt/{$(BOOTHOOK_SELFPARTITION_MPOINTS)}
	$(INSTALL) -Dm755 $(@D)/attachswap.sh \
		$(TARGET_DIR)/etc/setup.d/attachswap.sh
	$(INSTALL) -Dm755 $(@D)/attachcache.sh \
		$(TARGET_DIR)/etc/setup.d/attachcache.sh
	$(INSTALL) -Dm755 $(@D)/attachappdata.sh \
		$(TARGET_DIR)/etc/setup.d/attachappdata.sh
	$(INSTALL) -Dm755 $(@D)/chown_downloads.sh \
		$(TARGET_DIR)/etc/setup.d/chown_downloads.sh
endef

$(eval $(generic-package))
