import pyqtgraph as pg
import numpy as np

def drawFft(filename, side):
  data = np.fromfile("dump.dat", dtype="uint16").astype(float)
  data = data[side::2]
  #data = data[:-1]
  #data = data[:8192]
  #pg.plot(data)
  #return
  print "raw"
  print np.min(data)
  print np.max(data)
  data -= np.average(data)
  data = data / float(2**15)
  
  data.astype('float32').tofile(filename + ".f32")

  #pg.plot(data)
  #data = data[:1024]

  def plotPower(fftData, N, C, F):
    v = np.absolute(np.fft.fftshift(fftData) / N)
    sqV = v * v
    p = sqV / 50.0 * 1000 * 2 # * 2 is made to take care of the fact that FFT is two-sided
    pdBm = np.log10(p) * 10
    print "max = %f" % np.max(pdBm)
    print "avg = %f" % np.average(pdBm)
    #pg.plot(np.linspace(-Fs/2, Fs/2 - Fs / N, N), pdBm)
    s1 = N/2 + N * F / Fs - N * 1000000 / Fs
    s2 = N/2 + N * F / Fs + N * 1000000 / Fs
    pg.plot(pdBm[int(s1):int(s2)])
    #854839

  N = data.shape[0]
  #Fs = 105 * 1000 * 1000
  Fs = 105 * 1000 * 1000
  #F = 10.7 * 1000 * 1000
  F = 10.7 * 1000 * 1000
  #data = np.sin((N - 1) * (F / Fs) * np.linspace(0, np.pi * 2, N))
  print "scale"
  print np.min(data)
  print np.max(data)
  print np.log10(pow((np.max(data) - np.min(data)) * np.sqrt(2.0) / 2.0, 2.0) / 50 * 1000) * 10

  z = np.linspace(0, 2 * np.pi, N)
  cos = np.cos
  window = 1 - 1.96760033 * cos(z) + 1.57983607 * cos(2 * z) - 0.81123644 * cos(3 * z) + 0.22583558 * cos(4 * z) - 0.02773848 * cos(5 * z) + 0.00090360 * cos(6 * z)
  #pg.plot(window)
  #window = np.blackman(N)
  window /= np.sum(window) / N

  plotPower(np.fft.fft(window * data), N, Fs, F)
  #pg.plot(data)

  subFft = 256
  window = np.blackman(256)
  sum = np.array(np.fft.fft(data[0:subFft]))
  for i in range(1, N / subFft):
    sum += np.fft.fft(window * data[(i * subFft):((i + 1) * subFft)])
  #plotPower(sum, subFft, Fs)
  
drawFft("more1", 0)
drawFft("more1", 1)
#drawFft("more2.bin")
  
from pyqtgraph.Qt import QtCore, QtGui
QtGui.QApplication.instance().exec_()