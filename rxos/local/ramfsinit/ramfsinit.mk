################################################################################
#
# ramfsinit
#
################################################################################

RAMFSINIT_VERSION = 1.0
RAMFSINIT_LICENSE = GPLv3+
RAMFSINIT_SITE = $(BR2_EXTERNAL)/local/ramfsinit/src
RAMFSINIT_SITE_METHOD = local

INIT_CPIO_LISTS += default.cpio.in

# Define the package

RAMFSINIT_LIBC_VER = $(call qstrip,$(BR2_GLIBC_VERSION_STRING))
RAMFSINIT_CPIO_SED_CMDS = s|%PREFIX%|$(TARGET_DIR)|g;
RAMFSINIT_CPIO_SED_CMDS += s|%BINDIR%|$(BINARIES_DIR)|g;
RAMFSINIT_CPIO_SED_CMDS += s|%LIBC_VER%|$(RAMFSINIT_LIBC_VER)|g;

RAMFSINIT_TMPFS_SIZE = $(call qstrip,$(RXOS_TMPFS_SIZE))
RAMFSINIT_VERSION = $(call qstrip,$(RXOS_VERSION))
RAMFSINIT_INIT_SED_CMDS = s|%TMPFS_SIZE%|$(RAMFSINIT_TMPFS_SIZE)|g;
RAMFSINIT_INIT_SED_CMDS += s|%VERSION%|$(RAMFSINIT_VERSION)|g;

define RAMFSINIT_BUILD_CMDS
	$(HOSTCC) -o $(@D)/gen_init_cpio -O3 $(@D)/gen_init_cpio.c
endef

define RAMFSINIT_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/gen_init_cpio $(HOST_DIR)/usr/bin/gen_init_cpio
	$(INSTALL) -Dm644 $(@D)/init.cpio.in \
		$(BINARIES_DIR)/initramfs/default.cpio.in
	sed -i '$(RAMFSINIT_CPIO_SED_CMDS)' \
		$(BINARIES_DIR)/initramfs/default.cpio.in
	$(INSTALL) -Dm644 $(@D)/init.$(call qstrip,$(BR2_RAMFSINIT_INIT_TYPE)).in.sh \
		$(BINARIES_DIR)/initramfs/init
	sed -i '$(RAMFSINIT_INIT_SED_CMDS)' $(BINARIES_DIR)/initramfs/init
endef

$(eval $(generic-package))

# Add various build hooks

define COLLECT_CPIO_LISTS
	@$(call MESSAGE,"Generating composite cpio list")
	cat $(foreach cpio,$(INIT_CPIO_LISTS),$(BINARIES_DIR)/initramfs/$(cpio)) \
		> $(BINARIES_DIR)/initramfs/init.cpio
	$(RAMFSINIT_SITE)/dedupe_cpio.py $(BINARIES_DIR)/initramfs/init.cpio
endef

TARGET_FINALIZE_HOOKS += COLLECT_CPIO_LISTS
BR2_ROOTFS_POST_BUILD_SCRIPT += $(RAMFSINIT_SITE)/mkcpio.sh

# Add a target to print the cpio lists

.PHONY: print-ramfsinit-lists

print-cpio-lists:
	@echo $(INIT_CPIO_LISTS)
