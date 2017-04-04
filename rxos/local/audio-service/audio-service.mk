################################################################################
#
# audio_service
#
################################################################################

AUDIO_SERVICE_VERSION = 0.1
AUDIO_SERVICE_SITE = $(BR2_EXTERNAL)/local/audio-service/src
AUDIO_SERVICE_SITE_METHOD = local


define AUDIO_SERVICE_INSTALL_TARGET_CMDS
endef

define AUDIO_SERVICE_INSTALL_INIT_SYSV
	$(INSTALL) -Dm0755 $(@D)/S99audio $(TARGET_DIR)/etc/init.d/S99audio
endef

$(eval $(generic-package))
