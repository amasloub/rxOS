# Pass build hook arguments

ifeq ($(BR2_CPIO_COMPRESSION),"")
CPIO_COMPRESSION=none
else
CPIO_COMPRESSION=$(BR2_CPIO_COMPRESSION)
endif

BR2_ROOTFS_POST_SCRIPT_ARGS = $(RXOS_PLATFORM) \
							  $(RXOS_VERSION) \
							  $(BR2_LINUX_KERNEL_VERSION) \
							  $(CPIO_COMPRESSION) \
							  $(BR2_CPIO_COMPRESSED_FILE) \
							  $(RXOS_TMPFS_SIZE)

print-post-script-args:
	@echo $(BR2_ROOTFS_POST_SCRIPT_ARGS)
