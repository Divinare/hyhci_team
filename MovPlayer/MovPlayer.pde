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
int IRLed = 9;
String[] videos;

void setup() {
  size(636, 360);
  background(0);
  
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  initializePins(); //Set Arduino pins on INPUT, except IR Led Pin is marked as OUTPUT
  
  mov = new Movie(this, "girlAVI.mov");
  mov.loop(); 
  frame.setResizable(true);
}

void movieEvent(Movie movie) {
  mov.read(); 
  
}

void draw() {
  frame.setSize(mov.width, mov.height);
  if (framesBeforeGettingButtonState == 0) {
    readButtonState();  
    framesBeforeGettingButtonState = 5;
  }
  else {
    framesBeforeGettingButtonState--; 
  }
  
  readValues();
  image(mov, 0, 0);
 
 
  if ( playbackSpeed < 0.5 || playbackSpeed > 1.3 ) {
    mov.speed(playbackSpeed);  
    mov.volume(0);
  }
  else {
    mov.speed(1); //Normal speed
    mov.volume(1); //Normal volume 
  }
  
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
  text("TITLE: " + mov.filename + "\n SPEED: " + nfc(playbackSpeed, 2) + "X" + "\n Pressure reading: " + pressureRating, 10, 30);
  
}

void initializePins() {
  for (int i = 0; i <= 53; i++)
  arduino.pinMode(i, Arduino.INPUT);

  //IR Led  
  arduino.pinMode(IRLed, arduino.OUTPUT);  
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
