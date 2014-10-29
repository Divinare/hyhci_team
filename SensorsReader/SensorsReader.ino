#include <sstream>

const int buttonPin = 2;     // Digital pushbutton pin
const int ledPin =  13;      // the number of the LED pin
const int potentiometerPin = A0;

// variables will change:
int buttonState = 0;         // variable for reading the pushbutton status
int potentiometerValue;

void setup() {
   // init serial communication for potentiometer at 9600 bits per second
   Serial.begin(9600);
  
  // init led output for button
  pinMode(ledPin, OUTPUT);     

  pinMode(buttonPin, INPUT);     

}

void loop(){
  readPotentiometerSensorValue();
  readButtonValue();
  printValues();
}

void readPotentiometerSensorValue() {
  potentiometerValue = analogRead(potentiometerPin);
}

void readButtonValue() {
    buttonState = digitalRead(buttonPin);

  // check if the pushbutton is pressed.
  // if it is, the buttonState is HIGH:
  if (buttonState == HIGH) {     
    // turn LED on:    
    digitalWrite(ledPin, HIGH);  
  } 
  else {
    // turn LED off:
    digitalWrite(ledPin, LOW); 
  }
}

void printValues() {
  Serial.println(potentiometerValue);
}

int getPotentiometerValue() {
    return potentiometerValue;
}

int getButtonValue() {
    return buttonState; 
}


