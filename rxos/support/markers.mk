# Add platform, version, and build markers
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

RXOS_BUILD = $(shell cd $(BR2_EXTERNAL); git rev-parse --short HEAD)
RXOS_TIMESTAMP = $(shell date -u --rfc-3339=seconds)
RELEASE_FILE = $(TARGET_DIR)/etc/platform-release

define GENERATE_MARKERS
	@$(call MESSAGE,"Adding release markers")
	echo 'RXOS_PLATFORM=$(RXOS_PLATFORM)' > $(RELEASE_FILE)
	echo 'RXOS_SUBPLATFORM=$(RXOS_SUBPLATFORM)' > $(RELEASE_FILE)
	echo 'RXOS_VERSION=$(RXOS_VERSION)' >> $(RELEASE_FILE)
	echo 'RXOS_BUILD="$(RXOS_BUILD)"' >> $(RELEASE_FILE)
	echo 'RXOS_TIMESTAMP="$(RXOS_TIMESTAMP)"' >> $(RELEASE_FILE)
	echo '$(call qstrip,$(RXOS_VERSION))' > $(TARGET_DIR)/etc/version
	echo '$(call qstrip,$(RXOS_PLATFORM))' > $(TARGET_DIR)/etc/platform
	echo '$(call qstrip,$(RXOS_SUBPLATFORM))' > $(TARGET_DIR)/etc/subplatform
endef

TARGET_FINALIZE_HOOKS += GENERATE_MARKERS
