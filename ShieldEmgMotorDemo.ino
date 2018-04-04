
/**********************************************************/
/* Demo program for:                                      */
/*    Board: SHIELD-EKG/EMG + Olimexino328                */
/*  Manufacture: OLIMEX                                   */
/*  COPYRIGHT (C) 2012                                    */
/*  Designed by:  Penko Todorov Bozhkov                   */
/*   Module Name:   Sketch                                */
/*   File   Name:   ShieldEkgEmgDemo.ino                  */
/*   Revision:  Rev.A                                     */
/*    -> Added is suppport for all Arduino boards.        */
/*       This code could be recompiled for all of them!   */
/*   Date: 19.12.2012                                     */
/*   Built with Arduino C/C++ Compiler, version: 1.0.3    */
/**********************************************************/
/**********************************************************
Purpose of this programme is to give you an easy way to 
connect Olimexino328 to ElectricGuru(TM), see:
https://www.olimex.com/Products/EEG/OpenEEG/EEG-SMT/resources/ElecGuru40.zip
where you'll be able to observe yours own EKG or EMG signal.
It is based on:
***********************************************************
* ModularEEG firmware for one-way transmission, v0.5.4-p2
* Copyright (c) 2002-2003, Joerg Hansmann, Jim Peters, Andreas Robinson
* License: GNU General Public License (GPL) v2
***********************************************************
For proper communication packet format given below have to be supported:
///////////////////////////////////////////////
////////// Packet Format Version 2 ////////////
///////////////////////////////////////////////
// 17-byte packets are transmitted from Olimexino328 at 256Hz,
// using 1 start bit, 8 data bits, 1 stop bit, no parity, 57600 bits per second.

// Minimial transmission speed is 256Hz * sizeof(Olimexino328_packet) * 10 = 43520 bps.

struct Olimexino328_packet
{
  uint8_t	sync0;		// = 0xa5
  uint8_t	sync1;		// = 0x5a
  uint8_t	version;	// = 2 (packet version)
  uint8_t	count;		// packet counter. Increases by 1 each packet.
  uint16_t	data[6];	// 10-bit sample (= 0 - 1023) in big endian (Motorola) format.
  uint8_t	switches;	// State of PD5 to PD2, in bits 3 to 0.
};
*/
/**********************************************************/
#include <compat/deprecated.h>
#include <FlexiTimer2.h>
#include <SoftwareSerial.h>
//http://www.arduino.cc/playground/Main/FlexiTimer2

#include <AFMotor.h>


// All definitions
#define NUMCHANNELS 6
#define HEADERLEN 4
#define PACKETLEN (NUMCHANNELS * 2 + HEADERLEN + 1)
#define SAMPFREQ 2048                      // ADC sampling rate 2048 Hz
#define TIMER2VAL (1024/(SAMPFREQ))       // Set 256Hz sampling frequency                    
#define LED1  13
#define CAL_SIG 9



//#define TIMEWINDOW (SAMPFREQ/10)    // 2048 Hz * 100 ms = 204 samples


// Global constants and variables
volatile unsigned char TXBuf[PACKETLEN];  //The transmission packet
volatile unsigned char TXIndex;           //Next byte to write in the transmission packet.
volatile unsigned char CurrentCh;         //Current channel being sampled.
volatile unsigned char counter = 0;	  //Additional divider used to generate CAL_SIG
volatile unsigned int ADC_Value = 0;	  //ADC current value
//volatile unsigned int EMG_Value[2];    //EMG current value

//volatile unsigned int buffer1[TIMEWINDOW];
//volatile unsigned int buffer2[TIMEWINDOW];


#define MUSCLE1 1  // pin where MUSCLE1 envelope is
#define MUSCLE2 3  // pin where MUSCLE2 envelope is

#define MOTOR1 3
#define MOTOR2 4
AF_DCMotor motor1(MOTOR1);  
AF_DCMotor motor2(MOTOR2); 

//~~~~~~~~~~
// Functions
//~~~~~~~~~~

/****************************************************/
/*  Function name: Toggle_LED1                      */
/*  Parameters                                      */
/*    Input   :  No	                            */
/*    Output  :  No                                 */
/*    Action: Switches-over LED1.                   */
/****************************************************/
void Toggle_LED1(void){

 if((digitalRead(LED1))==HIGH){ digitalWrite(LED1,LOW); }
 else{ digitalWrite(LED1,HIGH); }
 
}


/****************************************************/
/*  Function name: toggle_GAL_SIG                   */
/*  Parameters                                      */
/*    Input   :  No	                            */
/*    Output  :  No                                 */
/*    Action: Switches-over GAL_SIG.                */
/****************************************************/
void toggle_GAL_SIG(void){
  
 if(digitalRead(CAL_SIG) == HIGH){ digitalWrite(CAL_SIG, LOW); }
 else{ digitalWrite(CAL_SIG, HIGH); }
 
}


/****************************************************/
/*  Function name: setup                            */
/*  Parameters                                      */
/*    Input   :  No	                            */
/*    Output  :  No                                 */
/*    Action: Initializes all peripherals           */
/****************************************************/
void setup() {

 noInterrupts();  // Disable all interrupts before initialization
 
 // LED1
 pinMode(LED1, OUTPUT);  //Setup LED1 direction
 digitalWrite(LED1,LOW); //Setup LED1 state
 pinMode(CAL_SIG, OUTPUT);
 
 //Write packet header and footer
 TXBuf[0] = 0xa5;    //Sync 0
 TXBuf[1] = 0x5a;    //Sync 1
 TXBuf[2] = 2;       //Protocol version
 TXBuf[3] = 0;       //Packet counter
 TXBuf[4] = 0x02;    //CH1 High Byte
 TXBuf[5] = 0x00;    //CH1 Low Byte
 TXBuf[6] = 0x02;    //CH2 High Byte
 TXBuf[7] = 0x00;    //CH2 Low Byte
 TXBuf[8] = 0x02;    //CH3 High Byte
 TXBuf[9] = 0x00;    //CH3 Low Byte
 TXBuf[10] = 0x02;   //CH4 High Byte
 TXBuf[11] = 0x00;   //CH4 Low Byte
 TXBuf[12] = 0x02;   //CH5 High Byte
 TXBuf[13] = 0x00;   //CH5 Low Byte
 TXBuf[14] = 0x02;   //CH6 High Byte
 TXBuf[15] = 0x00;   //CH6 Low Byte 
 TXBuf[2 * NUMCHANNELS + HEADERLEN] =  0x01;	// Switches state

 // Timer2
 // Timer2 is used to setup the analag channels sampling frequency and packet update.
 // Whenever interrupt occures, the current read packet is sent to the PC
 // In addition the CAL_SIG is generated as well, so Timer1 is not required in this case!
 FlexiTimer2::set(TIMER2VAL, Timer2_Overflow_ISR);
 FlexiTimer2::start();
 
 // Serial Port

 //#define RXPIN 10
 //#define RXPIN 11
 //SoftwareSerial bterial(RXPIN, TXPIN); // RX, TX
 
 Serial.begin(57600);
 //Serial.begin(9600); //Set speed to 57600 bps
 
 // Turn on motor(s)
 motor1.setSpeed(0);
 motor1.run(FORWARD);
 motor2.setSpeed(0);
 motor2.run(FORWARD);
 // MCU sleep mode = idle.
 //outb(MCUCR,(inp(MCUCR) | (1<<SE)) & (~(1<<SM0) | ~(1<<SM1) | ~(1<<SM2)));
 
 interrupts();  // Enable all interrupts after initialization has been completed
}

/****************************************************/
/*  Function name: Timer2_Overflow_ISR              */
/*  Parameters                                      */
/*    Input   :  No	                            */
/*    Output  :  No                                 */
/*    Action: Determines ADC sampling frequency.    */
/****************************************************/
void Timer2_Overflow_ISR()
{
  // Toggle LED1 with ADC sampling frequency /2
  Toggle_LED1();
  
  //Read the 6 ADC inputs and store current values in Packet
  for(CurrentCh=0;CurrentCh<6;CurrentCh++){
    ADC_Value = analogRead(CurrentCh);
    TXBuf[((2*CurrentCh) + HEADERLEN)] = ((unsigned char)((ADC_Value & 0xFF00) >> 8));	// Write High Byte
    TXBuf[((2*CurrentCh) + HEADERLEN + 1)] = ((unsigned char)(ADC_Value & 0x00FF));	// Write Low Byte
  
    // Transform Muscle 1  signal into motor speed of motor 1
    if (CurrentCh== MUSCLE1)
      //motor1.setSpeed(ADC_Value/4);
       motor1.setSpeed(ADC_Value/4);// ADC_value is 0-1023, speed value is 0-255

      if (CurrentCh== MUSCLE2)
      //motor1.setSpeed(ADC_Value/4);
       motor2.setSpeed(ADC_Value/4);// ADC_value is 0-1023, speed value is 0-255
      
  }
	 
  // Send Packet
  for(TXIndex=0;TXIndex<17;TXIndex++){
    Serial.write(TXBuf[TXIndex]);
  }
  
  // Increment the packet counter
  TXBuf[3]++;			
  
  // Generate the CAL_SIGnal
  counter++;		// increment the devider counter
  if(counter == 12){	// 250/12/2 = 10.4Hz ->Toggle frequency
    counter = 0;
    toggle_GAL_SIG();	// Generate CAL signal with frequ ~10Hz
  }
}


/****************************************************/
/*  Function name: loop                             */
/*  Parameters                                      */
/*    Input   :  No	                            */
/*    Output  :  No                                 */
/*    Action: Puts MCU into sleep mode.             */
/****************************************************/
void loop() {
  
 __asm__ __volatile__ ("sleep");
 
}
