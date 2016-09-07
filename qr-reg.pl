#!/usr/bin/python
#################################################
#
# BSidesDC QR Code Reader Registration System
# Using a Raspberry Pi
#
# Version
# -----------------------------------------------
# 1.0	jdg	Initial Version (2016-09)
#
# Authors
# -----------------------------------------------
# jdg	Jim Gilsinn
#
#################################################

import sys, os, time, subprocess, numbers, logging
import RPi.GPIO as GPIO
import pygame, qrtools
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from watchdog.events import DirModifiedEvent
from watchdog.events import LoggingEventHandler

#------------------------------------------------
# Usage Message
#------------------------------------------------
usage = "\nUsage:\tqr-reg.py [demo_file]\n\n"
usage += "Process QR codes generated by the BSidesDC\n"
usage += "registration system.\n\n"
usage += "demo_file\t(optional) Process and display\n"
usage += "\t\tthe desired demonstration file\n"

#------------------------------------------------
# Assign Values for LEDs
#------------------------------------------------
led_status_blue_gpio = 20
led_status_green_gpio = 21
led_code_red_gpio = 16
led_code_green_gpio = 12
led_on = GPIO.LOW
led_off = GPIO.HIGH
blink_time = 0.5

#------------------------------------------------
# Assign Values for QR Decoder
#------------------------------------------------
window_title = "BSidesDC Registration"
image_path = "/var/lib/motion"
cycle_sleep_time = 0.5
window_size = (640,480)
image_size = (640,360)
image_offset = (0,120)
font_color = (255,255,0)
background_color = (0,0,0)
font_type = "monospace"
font_size = 15
qr_text_offset = (50,25)
new_image_file = False
img_file = ""

#------------------------------------------------
# Check For a Demo Test File
#------------------------------------------------
demo_file = ""
if len(sys.argv) == 1:
  print "Live Mode"
elif len(sys.argv) == 2:
#  print "Demo Mode"
  if not os.path.exists(sys.argv[1]):
    print "ERROR: Demo file not accessible"
    exit()
  else:
    demo_file = sys.argv[1]
    print "Demo File = " + demo_file
else:
  print usage
  exit()

#------------------------------------------------
# Function - Clear Status LED
#------------------------------------------------
def ClearStatusLED():
  GPIO.output(led_status_blue_gpio, led_off)
  GPIO.output(led_status_green_gpio, led_off)

#------------------------------------------------
# Function - Clear Code LED
#------------------------------------------------
def ClearCodeLED():
  GPIO.output(led_code_red_gpio, led_off)
  GPIO.output(led_code_green_gpio, led_off)

#------------------------------------------------
# Function - Clear All LEDs
#------------------------------------------------
def ClearAllLED():
  ClearStatusLED()
  ClearCodeLED()

#------------------------------------------------
# Function - Initialize GPIO
#------------------------------------------------
def InitializeGPIO():
  GPIO.setmode(GPIO.BCM)
  GPIO.setup(led_status_blue_gpio, GPIO.OUT)
  GPIO.setup(led_status_green_gpio, GPIO.OUT)
  GPIO.setup(led_code_red_gpio, GPIO.OUT)
  GPIO.setup(led_code_green_gpio, GPIO.OUT)
  ClearAllLED()

#------------------------------------------------
# Function - Flash Main Status LED Blue
#------------------------------------------------
def FlashStatusLEDBlue(flash_time):
  GPIO.output(led_status_green_gpio,led_off)
  GPIO.output(led_status_blue_gpio,led_on)
  time.sleep(flash_time)
  GPIO.output(led_status_blue_gpio,led_off)
  time.sleep(flash_time)

#------------------------------------------------
# Function - Check That Motion Is Started
#------------------------------------------------
def CheckMotionStarted():
  motion_started = False
  while (motion_started == False):
    FlashStatusLEDBlue(blink_time)
    proc = subprocess.Popen(["pgrep","motion"],stdout=subprocess.PIPE)
    proc_out = proc.stdout.readline().strip()
    if proc_out != "":
      motion_started = True
      print "Camera Motion Detection Started."
    else:
      print "Waiting for Camera Motion Detection to Start..."

#------------------------------------------------
# Class - New Image Event Handler
#------------------------------------------------
class NewFileEventHandler(PatternMatchingEventHandler):
  patterns = ["*.jpg", "*.jpeg"]

  def process(self, event):
    """
    event.event_type 
      'modified' | 'created' | 'moved' | 'deleted'
    event.is_directory
       True | False
    event.src_path
       path/to/observed/file
    """
#    print event.src_path, event.event_type
    global new_image_file
    new_image_file = True
    global img_file
    img_file = event.src_path

#  def on_modified(self, event):
#    self.process(event)

  def on_created(self, event):
    self.process(event)

#------------------------------------------------
# Main Program Loop
#------------------------------------------------
try:
  InitializeGPIO()
  CheckMotionStarted()
  GPIO.output(led_status_blue_gpio,led_on)

  #------------------------------------------------
  # Initialize Output Window
  #------------------------------------------------
  pygame.init()
  window = pygame.display.set_mode(window_size)
  pygame.display.set_caption(window_title)

  while True:
    #------------------------------------------------
    # Add Image to Window
    #------------------------------------------------
    pygame.draw.rect(window,background_color,(0,0,640,480))
    if demo_file != "":
      img_file = demo_file
    else:
      # Kludge to test right now with the demo file
      img_file = "test1.jpg"

      observer = Observer()
      observer.schedule(NewFileEventHandler(), path=image_path)
      observer.start()
      while new_image_file == False:
        time.sleep(cycle_sleep_time)
      observer.stop()
      observer.join()
      new_image_file = False
#      print img_file

    img = pygame.image.load(img_file)
    img = pygame.transform.scale(img,image_size)
    window.blit(img,image_offset)

    #------------------------------------------------
    # Parse QR Code
    #------------------------------------------------
    GPIO.output(led_status_green_gpio,led_on)
    qr = qrtools.QR()
    qr.decode(img_file)
    if qr.decode():
      qr_code = qr.data_to_string()
      GPIO.output(led_code_green_gpio,led_on)
      GPIO.output(led_code_red_gpio,led_off)
    else:
      qr_code = "Invalid!"
      GPIO.output(led_code_green_gpio,led_off)
      GPIO.output(led_code_red_gpio,led_on)
    GPIO.output(led_status_green_gpio,led_off)

    #------------------------------------------------
    # Priont QR Code in Window
    #------------------------------------------------
    myfont = pygame.font.SysFont(font_type,font_size)
    label = myfont.render(qr_code, 1, font_color)
    window.blit(label,qr_text_offset)

    #------------------------------------------------
    # Update Window
    #------------------------------------------------
    pygame.display.flip()

    #------------------------------------------------
    # Delay Before Next Running
    #------------------------------------------------
    time.sleep(cycle_sleep_time)
    ClearCodeLED()

#------------------------------------------------
# Cleanup and Exit
#------------------------------------------------
finally:
  pygame.quit()
  GPIO.cleanup()
