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
int threeWayDown = 3;
int threeWayIn = 4;
int threeWayUp = 5;
long threeWayInPressed = 10000;
long skipVideosChanged = System.currentTimeMillis();
float volume = 0.5;
String[] videos;
boolean skipVideos = false; 

void setup() {
  size(636, 360);
  background(0);
  
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  
  initializePins(); //Set Arduino pins on INPUT, except IR Led Pin is marked as OUTPUT
  
  background(0);
  mov = new Movie(this, "otter.mov");
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
 
   mov.volume(volume);
  if ( playbackSpeed < 0.5 || playbackSpeed > 1.3 ) {
    mov.speed(playbackSpeed);  
   // mov.volume(0);
  }
  else {
    mov.speed(1); //Normal speed
   // mov.volume(1); //Normal volume 
  }
  handleVolumeAndSkip();

  
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

void handleVolumeAndSkip() {
  
  // If over 5 seconds has passed from pressing threeWayIn button, set skipVideos false
  if(skipVideos && skipVideosChanged + 5000 < System.currentTimeMillis()) {
     skipVideos = false; 
  }
  
  boolean skipChangeAllowed = true;
  // to prevent user from holding down threeWayIn button
  if (skipVideosChanged + 250 > System.currentTimeMillis()) {
     skipChangeAllowed = false;
  }
  if (arduino.digitalRead(threeWayIn) == arduino.LOW && skipVideos) {
    if(skipChangeAllowed) {
        skipVideos = false;
    }
     skipVideosChanged = System.currentTimeMillis();
  }
  else if (arduino.digitalRead(threeWayIn) == arduino.LOW) {
    if(skipChangeAllowed) {
        skipVideos = true;
    }
    skipVideosChanged = System.currentTimeMillis();
  }
  
   if (skipVideos) {
     handleSkip();
   } else {
      handleVolume(); 
   }
 
  if (arduino.digitalRead(threeWayIn) == arduino.LOW) {
        threeWayInPressed = System.currentTimeMillis();
  }
}

void handleSkip() {
  text("Skipping video ", 10, 90);
}

void handleVolume() {
   text("Volume " + volume, 10, 70);
   if (arduino.digitalRead(threeWayDown) == arduino.LOW) {
      if (volume+0.01 < 1) {
          volume += 0.01;
          
      } else {
         volume = 1; 
      }
      
  }
  if (arduino.digitalRead(threeWayUp) == arduino.LOW) {
      if (volume-0.01 > 0) {
          volume -= 0.01;
      } else {
          volume = 0; 
      }
   } 
}

