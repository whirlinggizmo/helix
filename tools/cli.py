"""The tools' command lines (docs/CONVENTIONS.md, "Every tool answers --help"): a parser whose help is the tool's docstring, which refuses an
argument the tool doesn't take, the run options every tool that runs programs takes alike (runs), and the command line of a module the tools
import, which has nothing to run. Imported by the tools, not run. Standard library only."""
import argparse
import sys


def parser(doc):
    """An argument parser for a tool: --help prints doc, its docstring, whole and as written; an argument it wasn't given is refused (exit 2)."""
    return argparse.ArgumentParser(description=doc, formatter_class=argparse.RawDescriptionHelpFormatter)


def runs(parser, kinds=True):
    """Adds the two choices a tool that runs programs offers, the same in every tool. What runs, when kinds: --native and --page, each
    alone for that kind, neither (or both) for both (targets). Where: --headless, the default, off screen (a native program on a private
    display, a page in headless Chromium), so CI and unattended runs need neither; or --headed, on this machine's display (a native
    program's window, the browser's), for timing or watching."""
    if kinds:
        parser.add_argument('--native', action='store_true', help='run the native programs (alone, or with --page both, as with neither)')
        parser.add_argument('--page', action='store_true', help='run the pages (alone, or with --native both, as with neither)')
    where = parser.add_mutually_exclusive_group()
    where.add_argument('--headless', dest='headed', action='store_false',
                       help='off screen: a native program on a private display, a page in headless Chromium (the default)')
    where.add_argument('--headed', dest='headed', action='store_true',
                       help="on this machine's display: a native program's window and the browser's, for timing or watching")
    parser.set_defaults(headed=False)


def targets(args):
    """(native, page): the kinds to run, from runs' --native and --page, both when neither is given."""
    return args.native or not args.page, args.page or not args.native


def module(doc):
    """A module's command line: --help prints doc; anything else, or nothing, says it's imported, not run (exit 2)."""
    parser(doc).parse_args()
    sys.exit(f'{sys.argv[0]}: a module the tools import, with nothing to run of its own (--help says what it is)')


if __name__ == '__main__':
    module(__doc__)
