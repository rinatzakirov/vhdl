from mmap import mmap
import struct, time

dmaAddr = 0x38000000
dmaMem = None
dmaSize = 1024 * 1024 * 16

regsMem = None
with open("/dev/mem", "rb+") as f:
	regsMem = mmap(f.fileno(), 16 * 4, offset = 0xff240000)
	dmaMem = mmap(f.fileno(), dmaSize, offset = dmaAddr)

def readReg(regOffset):
	return struct.unpack("<L", regsMem[(regOffset*4):(regOffset*4 + 4)])[0]

def writeReg(regOffset, value):
	regsMem[(regOffset*4):(regOffset*4 + 4)] = struct.pack("<L", value)
  
def checkMem():
  printed = 0
  for i in range(dmaSize / 4):
    val = struct.unpack("<L", dmaMem[(i * 4):(i * 4 + 4)])[0]
    if val != i:
      if printed < 10:
        print "dmaMem[%08X] = %08X" % (i, val)
      printed += 1
  print "mismatches = %08X" % printed
  
def printRegs():
        print "REG 0 = %08X" % readReg(0)
        print "REG 1 = %08X" % readReg(1)
        print "REG 2 = %08X" % readReg(2)
        print "REG 3 = %08X" % readReg(3)
  
def tempInit():
  writeReg(0, 0x00)
  writeReg(0, 0x04) # Stop stream
  while readReg(0) & 2 != 0: pass # Wait till the streamer is idle
  writeReg(0, 0x20) # Zero-fill if needed
  while readReg(0) & 1 != 0: pass # Wait till the writer is idle
  writeReg(0, 0x18 + 2) # Reset FIFOs and Start streamer
  writeReg(0, 0x18 + 4) # Reset FIFOs and stop streamer
  printRegs()
  writeReg(0, 0x18) # Reset FIFOs and Stream full flag
  writeReg(0, 0x00)
  printRegs()
  
tempInit()
printRegs()
writeReg(2, dmaSize / (128 / 8))
writeReg(1, dmaAddr)
writeReg(0, 0x00000043)
writeReg(0, 0x00000041)
printRegs()
print "done"



