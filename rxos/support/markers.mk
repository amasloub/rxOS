# Add platform, version, and build markers

RXOS_BUILD=$(shell git rev-parse --short HEAD)
RXOS_TIMESTAMP=$(shell date --rfc-822)

define GENERATE_MARKERS
	@$(call MESSAGE,"Adding release markers")
	echo $(RXOS_PLATFORM) > $(TARGET_DIR)/etc/platform
	echo $(RXOS_VERSION) > $(TARGET_DIR)/etc/version
	echo $(RXOS_BUILD) @ $(RXOS_TIMESTAMP) > $(TARGET_DIR)/etc/build-info
endef

TARGET_FINALIZE_HOOKS += GENERATE_MARKERS
