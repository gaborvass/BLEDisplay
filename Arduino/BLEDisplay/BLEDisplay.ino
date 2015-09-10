/*******************************************
* This example is for Arduino board listed below working with BLEMini,chating with BLE app in ipod etc.
* BLEMini's TX map the RX below and its RX map the TX below
*
* Board       RX      TX
* UNO         PIN8    PIN9  (PINs can be changed in file "document/library/AltSoftSerial/config/known_boards.h")
* MEGA2560    PIN19   PIN18 (actually use the Serial1)
* Leonardo    PIN0    PIN1  (actually use the Serial1)
*******************************************/
#include <Arduino.h>
#include <AltSoftSerial.h>

// For UNO, AltSoftSerial library is required, please get it from:
// http://www.pjrc.com/teensy/td_libs_AltSoftSerial.html
#if defined (__AVR_ATmega168__) || defined (__AVR_ATmega328P__)  
  AltSoftSerial BLEMini;  
#else
  #define BLEMini Serial1
#endif

void setup()
{
    setupDisplay();
    setMessageToDisplay("labda");
    BLEMini.begin(57600); 
    //Serial.begin(57600);
}

unsigned char buf[16] = {0};

char displayBuf[16] = {0};

unsigned char len = 0;
unsigned char displayLen = 0;

bool connected = false;

void loop(){
  loopDisplay();
  while ( BLEMini.available()){
    connected = true;
     byte data = BLEMini.read();
     char c = data;
    if (c != 0x78){
      if (displayLen < 16){
        displayBuf[displayLen++] = c;
      }
    }else{
      setMessageToDisplay(displayBuf);
      displayLen = 0;
    }
  }  
}

