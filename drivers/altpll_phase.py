from altera_pio import AlteraPIO
import time

class altpll_phase(object):  
  SCANCLK = 1 << 6
  PHASE_EN = 1 << 5
  UPDN = 1 << 7
  CNTSEL = 1 << 0
  
  PHASE_DONE = 1

  def __init__(self, pio = None):
    if pio != None:
      self.pio = pio
    else:
      self.pio = AlteraPIO(base = 0x60000)
    self.pio.clearBits(0xFF)
    
  def toggleClock(self):
    for i in range(100):
      self.pio.setBits(self.SCANCLK)
      self.pio.clearBits(self.SCANCLK)

  def phase_shift(self, directionUp = True):
    self.toggleClock()
    success = 0
    done = (self.pio.readBits() & 1) == 1
    if done: success += 1
    else: return 0
    
    self.toggleClock()
    
    self.pio.setBits(self.PHASE_EN)
    if directionUp:
      self.pio.setBits(self.UPDN)
    else:
      self.pio.clearBits(self.UPDN)
    
    self.pio.setBits(self.SCANCLK)
    self.pio.clearBits(self.SCANCLK)
    self.pio.setBits(self.SCANCLK)
    self.pio.clearBits(self.SCANCLK)
    
    self.pio.clearBits(0xFF)
    self.toggleClock()
    
    #time.sleep(0.5)
    
    done = (self.pio.readBits() & 1) == 1
    if done: success += 1
    else: return success
    return success
    
if __name__ == "__main__":
  pll = altpll_phase()
  count = 0
  #while True:
  #for i in range(80 * 10):
  #  count += 1
  #  good = pll.phase_shift()
  #  time.sleep(0.2)
  #  print count
  import sys
  if sys.argv[1] == "up":
    pll.phase_shift(True)
  if sys.argv[1] == "down":
    pll.phase_shift(False)
  
