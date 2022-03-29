#!/usr/bin/env python
from curses import baudrate
from serial import Serial, EIGHTBITS, PARITY_NONE, STOPBITS_ONE
from sys import argv

assert len(argv) == 3 # python rs232.py [port name] [transmission method]
if argv[2] == "line":
    s = Serial(
        port=argv[1],
        baudrate=115200,
        bytesize=EIGHTBITS,
        parity=PARITY_NONE,
        stopbits=STOPBITS_ONE,
        xonxoff=False,
        rtscts=False
    )
elif argv[2] == "bt":
    s = Serial(
        port=argv[1],
        baudrate=9600,
    )
else:
    assert argv[2] == "line" or argv[2] == "bt" 

fp_key = open('key.bin', 'rb')
fp_enc = open('cipher_20220325.bin', 'rb')
fp_dec = open(f'dec_{argv[2]}.bin', 'wb')
assert fp_key and fp_enc and fp_dec

key = fp_key.read(64)
enc = fp_enc.read()
assert len(enc) % 32 == 0

s.write(key)
for i in range(0, len(enc), 32):
    s.write(enc[i:i+32])
    dec = s.read(31)
    #print(dec)
    fp_dec.write(dec)

fp_key.close()
fp_enc.close()
fp_dec.close()
