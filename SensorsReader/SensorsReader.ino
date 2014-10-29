const int buttonPin = 1;     // Digital pushbutton pin
const int ledPin =  13;      // the number of the LED pin

// variables will change:
int buttonState = 0;         // variable for reading the pushbutton status
int potentiometerValue = 0;

void setup() {
  
   // init serial communication for potentiometer at 9600 bits per second
   Serial.begin(9600);
  
  // init led output for button
  pinMode(ledPin, OUTPUT);     
  // init led input for button 
  pinMode(buttonPin, INPUT);     
}

void loop(){
  readPotentiometerSensorValue()
  readButtonValue();
  printValues();
}

void readPotentiometerSensorValue() {
      potentiometerValue = analogRead(A0);
  delay(1); 
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
  Serial.println("potentiometer value: " + sensorValue);
}

int getPotentiometerValue() {
    return potentiometerValue;
}

int getButtonValue() {
    return buttonState; 
}


