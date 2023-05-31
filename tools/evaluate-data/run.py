#!/usr/bin/env python

import argparse
import logging

from os import path

from src.ParseFiles import parse_files_in_dir
from src.result import create_results


def start(args):
    debug = args.loglevel == logging.DEBUG

    unoptimized_data = parse_files_in_dir(args.unoptimized_directory, debug)
    optimized_data = parse_files_in_dir(args.optimized_directory, debug)

    create_results(args,
                   raw_optimized_data=optimized_data,
                   raw_unoptimized_data=unoptimized_data)


def main():
    parser = argparse.ArgumentParser(
        description='Calculate information and make graphs')

    parser.add_argument('-u', "--unoptimized-directory",
                        help="Input directory with unoptimized files.",
                        required=True,
                        dest="unoptimized_directory",
                        type=path.abspath)

    parser.add_argument('-o', "--optimized-directory",
                        help="Input directory with unoptimized files.",
                        required=True,
                        dest="optimized_directory",
                        type=path.abspath)

    parser.add_argument('-g', "--graphs",
                        help="Generate distribution graphs from both "
                             "directories.",
                        action="store_true",
                        default=False)

    parser.add_argument('-d', '--debug',
                        help="Enable debugging statements.",
                        action="store_const",
                        dest="loglevel",
                        const=logging.DEBUG)

    args = parser.parse_args()
    start(args)


if __name__ == '__main__':
    main()
