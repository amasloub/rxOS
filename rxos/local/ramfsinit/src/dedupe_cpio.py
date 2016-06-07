#!/usr/bin/env python
#
# Removes duplicate paths from initramfs list file.
#
# This file is part of rxOS.
# rxOS is free software released under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

import sys


def target_path(line):
    """
    Return the target path from given initramfs list file line.

    If the line does not consist of multiple whitespace-separate fileds, or
    begins with a '#', ``None`` is returned.
    """
    if (not line) or line.startswith('#'):
        return None
    try:
        return line.split()[1]
    except IndexError:
        return None


def dedupe_list(path):
    lines = []
    paths = [None]
    with open(path, 'r') as fd:
        for line in fd:
            line = line.strip()
            tpath = target_path(line)
            if target_path(line) in paths:
                print('SKIPPED: {}'.format(tpath or '(blank/comment)'))
                continue
            paths.append(tpath)
            lines.append(line)
    with open(path, 'w') as fd:
        fd.write('\n'.join(lines))


def main():
    try:
        irfs_list = sys.argv[1]
    except IndexError:
        print('Missing argument: initramfs list file path')
        return 1
    print("Processing '{}'".format(irfs_list))
    dedupe_list(irfs_list)
    return 0


if __name__ == '__main__':
    sys.exit(main())
