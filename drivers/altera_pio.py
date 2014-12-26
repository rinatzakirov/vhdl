from mmap import mmap
import struct, time

class PhysMem32(object):
  def __init__(self, base, words = 16):
    self.regsMem = None
    with open("/dev/mem", "rb+") as f:
      self.regsMem = mmap(f.fileno(), words * 4, offset = 0xff200000 + base)
    if self.regsMem == None:
      raise Exception("Couldn't open /dev/mem. Root?")
  
  def writeReg(self, dwordAddr, val):
    self.regsMem[(dwordAddr * 4):(dwordAddr * 4 + 4)] = struct.pack("<I", val)
    
  def readReg(self, dwordAddr):
    return struct.unpack("<I", self.regsMem[(dwordAddr * 4):(dwordAddr * 4 + 4)])[0]

class AlteraPIO(PhysMem32):
  DATA_REG = 0
  DIRECTION_REG = 1
  BITSET_REG = 4
  BITCLEAR_REG = 5
  
  def __init__(self, base):
    super(AlteraPIO, self).__init__(base, words = 6)
  
  # For every bit, 1 is output, 0 is input
  def setDirection(self, direction):
    self.writeReg(self.DIRECTION_REG, direction)
    
  def setBits(self, bits):
    self.writeReg(self.BITSET_REG, bits)

  def clearBits(self, bits):
    self.writeReg(self.BITCLEAR_REG, bits)
    
  def readBits(self):
    return self.readReg(self.DATA_REG)