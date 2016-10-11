################################################################################
#
# weathergen
#
################################################################################

WEATHERGEN_VERSION = 1.0
WEATHERGEN_LICENSE = GPLv3+
WEATHERGEN_SITE = $(BR2_EXTERNAL)/local/weathergen/src
WEATHERGEN_SITE_METHOD = local

WEATHERGEN_SED_CMDS += s|%GRIBSOURCE%|$(call qstrip,$(BR2_WEATHERGEN_SOURCE))|;
WEATHERGEN_SED_CMDS += s|%JSONDESTINATION%|$(call qstrip,$(BR2_WEATHERGEN_JSON_DESTINATION))|;
WEATHERGEN_SED_CMDS += s|%GRIBDESTINATION%|$(call qstrip,$(BR2_WEATHERGEN_GRIB_DESTINATION))|;


define WEATHERGEN_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/grib2json $(TARGET_DIR)/usr/bin/grib2json
	$(SED) '$(WEATHERGEN_SED_CMDS)' $(TARGET_DIR)/usr/bin/grib2json
	$(INSTALL) -Dm0644 $(@D)/weather.incron $(TARGET_DIR)$(call qstrip,$(BR2_INCRON_SERVICE_CONFDIR))/weather.incron
	$(SED) '$(WEATHERGEN_SED_CMDS)' $(TARGET_DIR)$(call qstrip,$(BR2_INCRON_SERVICE_CONFDIR))/weather.incron
endef

$(eval $(generic-package))
