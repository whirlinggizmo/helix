"""Asset manifests for a directory tree, as helix.asset.AssetManifest reads them: a manifest.json in the directory and in every directory under it,
listing each file's SHA-256 and each subdirectory's manifest's, so a client knows an unchanged directory from its parent alone. Written deepest
first, deterministically (sorted, compact), and only where one changed; manifest.json files themselves aren't listed, nor names an asset
path can't hold (helix.asset.AssetPath: A-Z, a-z, 0-9, '_', '.', '-'), which no asset could load and a client would refuse the manifest for.

  python3 tools/gen_manifest.py DIR"""
import hashlib
import json
import re
import sys
from pathlib import Path

NAME='manifest.json'
VALID=re.compile(r'[A-Za-z0-9_.-]+')

def digest(data):
    """data's hash as manifests write it."""
    return 'sha256:'+hashlib.sha256(data).hexdigest()

def write(directory):
    """Writes directory's manifest, and its subdirectories' first; returns its bytes."""
    files={};dirs={}
    for entry in sorted(directory.iterdir()):
        if not VALID.fullmatch(entry.name) or entry.name in ('.','..'):continue
        if entry.is_dir():dirs[entry.name]=digest(write(entry))
        elif entry.is_file() and entry.name!=NAME:files[entry.name]=digest(entry.read_bytes())
    data=json.dumps({'manifest':1,'files':files,'dirs':dirs},sort_keys=True,separators=(',',':')).encode()
    target=directory/NAME
    if not target.is_file() or target.read_bytes()!=data:target.write_bytes(data)
    return data

def main():
    import cli
    p=cli.parser(__doc__);p.add_argument('directory',type=Path,help='the assets directory to write manifests through')
    directory=p.parse_args().directory
    if not directory.is_dir():p.error(f'{directory} is not a directory')
    write(directory)

if __name__=='__main__':main()
