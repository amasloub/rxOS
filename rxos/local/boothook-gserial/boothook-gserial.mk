################################################################################
#
# boothook-gserial
#
################################################################################

BOOTHOOK_GSERIAL_VERSION = 1.0
BOOTHOOK_GSERIAL_LICENSE = GPLv3+
BOOTHOOK_GSERIAL_SITE = $(BR2_EXTERNAL)/local/boothook-gserial/src
BOOTHOOK_GSERIAL_SITE_METHOD = local

ifeq ($(BR2_PACKAGE_BOOTHOOK_GSERIAL),y)
INIT_CPIO_LISTS += gserial.cpio.in
endif

BOOTHOOK_GSERIAL_KERNELVERSION = $(shell make -s -C $(LINUX_DIR) kernelversion)
BOOTHOOK_GSERIAL_CPIO_SED_CMDS = s|%PREFIX%|$(TARGET_DIR)|g;
BOOTHOOK_GSERIAL_CPIO_SED_CMDS += s|%BINDIR%|$(BINARIES_DIR)|g;
BOOTHOOK_GSERIAL_CPIO_SED_CMDS += s|%KVER%|$(BOOTHOOK_GSERIAL_KERNELVERSION)|g;

define BOOTHOOK_GSERIAL_INSTALL_TARGET_CMDS
	$(SED) '$(BOOTHOOK_GSERIAL_CPIO_SED_CMDS)' $(@D)/init.gserial.cpio.in
	$(INSTALL) -Dm644 $(@D)/init.gserial.cpio.in \
		$(BINARIES_DIR)/initramfs/gserial.cpio.in
	$(INSTALL) -Dm644 $(@D)/gserial-hook.sh \
		$(BINARIES_DIR)/initramfs/gserial-hook.sh
	$(INSTALL) -Dm644 $(@D)/modules.dep \
		$(BINARIES_DIR)/initramfs/modules.dep
endef

$(eval $(generic-package))
