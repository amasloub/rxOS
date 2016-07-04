#!/usr/bin/python

import json


def read_args(target):
    """ Read a json file and return its 'sdr' key value """
    with open(target, 'r') as settings_file:
        settings = json.load(settings_file)
        return settings['sdr']


def stringify_args(args):
    """ Create the text used by sdr100 as an argument string """
    settings_text = ('-f {frequency} -u {uncertainty} -r {symbol_rate} '
                     '-s {sample_rate} -b {rf_filter}').format(**args)
    if args['descrambler']:
        settings_text += ' -w'
    return settings_text


def main():
    import argparse
    parser = argparse.ArgumentParser('SDR Argument Generator')
    parser.add_argument('JSON', help='JSON file to parse for SDR arguments')
    target = parser.parse_args().JSON
    try:
        args = read_args(target)
        print(stringify_args(args))
    except Exception:
        pass


if __name__ == "__main__":
    main()
