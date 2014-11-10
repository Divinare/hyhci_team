import org.firmata.*;
import cc.arduino.*;

import processing.video.*;
import processing.serial.*;

Movie mov;
Arduino arduino;
boolean isPlaying = true;

void setup() {
  size(636, 360);
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  for (int i = 0; i <= 53; i++)
    arduino.pinMode(i, Arduino.INPUT);
  
  background(0);
  mov = new Movie(this, "girlAVI.mov");
  mov.loop(); 
}

void movieEvent(Movie movie) {
  mov.read(); 
  
}

void draw() {    
  image(mov, 0, 0);
  float playbackSpeed = map(arduino.analogRead(0), 0, 1023, 0.1, 3);
  mov.speed(playbackSpeed);
  
  if (arduino.digitalRead(7) == Arduino.HIGH) {
    mov.pause();
  }
  else { 
    mov.play();
  }
  
  fill(255);
  text("TITLE: " + mov.filename + "\n SPEED: " + nfc(playbackSpeed, 2) + "X", 10, 30); 
}  
