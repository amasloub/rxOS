################################################################################
#
# vsftpd_rxos
#
################################################################################

VSFTPD_RXOS_VERSION = 3.0.3
VSFTPD_RXOS_SITE = https://security.appspot.com/downloads
VSFTPD_RXOS_LIBS = -lcrypt
VSFTPD_RXOS_LICENSE = GPLv2
VSFTPD_RXOS_LICENSE_FILES = COPYING

define VSFTPD_RXOS_DISABLE_UTMPX
	$(SED) 's/.*VSF_BUILD_UTMPX/#undef VSF_BUILD_UTMPX/' $(@D)/builddefs.h
endef

define VSFTPD_RXOS_ENABLE_SSL
	$(SED) 's/.*VSF_BUILD_SSL/#define VSF_BUILD_SSL/' $(@D)/builddefs.h
endef

ifeq ($(BR2_PACKAGE_VSFTPD_RXOS_UTMPX),)
VSFTPD_RXOS_POST_CONFIGURE_HOOKS += VSFTPD_RXOS_DISABLE_UTMPX
endif

ifeq ($(BR2_PACKAGE_OPENSSL),y)
VSFTPD_RXOS_DEPENDENCIES += openssl host-pkgconf
VSFTPD_RXOS_LIBS += `$(PKG_CONFIG_HOST_BINARY) --libs libssl libcrypto`
VSFTPD_RXOS_POST_CONFIGURE_HOOKS += VSFTPD_RXOS_ENABLE_SSL
endif

ifeq ($(BR2_PACKAGE_LIBCAP),y)
VSFTPD_RXOS_DEPENDENCIES += libcap
VSFTPD_RXOS_LIBS += -lcap
endif

ifeq ($(BR2_PACKAGE_LINUX_PAM),y)
VSFTPD_RXOS_DEPENDENCIES += linux-pam
VSFTPD_RXOS_LIBS += -lpam
endif

define VSFTPD_RXOS_BUILD_CMDS
	$(MAKE) CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" LIBS="$(VSFTPD_RXOS_LIBS)" -C $(@D)
endef

define VSFTPD_RXOS_USERS
    guest        1003    guest        1003    =guest       /home/guest          /bin/false     -
endef

define VSFTPD_RXOS_INSTALL_INIT_SYSV
	$(INSTALL) -D -m 755 $(call lpkgdir,vsftpd-rxos)/S70vsftpd $(TARGET_DIR)/etc/init.d/S70vsftpd
endef

# vsftpd won't work if the jail directory is writable, it has to be
# readable only otherwise you get the following error:
# 500 OOPS: vsftpd: refusing to run with writable root inside chroot()
# That's why we have to adjust the permissions of /home/ftp
define VSFTPD_RXOS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 755 $(@D)/vsftpd $(TARGET_DIR)/usr/sbin/vsftpd
	test -f $(TARGET_DIR)/etc/vsftpd.conf || \
		$(INSTALL) -D -m 644 $(call lpkgdir,vsftpd-rxos)/vsftpd.conf \
			$(TARGET_DIR)/etc/vsftpd.conf
	$(INSTALL) -d -m 700 $(TARGET_DIR)/usr/share/empty
	$(INSTALL) -d -m 555 $(TARGET_DIR)/home/guest
endef

$(eval $(generic-package))
