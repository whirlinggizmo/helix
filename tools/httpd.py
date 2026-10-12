"""Portable static delivery with the same gzip9 accounting used in size reports."""
import gzip,http.server,io
from pathlib import Path
from urllib.parse import urlsplit,unquote
class GzipHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*args,directory=None,reference=None,**kwargs):
        self.reference=Path(reference).resolve() if reference else None
        super().__init__(*args,directory=directory,**kwargs)
    def translate_path(self,path):
        relative=unquote(urlsplit(path).path)
        if self.reference and relative.startswith('/reference/'):
            candidate=(self.reference/relative.removeprefix('/reference/')).resolve()
            if candidate.is_relative_to(self.reference):return str(candidate)
            return str(self.reference/'__invalid_path__')
        return super().translate_path(path)
    def send_head(self):
        path=Path(self.translate_path(self.path))
        if path.is_dir():path=path/'index.html'
        if not path.is_file():self.send_error(404,'File not found');return None
        gzip_ok=False
        for encoding in self.headers.get('Accept-Encoding','').split(','):
            parts=encoding.strip().split(';')
            if parts[0]=='gzip':
                try:gzip_ok=all(not p.strip().startswith('q=') or float(p.strip()[2:])>0 for p in parts[1:])
                except ValueError:gzip_ok=False
        payload=path.read_bytes()
        if gzip_ok:payload=gzip.compress(payload,compresslevel=9,mtime=0)
        self.send_response(200);self.send_header('Content-Type',self.guess_type(str(path)));self.send_header('Content-Length',str(len(payload)));self.send_header('Vary','Accept-Encoding');self.send_header('Cache-Control','no-cache')
        if gzip_ok:self.send_header('Content-Encoding','gzip')
        self.end_headers();return io.BytesIO(payload)
