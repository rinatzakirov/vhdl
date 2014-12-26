from ad9650_spi import ad9650_spi
from stream_to_avalon import StreamToAvalon
from altpll_phase import altpll_phase
import struct, time
import sys

adc = ad9650_spi()
pll = None
if sys.argv[1] == "alter":
  pll = altpll_phase()
dma = StreamToAvalon()

adc.init()
adc.testMode(True)

misPerPhase = [0] * 100
phase = 50
dma.dmaSize = (2 << 16) * 4
min = 99999999
minIndex = -1
lastMinIndex = -1
done = 0
directionUp = True
while True:
  dma.reset()
  dma.singleRun(0)
  #print "SINGLE"
  mismatches = 0
  for i in range(100):
    val1 = struct.unpack("<H", dma.readBuffer(0, i * 4      , 2))[0]
    val2 = struct.unpack("<H", dma.readBuffer(0, i * 4 + 511 * 4, 2))[0]
    #if val1 != val2:
    #  mismatches += 1
    #  #print "val1 = %08X" % val1
    #  #print "val2 = %08X" % val2
    mismatches += abs(val1 - val2)
 
  #if done > 3 and phase == lastMinIndex: break
  
  if mismatches < min:
    min = mismatches
    minIndex = phase
    
  if mismatches == 0 and done != 0: 
    print "found it going %s" % ("up" if directionUp else "down")
    for i in range(4):
      pll.phase_shift(directionUp)
      time.sleep(0.1)
    break
  
  mismatches = (mismatches - 1) / 10000
  misPerPhase[phase] = mismatches
  if phase == 99 or phase == 0:
    directionUp = not directionUp
    done += 1
    #print misPerPhase
    for i in range(100): sys.stdout.write("%03d," % misPerPhase[i])
    print ""
    #time.sleep(0.1)
    print "min %d\t\t%d" % (min, minIndex)
    lastMinIndex = minIndex
    min = 99999999
  
  phase = (phase + 1) if directionUp else (phase - 1)
  if pll != None: pll.phase_shift(directionUp)
  time.sleep(0.02)
  
