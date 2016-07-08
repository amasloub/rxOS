define INSTALL_OTA_KEY
$(INSTALL) -Dm644 $(BR2_EXTERNAL)/configs/package.pem \
	$(BINARIES_DIR)/signature.pem
endef

TARGET_FINALIZE_HOOKS += INSTALL_OTA_KEY
