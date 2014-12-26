from altera_pio import AlteraPIO
import time
import sys

class ad9650_spi(object):
  TCK = 1 << 6
  CS  = 1 << 5
  SDI = 1 << 4
  SDO = 1 << 3
  
  CHIP_ID_REG = 0x01
  CHIP_GRADE_REG = 0x02
  OUTPUT_MODE_REG = 0x14
  TRANSFER_REG = 0xFF
  TEST_MODE_REG = 0x0D
  
  def __init__(self, pio = None):
    if pio != None:
      self.pio = pio
    else:
      self.pio = AlteraPIO(base = 0x50000)
    self.pio.clearBits(self.SDI | self.TCK)
    self.pio.setBits(self.CS)
    self.pio.setDirection(self.TCK | self.CS | self.SDI)
    
  def ioByte(self, byteOut):
    byteIn = 0
    for i in range(8)[::-1]:
      byteIn |= (1 << i) if (self.pio.readBits() & self.SDO) else 0
      if byteOut & (1 << i):
        self.pio.setBits(self.SDI)
      else:
        self.pio.clearBits(self.SDI)
      #time.sleep(0.001)
      self.pio.setBits(self.TCK)
      #time.sleep(0.001)
      self.pio.clearBits(self.TCK)
      #time.sleep(0.001)
      
    return byteIn

  def readReg(self, reg):
    self.pio.clearBits(self.CS)
    self.ioByte(0x80 + reg / 256)
    self.ioByte(reg % 256)
    regData = self.ioByte(0)
    self.pio.setBits(self.CS)
    return regData
    
  def writeReg(self, reg, data):
    self.pio.clearBits(self.CS)
    self.ioByte(reg / 256)
    self.ioByte(reg % 256)
    self.ioByte(data)
    self.pio.setBits(self.CS)
    
  def init(self):
    print "CHIP_ID = %02X" % self.readReg(self.CHIP_ID_REG)
    print "CHIP_GRADE = %02X" % self.readReg(self.CHIP_GRADE_REG)
    print "OUTPUT_MODE = %02X" % self.readReg(self.OUTPUT_MODE_REG)
    self.writeReg(self.OUTPUT_MODE_REG, 0x20)
    print "OUTPUT_MODE = %02X" % self.readReg(self.OUTPUT_MODE_REG)
    self.writeReg(self.TRANSFER_REG, 0x01)
    print "OUTPUT_MODE = %02X" % self.readReg(self.OUTPUT_MODE_REG)
    
  def testMode(self, enableTest):
    test_mode = 0x80 | 0x06
    if not enableTest:
      test_mode = 0
      print "DISABLE TEST MODE"
    self.writeReg(self.TEST_MODE_REG, test_mode | 0x10)
    print "TEST_MODE = %02X" % self.readReg(self.TEST_MODE_REG)
    self.writeReg(self.TRANSFER_REG, 0x01)
    print "TEST_MODE = %02X" % self.readReg(self.TEST_MODE_REG)

    self.writeReg(self.TEST_MODE_REG, test_mode)
    print "TEST_MODE = %02X" % self.readReg(self.TEST_MODE_REG)
    self.writeReg(self.TRANSFER_REG, 0x01)
    print "TEST_MODE = %02X" % self.readReg(self.TEST_MODE_REG)


if __name__ == "__main__":
  adc = ad9650_spi()
  adc.init()
  if len(sys.argv) > 1:
    adc.testMode(False)
  else:
    adc.testMode(True)
  
  

  