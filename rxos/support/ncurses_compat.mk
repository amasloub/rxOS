# Add symlinks to relevant ncurses libraries
#
# The demod binary is linked against libtinfo[1] and libncurses which are
# different versions that those in the rootfs. Because of thise, we need to
# create symlinks to it can find the correct wrong libraries (no, it's not a
# typo, they are still wrong even though they seem to work).
#
# [1] https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libtinfo
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

NCURSES_WANTED = 5
NCURSES_ACTUAL = $(NCURSES_VERSION)
LIBDIR = $(TARGET_DIR)/usr/lib

define NCURSES_COMPAT
	$(call msg,"Creating ncurses compatibility symlinks")
	ln -fsr "$(LIBDIR)/libncurses.so.$(NCURSES_ACTUAL)" \
	  "$(LIBDIR)/libtinfo.so.$(NCURSES_WANTED)"
	ln -fsr "$(LIBDIR)/libtinfo.so.$(NCURSES_WANTED)" "$(LIBDIR)/libtinfo.so"
endef

TARGET_FINALIZE_HOOKS += NCURSES_COMPAT
