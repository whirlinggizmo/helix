"""The tools' command lines (docs/CONVENTIONS.md, "Every tool answers --help"): a parser whose help is the tool's docstring, which refuses an
argument the tool doesn't take, and the command line of a module the tools import, which has nothing to run. Imported by the tools, not run.
Standard library only."""
import argparse
import sys


def parser(doc):
    """An argument parser for a tool: --help prints doc, its docstring, whole and as written; an argument it wasn't given is refused (exit 2)."""
    return argparse.ArgumentParser(description=doc, formatter_class=argparse.RawDescriptionHelpFormatter)


def module(doc):
    """A module's command line: --help prints doc; anything else, or nothing, says it's imported, not run (exit 2)."""
    parser(doc).parse_args()
    sys.exit(f'{sys.argv[0]}: a module the tools import, with nothing to run of its own (--help says what it is)')


if __name__ == '__main__':
    module(__doc__)
