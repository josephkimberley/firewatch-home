#!/usr/bin/env python3
"""Draw an original geometric lookout mark; no third-party logo or dependencies."""
import pathlib
import struct
import zlib


def png(size):
    # Normalized polygons: simple roof, cabin, platform, crossed tower legs.
    shapes = [([(25,33),(50,18),(75,33)],(243,196,118)), ([(31,34),(69,34),(69,49),(31,49)],(243,196,118)),
              ([(26,50),(74,50),(74,54),(26,54)],(243,196,118)), ([(34,54),(39,54),(34,84),(29,84)],(243,196,118)),
              ([(61,54),(66,54),(71,84),(66,84)],(243,196,118)), ([(37,56),(65,79),(63,83),(35,60)],(243,196,118)),
              ([(63,56),(35,79),(37,83),(65,60)],(243,196,118)), ([(38,38),(47,38),(47,45),(38,45)],(26,45,46)),
              ([(53,38),(62,38),(62,45),(53,45)],(26,45,46))]
    def inside(x,y,points):
        yes=False
        for i,(x1,y1) in enumerate(points):
            x2,y2=points[(i+1)%len(points)]
            if ((y1>y)!=(y2>y)) and x < (x2-x1)*(y-y1)/(y2-y1)+x1: yes=not yes
        return yes
    data=bytearray()
    for y in range(size):
        data.append(0)
        for x in range(size):
            total=[0,0,0]
            for dy in (.25,.75):
                for dx in (.25,.75):
                    color=(26,45,46)
                    for points,fill in shapes:
                        if inside((x+dx)*100/size,(y+dy)*100/size,points): color=fill
                    for c in range(3): total[c]+=color[c]
            data.extend(v//4 for v in total)
    def chunk(name,content): return struct.pack('>I',len(content))+name+content+struct.pack('>I',zlib.crc32(name+content)&0xffffffff)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(bytes(data),9))+chunk(b'IEND',b'')


if __name__=='__main__':
    root=pathlib.Path(__file__).resolve().parents[1]/'src/native'
    for name,size in [('icon.png',80),('large-icon.png',130)]:
        (root/name).write_bytes(png(size))
        print(name,size)
