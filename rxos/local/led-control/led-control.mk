################################################################################
#
# led-control
#
################################################################################

LED_CONTROL_VERSION = 1.0
LED_CONTROL_LICENSE = GPLv3+
LED_CONTROL_SITE = $(BR2_EXTERNAL)/local/led-control/src
LED_CONTROL_SITE_METHOD = local

LED_CONTROL_SED_CMDS = s|%LED_NUM%|$(call qstrip,$(BR2_LED_DEVNUM))|

define LED_CONTROL_INSTALL_TARGET_CMDS
	$(SED) '$(LED_CONTROL_SED_CMDS)' $(@D)/led_ctrl.sh
	$(INSTALL) -Dm644 $(@D)/led_ctrl.sh $(TARGET_DIR)/usr/lib/led_ctrl.sh
endef

define LED_CONTROL_INSTALL_INIT_SYSV
	$(INSTALL) -Dm755 $(BR2_EXTERNAL)/local/led-control/S99led \
		$(TARGET_DIR)/etc/init.d/S99led
endef

$(eval $(generic-package))
