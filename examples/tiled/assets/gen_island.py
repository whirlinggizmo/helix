"""The tiled example's map, made here and committed (examples/tiled/assets/maps/), each file only when it's missing (tools/example.py runs
this before copying the example's assets), or anew with --regenerate. They're Tiled's own files, to open and edit in Tiled:
  - terrain.png: 16 x 16 tiles, 4 a row: the first 16 a corner terrain set's every arrangement of grass and water (tile id = TL*8 + TR*4 +
    BR*2 + BL, a 1 water), the boundary between drawn as a curve so neighbors join; then a coin's four frames, turning.
  - ground.tsj: the tileset: its terrain set "land" (grass 1, water 2) and the coin animated (150 ms a frame), its class "Coin".
  - island.tmj: a 24 x 14 island: its "land" layer from a corner grid (grass inside an uneven circle), a "coins" layer, and "things": the
    start (a point) and a sign (a rectangle with a "text" property).
Standard library only: the PNG written by hand."""
import json
import math
from pathlib import Path
import struct
import sys
import zlib

HERE=Path(__file__).resolve().parent/'maps'
TILE=16
GRASS=(84,158,70);GRASS_DARK=(64,132,56);WATER=(48,108,196);WATER_LIGHT=(80,140,220);SAND=(214,196,130)
COLUMNS,ROWS=24,14

def png(path,width,height,pixels):
    """Writes an RGBA PNG of width x height from pixels, a list of (r, g, b, a) rows top to bottom."""
    raw=b''.join(b'\0'+bytes(c for p in row for c in p) for row in pixels)
    def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))

def terrain_tile(tl,tr,br,bl):
    """A tile's pixels: water where the corners' blend is past half (a 1 a water corner), a sandy shore at the line, grass speckled."""
    rows=[]
    for y in range(TILE):
        row=[]
        for x in range(TILE):
            u=(x+.5)/TILE;v=(y+.5)/TILE
            w=tl*(1-u)*(1-v)+tr*u*(1-v)+br*u*v+bl*(1-u)*v
            if w>.56:c=WATER_LIGHT if (x*7+y*3)%11==0 else WATER
            elif w>.44:c=SAND
            else:c=GRASS_DARK if (x*5+y*9)%13==0 else GRASS
            row.append(c+(255,))
        rows.append(row)
    return rows

def coin_tile(frame):
    """A coin turning: its width by the frame, gold with a darker rim, clear round it."""
    half=[6,4,1.5,4][frame];rows=[]
    for y in range(TILE):
        row=[]
        for x in range(TILE):
            dx=(x+.5-8)/max(half,.5);dy=(y+.5-8)/6
            d=dx*dx+dy*dy
            row.append((150,110,20,255) if .7<d<=1 else (240,196,60,255) if d<=.7 else (0,0,0,0))
        rows.append(row)
    return rows

def sheet():
    tiles=[terrain_tile(id>>3&1,id>>2&1,id>>1&1,id&1) for id in range(16)]+[coin_tile(f) for f in range(4)]
    width=4*TILE;height=(len(tiles)+3)//4*TILE
    pixels=[[(0,0,0,0)]*width for _ in range(height)]
    for i,t in enumerate(tiles):
        ox=i%4*TILE;oy=i//4*TILE
        for y in range(TILE):
            pixels[oy+y][ox:ox+TILE]=t[y]
    return width,height,pixels

def tileset(width,height):
    tiles=[{'tileid':id,'wangid':[0,(id>>2&1)+1,0,(id>>1&1)+1,0,(id&1)+1,0,(id>>3&1)+1]} for id in range(16)]
    return {'type':'tileset','version':'1.10','tiledversion':'1.10.2','name':'ground','image':'terrain.png','imagewidth':width,'imageheight':height,
            'tilewidth':TILE,'tileheight':TILE,'tilecount':20,'columns':4,'margin':0,'spacing':0,
            'tiles':[{'id':16,'type':'Coin','animation':[{'tileid':16+f,'duration':150} for f in range(4)]}],
            'wangsets':[{'name':'land','type':'corner','tile':-1,'colors':[{'name':'grass','color':'#549e46','tile':0,'probability':1},
                                                                         {'name':'water','color':'#306cc4','tile':15,'probability':1}],'wangtiles':tiles}]}

def island():
    # Corners: water (1) outside an uneven circle, grass (0) in it.
    corners=[[0]*(COLUMNS+1) for _ in range(ROWS+1)]
    for y in range(ROWS+1):
        for x in range(COLUMNS+1):
            dx=(x-COLUMNS/2)/(COLUMNS/2-1.5);dy=(y-ROWS/2)/(ROWS/2-1.5)
            a=math.atan2(dy,dx);r=1+.12*math.sin(3*a)+.08*math.cos(5*a)
            corners[y][x]=0 if dx*dx+dy*dy<r*r else 1
    land=[1+(corners[y][x]<<3|corners[y][x+1]<<2|corners[y+1][x+1]<<1|corners[y+1][x]) for y in range(ROWS) for x in range(COLUMNS)]
    coins=[0]*(COLUMNS*ROWS)
    for x,y in [(9,5),(10,5),(11,5),(14,8),(15,8),(12,10)]:
        coins[y*COLUMNS+x]=17
    return {'type':'map','version':'1.10','tiledversion':'1.10.2','orientation':'orthogonal','renderorder':'right-down','infinite':False,
            'width':COLUMNS,'height':ROWS,'tilewidth':TILE,'tileheight':TILE,'nextlayerid':4,'nextobjectid':3,'backgroundcolor':'#306cc4',
            'tilesets':[{'firstgid':1,'source':'ground.tsj'}],
            'layers':[{'id':1,'type':'tilelayer','name':'land','width':COLUMNS,'height':ROWS,'x':0,'y':0,'opacity':1,'visible':True,'data':land},
                      {'id':2,'type':'tilelayer','name':'coins','width':COLUMNS,'height':ROWS,'x':0,'y':0,'opacity':1,'visible':True,'data':coins},
                      {'id':3,'type':'objectgroup','name':'things','draworder':'topdown','x':0,'y':0,'opacity':1,'visible':True,'objects':[
                          {'id':1,'name':'start','type':'Spawn','point':True,'x':8*TILE,'y':7*TILE,'width':0,'height':0,'rotation':0,'visible':True},
                          {'id':2,'name':'sign','type':'Sign','x':15*TILE,'y':5*TILE,'width':2*TILE,'height':TILE,'rotation':0,'visible':True,
                           'properties':[{'name':'text','type':'string','value':'Welcome to the island'}]}]}]}

def generate(regenerate=False):
    HERE.mkdir(parents=True,exist_ok=True)
    width,height,pixels=sheet()
    files={'terrain.png':lambda p:png(p,width,height,pixels),'ground.tsj':lambda p:p.write_text(json.dumps(tileset(width,height),indent=1)+'\n'),
           'island.tmj':lambda p:p.write_text(json.dumps(island(),indent=1)+'\n')}
    for name,write in files.items():
        if regenerate or not (HERE/name).exists():write(HERE/name)

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__,formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--regenerate',action='store_true',help='make every file again, over what\'s there')
    generate(parser.parse_args().regenerate)
