################################################################################
#
# led-control
#
################################################################################

LED_CONTROL_VERSION = 1.0
LED_CONTROL_LICENSE = GPLv3+
LED_CONTROL_SITE = $(BR2_EXTERNAL)/local/led-control/src
LED_CONTROL_SITE_METHOD = local

LED_CONTROL_SED_CMDS += s|%LED_NUM%|$(BR2_LED_DEVNUM)|;
LED_CONTROL_SED_CMDS += s|%LED_BUS%|$(BR2_LED_BUS)|;
LED_CONTROL_SED_CMDS += s|%LED_CHIP%|$(BR2_LED_CHIP)|;
LED_CONTROL_SED_CMDS += s|%LED_ADDR%|$(BR2_LED_ADDR)|;

LED_CONTROL_SCRIPT_NAME = led_ctrl-$(call qstrip,$(BR2_LED_CONTROL_METHOD)).sh

ifeq ($(BR2_LED_CONTROL_METHOD),"i2c")
define LED_CONTROL_INSTALL_BLINK_SCRIPT_CMDS
$(INSTALL) -Dm755 $(@D)/led_blink-i2c.sh $(TARGET_DIR)/usr/bin/blink
endef
endif

define LED_CONTROL_INSTALL_TARGET_CMDS
	$(SED) '$(LED_CONTROL_SED_CMDS)' $(@D)/$(LED_CONTROL_SCRIPT_NAME)
	$(INSTALL) -Dm644 $(@D)/$(LED_CONTROL_SCRIPT_NAME) \
		$(TARGET_DIR)/usr/lib/led_ctrl.sh
	$(LED_CONTROL_INSTALL_BLINK_SCRIPT_CMDS)
endef

define LED_CONTROL_INSTALL_INIT_SYSV
	$(INSTALL) -Dm755 $(BR2_EXTERNAL)/local/led-control/S99led \
		$(TARGET_DIR)/etc/init.d/S99led
endef

$(eval $(generic-package))
