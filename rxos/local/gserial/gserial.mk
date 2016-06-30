################################################################################
#
# gserial
#
################################################################################

GSERIAL_VERSION = 1.0
GSERIAL_LICENSE = GPLv3+
GSERIAL_SITE = $(BR2_EXTERNAL)/local/gserial/src
GSERIAL_SITE_METHOD = local

define GSERIAL_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/gserial.sh \
		$(TARGET_DIR)/etc/setup.d/gserial.sh
endef

$(eval $(generic-package))
