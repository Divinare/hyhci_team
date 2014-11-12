import org.firmata.*;
import cc.arduino.*;

import processing.video.*;
import processing.serial.*;

Movie mov;
Arduino arduino;
int pressureRating;
boolean buttonState = false; //true for pressed down
float playbackSpeed;
int framesBeforeGettingButtonState = 5; //So that we avoid reading the button state every frame

void setup() {
  size(636, 360);
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  for (int i = 0; i <= 53; i++)
    arduino.pinMode(i, Arduino.INPUT);

  //IR Led  
  arduino.pinMode(9, arduino.OUTPUT);
  
  background(0);
  mov = new Movie(this, "girlAVI.mov");
  mov.loop(); 
}

void movieEvent(Movie movie) {
  mov.read(); 
  
}

void draw() {
  if (framesBeforeGettingButtonState == 0) {
    readButtonState();  
  }
  else {
    framesBeforeGettingButtonState--; 
  }
  
  readValues();
  image(mov, 0, 0);
 
  mov.speed(playbackSpeed);
  
  if (buttonState) {
    mov.pause();
  }
  else { 
    mov.play();
  }
  
  if (pressureRating > 500 ) {
    arduino.digitalWrite(9, arduino.HIGH);
  }
  
  fill(255);
  text("TITLE: " + mov.filename + "\n SPEED: " + nfc(playbackSpeed, 2) + "X" + "\n Pressure reading: " + arduino.analogRead(3), 10, 30);
  
}  

void readValues() {
 pressureRating = arduino.analogRead(3);
 playbackSpeed = map(arduino.analogRead(0), 0, 1023, 0.1, 3);
 
 
}

void readButtonState() { 
 if (arduino.digitalRead(7) == arduino.HIGH) {
  if (buttonState) {
    buttonState = false;
  }
  else {
    buttonState = true; 
  }
 }
}
