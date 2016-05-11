Boot hooks
==========

Boot hooks are early userspace shell scripts (part of the initial RAM
filesystem image) that are invoked by the ``init`` script on each boot. 

Boot hook local packages
------------------------

Boot hooks are provided by local packages that are named ``boothook-*``. A
typical boot hook consists of the following:

- initial RAM filesystem file list (to be added to the default set of files)
- hook script

Additionally, the package may select other packages that would become part of
the root filesystem and used as the source for the initial RAM filesystem file
list, or provide configuration options for the hook script.

The initial RAM filesystem file list is mandatory and it must be installed in
the ``$(BINARIES_DIR)/initramfs`` directory. The file must contain at least a
reference to the hook script and place the hook script into the root of the
initramfs.

There are no rules as to the naming of the initramfs list file, but a
convention is to use the package name without the ``boothook-`` prefix, and
append ``.cpio.in`` extension. The file must also be declared as the initramfs
list extension by appending its name (just the name, not the full path) to
``INIT_CPIO_LISTS`` variable in the makefile. More information about the
initramfs list format can be found `on landley.net
<http://www.landley.net/writing/rootfs-howto.html>`_.

By convention, we install the hook script into the same directory as the
initramfs list, so that it can be accessed quickly when needed for debugging 
and similar purposes, but this is not required.

Finally, the package is registered under the "System configuration" section in
the rxOS's master ``Config.in``.

Simple boot hook example
------------------------

For our example, we will create a simple hook script that shows a greeting with
configurable name. Let's call this hook 'greeter'.

We first need to create a directory for the hook. ::

    $ mkdir -p rxos/local/boothook-greeter/src

Note that we have created not only the hook package directory, but also a
``src`` directory inside it. This is a typical setup for local packages, where
the ``src`` directory provides the source code.

Now let's create the ``Config.in`` file for the hook package (do not copy this
example as it is _not_ correctly formatted). ::

    config BR2_PACKAGE_BUILDHOOK_GREETER
        bool "Greet the user"
        help
          Greet the user using a configurable message.

    if BR2_PACKAGE_BUILDHOOK_GREETER
    
    config BR2_PACKAGE_BUILDHOOK_GREETER_MESSAGE
        string "Greeting message"
        default "Welcome to rxOS!"
        help
          Greeting message printed to the user during
          boot.

    endif # BR2_PACKAGE_BUILDHOOK_GREETER

We will also register this configuration. We edit the ``rxOS/Config.in`` file
and modify the "System configuration" menu. ::

    menu "System configuration"
        ...
        source "$BR2_EXTERNAL/local/boothook-greeter/Config.in"
        ...
    endmenu

Before we can write the matching makefile, we need the hook script itself. In
the ``src`` directory, we create a file called ``greeter.sh`` that looks like
this::

    #!/busybox sh
    MESSAGE="%MSG%"
    echo "
    ************************************
    $MESSSAGE
    ************************************
    "

The ``%MSG%`` is a placeholder that will be populated later in the makefile.

.. note::
    The ``%NAME%`` syntax is just a convention. You can use whatever you like
    for your placeholders, and also any technique for populating them. This is
    just an example of how we do it.

We also need a initramfs list file. We will assume that, as per convention, the
hook script will be installed in ``$(BINARIES_DIR)/initramfs``. The list will
be saved as ``src/init.cpio.in``. ::

    file /hook-greeter.sh %BINDIR%/initramfs/greeter.sh

Now we have all the files we need, so we can proceed to write the makefile.

Now let's create the makefile. The makefile is called ``buildhook-greeter.mk``
and should be saved in the package directory. ::

    ###################################################################
    #
    # buildhook-greeter
    #
    ###################################################################

    BUILDHOOK_GREETER_VERSION = 1.0
    BUILDHOOK_GREETER_LICENSE = GPLv3+
    BUILDHOOK_GREETER_SITE = $(BR2_EXTERNAL)/local/buildhook-greeter/src
    BUILDHOOK_GREETER_SITE_METHOD = local

    ### (More stuff here soon...) ###

    $(eval $(generic-package))

Thus far, it's a typical Buildroot `generic package <http://bit.ly/1saNe4s>`_ 
makefile. (Assume that we will keep the code above and below the 'More stuff' 
comment in the snippets that follow.)

We first need to prepare the user-specified message. When a value is specified
in the Buildroot's menuconfig, it comes with double-quotes around them so those
need to be stripped out. ::

    BUILDHOOK_GREETER_MSG = $(call qstrip,$(BR2_BUILDHOOK_GREETER_MESSAGE))

Now we define the install commands that will install the initramfs list and the
hook script in appropriate places and replace the placeholders with appropriate
values. ::

    define BUILDHOOK_GREETER_INSTALL_TARGET_CMDS
        install -Dm644 $(@D)/init.cpio.in \
            $(BINARIES_DIR)/initramfs/greeter.cpio.in
        sed -i 's|%BINDIR%|$(BINARIES_DIR)' \
            $(BINARIES_DIR)/initramfs/greeter.cpio.in
        install -Dm644 $(@D)/greeter.sh \
            $(BINARIES_DIR)/initramfs/greeter.sh
        sed -i 's|%MSG%|$(BUILDHOOK_GREETER_MSG)' \
            $(BINARIES_DIR)/initramfs/greeter.sh
    endef

This concludes our makefile. Now we can test whether it all works. ::

    $ make buildhook-greeter-rebuild

When we're done, we can take a look at ``out/images/initramfs`` directory and
inspect the results. If everything is alright, we can include the hook in
initramfs by enabling "User-provided options > System configuration > Greet 
the user" option and setting the message.

Modifying the hooks
-------------------

When the hook is modified, and it's time to rebuild the image, we need to do it
like so::

    $ make buildhook-<hookname>-rebuild rebuild

Simply doing ``make rebuild`` will not update the hook as the package is marked
as already installed.
