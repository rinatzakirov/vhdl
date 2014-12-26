from mmap import mmap
import struct, time

class StreamToAvalon(object):
  def __init__(self):
    self.dmaAddr = [0x38000000, 0x38000000, 0x37000000, 0x36000000]
    self.dmaMem = [None, None, None, None]
    self.dmaSize = 1024 * 1024 * 16

    self.regsMem = None
    with open("/dev/mem", "rb+") as f:
      self.regsMem = mmap(f.fileno(), 16 * 4, offset = 0xff240000)
      for i in range(len(self.dmaAddr)): self.dmaMem[i] = mmap(f.fileno(), self.dmaSize, offset = self.dmaAddr[i])

  def readReg(self, regOffset):
    return struct.unpack("<L", self.regsMem[(regOffset*4):(regOffset*4 + 4)])[0]

  def writeReg(self, regOffset, value):
    self.regsMem[(regOffset*4):(regOffset*4 + 4)] = struct.pack("<L", value)
    
  def printRegs(self):
    print "REG 0 = %08X" % self.readReg(0)
    print "REG 1 = %08X" % self.readReg(1)
    print "REG 2 = %08X" % self.readReg(2)
    print "REG 3 = %08X" % self.readReg(3)

  def reset(self):
    self.writeReg(0, 0x00)
    self.writeReg(0, 0x04) # Stop stream
    while self.readReg(0) & 2 != 0: pass # Wait till the streamer is idle
    self.writeReg(0, 0x20) # Zero-fill if needed
    while self.readReg(0) & 1 != 0: pass # Wait till the writer is idle
    self.writeReg(0, 0x18 + 2) # Reset FIFOs and Start streamer
    self.writeReg(0, 0x18 + 4) # Reset FIFOs and stop streamer
    #self.printRegs()
    self.writeReg(0, 0x18) # Reset FIFOs and Stream full flag
    self.writeReg(0, 0x00)
    #self.printRegs()
    
  def singleRun(self, bufferIndex):
    #self.printRegs()
    self.writeReg(2, self.dmaSize / (128 / 8))
    self.writeReg(1, self.dmaAddr[bufferIndex])
    self.writeReg(0, 0x00000003)
    self.writeReg(0, 0x00000000)
    while self.readReg(0) != 6: pass
    
  def readBuffer(self, bufferIndex, offset, size):
    return self.dmaMem[bufferIndex][offset:(offset + size)]
