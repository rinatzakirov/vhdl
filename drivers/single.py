from mmap import mmap
import struct, time

dmaAddr = [0x30000000, 0x2f000000, 0x2e000000, 0x2d000000]
dmaMem = [None, None, None, None]
dmaSize = 1024 * 1024 * 16

regsMem = None
with open("/dev/mem", "rb+") as f:
	regsMem = mmap(f.fileno(), 16 * 4, offset = 0xff240000)
	for i in range(len(dmaAddr)): dmaMem[i] = mmap(f.fileno(), dmaSize, offset = dmaAddr[i])

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

#checkMem()
#for i in range(dmaSize / 4):
#  dmaMem[(i * 4):(i * 4 + 4)] = struct.pack("<L", i)
#checkMem()
  
def printRegs():
	print "REG 0 = %08X" % readReg(0)
	print "REG 1 = %08X" % readReg(1)
	print "REG 2 = %08X" % readReg(2)
	print "REG 3 = %08X" % readReg(3)

def init():
  writeReg(0, 0x00)
  writeReg(0, 0x04) # Stop stream
  while readReg(0) & 2 != 0: pass # Wait till the streamer is idle
  writeReg(0, 0x20) # Zero-fill if needed
  while readReg(0) & 1 != 0: pass # Wait till the writer is idle
  writeReg(0, 0x18) # Reset FIFOs and Stream full flag
  time.sleep(0.1)
  printRegs()
  writeReg(0, 0x00)
  printRegs()
  
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
firstTime = True
writeReg(2, dmaSize / (128 / 8))
for i in range(4):
	writeReg(1, dmaAddr[i])
	lastReg2 = readReg(2)
	reg2 = readReg(2)
	while reg2 <= lastReg2 and not firstTime: 
		lastReg2 = reg2
		reg2 = readReg(2)
	if firstTime:
		firstTime = False
		writeReg(0, 0x00000043)
		writeReg(0, 0x00000041)
writeReg(0, 0x0)
while readReg(0) != 6: printRegs()
print "done"
    
#checkMem()  
with open("dump.dat", "w+") as f: 
    for mem in dmaMem: f.write(mem[:dmaSize])

#writeReg(0, 0x00000000)



