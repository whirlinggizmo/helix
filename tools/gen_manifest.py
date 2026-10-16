"""Asset manifests for a folder tree, as helix.assets.AssetManifest reads them: a manifest.json in the folder and in every folder under it,
listing each file's SHA-256 and each subfolder's manifest's, so a client knows an unchanged folder from its parent alone. Written deepest
first, deterministically (sorted, compact), and only where one changed; manifest.json files themselves aren't listed, nor names an asset
path can't hold (helix.assets.AssetPath: A-Z, a-z, 0-9, '_', '.', '-'), which no asset could load and a client would refuse the manifest for.

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

def write(folder):
    """Writes folder's manifest, and its subfolders' first; returns its bytes."""
    files={};dirs={}
    for entry in sorted(folder.iterdir()):
        if not VALID.fullmatch(entry.name) or entry.name in ('.','..'):continue
        if entry.is_dir():dirs[entry.name]=digest(write(entry))
        elif entry.is_file() and entry.name!=NAME:files[entry.name]=digest(entry.read_bytes())
    data=json.dumps({'manifest':1,'files':files,'dirs':dirs},sort_keys=True,separators=(',',':')).encode()
    target=folder/NAME
    if not target.is_file() or target.read_bytes()!=data:target.write_bytes(data)
    return data

def main():
    if len(sys.argv)!=2 or not Path(sys.argv[1]).is_dir():sys.exit(__doc__)
    write(Path(sys.argv[1]))

if __name__=='__main__':main()
