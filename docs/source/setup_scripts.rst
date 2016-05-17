Setup scripts
=============

If the "User-provided options > System configuration > Perform initial system
setup" option is enabled, a ``S00setup`` init script is installed in the target
system. This script runs the scripts found in ``/etc/setup.d`` during init,
allowing the developer to perform arbitrary tasks during init.

The setup scripts must have an exectuable flag and must have a ``.sh``
extension (even if it's not a shell script!). When a script is run, a log file
is created that is named so as to match the script name: 
``/var/log/setup/<scriptname>.sh.log``. Any messages from the setup script are
logged in that file. The log file is kept only if the script's exit code is not
0. No output from the script is echoed to console.

One example of a setup script is the ``persist.sh`` which is installed by
enabling "User-provided options > System configuration > Persistent system
configuration" option.
