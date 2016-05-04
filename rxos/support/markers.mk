# Add platform, version, and build markers

RXOS_BUILD = $(shell git rev-parse --short HEAD)
RXOS_TIMESTAMP = $(shell date -u --rfc-3339=seconds)
RELEASE_FILE = $(TARGET_DIR)/etc/platform-release

define GENERATE_MARKERS
	@$(call MESSAGE,"Adding release markers")
	echo 'RXOS_PLATFORM=$(RXOS_PLATFORM)' > $(RELEASE_FILE)
	echo 'RXOS_VERSION=$(RXOS_VERSION)' >> $(RELEASE_FILE)
	echo 'RXOS_BUILD="$(RXOS_BUILD)"' >> $(RELEASE_FILE)
	echo 'RXOS_TIMESTAMP="$(RXOS_TIMESTAMP)"' >> $(RELEASE_FILE)
endef

TARGET_FINALIZE_HOOKS += GENERATE_MARKERS
