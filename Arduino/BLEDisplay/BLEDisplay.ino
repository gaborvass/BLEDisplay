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
#include <U8g2lib.h>
#include <SPI.h>
#include <Wire.h>

// For UNO, AltSoftSerial library is required, please get it from:
// http://www.pjrc.com/teensy/td_libs_AltSoftSerial.html
#if defined (__AVR_ATmega168__) || defined (__AVR_ATmega328P__)  
  AltSoftSerial BLEMini;  
#else
  #define BLEMini Serial1
#endif

U8G2_SH1106_128X64_NONAME_1_4W_SW_SPI u8g2(U8G2_R0, 10, 9, 12, 11, 13);

// initial Time display is 12:59:45 PM
int hour = 22;
int mins = 6;
int sec = 0;

static uint32_t last_time, now = 0; // RTC

void setup()
{
    u8g2.begin();
    //BLEMini.begin(57600); 
    //Serial.begin(57600);
    now = 1548604043; // read RTC initial value  

}

unsigned char buf[16] = {0};

char displayBuf[16] = {0};

unsigned char len = 0;
unsigned char displayLen = 0;


bool connected = false;

void loop(){
  u8g2.firstPage();
  do {
    char buff[50];
    sprintf(buff, "%02d:%02d:%02d", hour, mins, sec);
    u8g2.setFont(u8g2_font_fub20_tn);
    u8g2.drawStr(10,34,buff);
  } while ( u8g2.nextPage() );
  for ( int i=0 ;i<5 ;i++)// make 5 time 200ms loop, for faster Button response
  {

    while ((now-last_time) < 200) //delay 1000ms
    { 
      now = millis();
    }
    // inner 1000ms loop
    last_time=now; // prepare for next loop 

    /* ---- manage seconds, minutes, hours am/pm overflow ----*/
    if(sec == 60){
      sec = 0;
      mins = mins + 1;
    }
    if(mins == 60)
    {
      mins = 0;
      hour = hour + 1;
    }
    if(hour == 24)
    {
      hour = 0;
    }
  }// end for

  // outer 1000ms loop

  sec = sec + 1; //increment sec. counting
      
  // ---- manage seconds, minutes, hours am/pm overflow ----
  if(sec == 60){
    sec = 0;
    mins = mins + 1;
  }
  if(mins == 60)
  {
    mins = 0;
    hour = hour + 1;
  }
  if(hour == 24)
  {
    hour = 0;
  } 
  // Loop end
  
}
