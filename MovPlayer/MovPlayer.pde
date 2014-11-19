import org.firmata.*;
import cc.arduino.*;
import processing.video.*;
import processing.serial.*;
import java.io.*;

Movie mov;
Movie[] movieObjects;
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
long skipVideosChanged = 0;
float volume = 0.5;
long volumeChanged = 0;
boolean skipVideos = false;
boolean videoSelect; //Are we just selecting the video to play

void setup() {
  size(displayWidth, displayHeight);
  background(0);
  
  initializeVideoLibrary();
  
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  initializePins(); //Set Arduino pins on INPUT, except IR Led Pin is marked as OUTPUT 
  frame.setResizable(true);
}

/*
* Get all the video files in sketch data folder, get a frame at 3 seconds from video start
*/
void initializeVideoLibrary() {
  
  videoSelect = true;
  File dir = new File(dataPath(""));
  File[] videos = dir.listFiles(new FileFilter() {
   public boolean accept(File video) {
    return video.getName().endsWith(".mov");
   } 
  });
  
  movieObjects = new Movie[videos.length];
  for (int i=0; i < videos.length; i++) {
   movieObjects[i] = new Movie(this, videos[i].getAbsolutePath());
   movieObjects[i].play();
   movieObjects[i].volume(0);
   movieObjects[i].jump(3);
   movieObjects[i].volume(volume);
   movieObjects[i].pause();
  }
  
}

void mousePressed() {
 if (videoSelect) {
  int selectedMovie = (int)map(mouseX, 0, width, 0, movieObjects.length);
  videoSelect = false; 
  mov = new Movie(this, movieObjects[selectedMovie].filename); 
  mov.loop();
 }
 else
 {
  videoSelect = true;
  mov.stop();
  frame.setSize(displayWidth, displayHeight);
  videoSelectScreen(); 
 }
}

void movieEvent(Movie movie) {
  movie.read();   
}

void draw() {
  if (videoSelect) {
   videoSelectScreen(); 
  }
  else {
   frame.setSize(mov.width, mov.height);

   handleInputs(); 
  
   image(mov, 0, 0);
  
   fill(255);

   printVideoInfo();
  }
}

void handleInputs() {

  readValues();
  changePlaybackSpeed();
  handleVolumeAndSkip();
  if (pressureRating > 500 ) {
     arduino.digitalWrite(9, arduino.HIGH);
   }
   
}

void changePlaybackSpeed() {
  double speedDownLimit = 0.5;
  double speedUpLimit = 1.3; 
  if ( playbackSpeed < speedDownLimit || playbackSpeed > speedUpLimit ) {
     mov.speed(playbackSpeed);  
     mov.volume(0);
  }
  else {
     mov.speed(1); //Normal speed
     mov.volume(volume); // Normal volume
  }
}

void videoSelectScreen() {
 int usedWidth = 0;
 for (int i=0; i < movieObjects.length; i++) {
  String[] file = splitTokens(movieObjects[i].filename, System.getProperty("file.separator"));
  String title = file[file.length-1];
  image(movieObjects[i], usedWidth, height/2, width/5, height/5);
  text(title, usedWidth, height/2 + height/3);
  usedWidth += width/movieObjects.length;
 } 
}

void printVideoInfo() {
  text("TITLE: " + mov.filename + "\n SPEED: " + nfc(playbackSpeed, 2) + "X" + "\n Pressure reading: " + pressureRating, 10, 30);
    
    if (volumeChanged + 2000 > System.currentTimeMillis()) {
        text("Volume " + volume, 10, 70);
    }
    
    if (skipVideos) {
        text("Skipping video (not implemented yet)", 10, 90);
    }
    text("print coords here, x: y: ", 10, 110);
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
    // to be implemented
    //bootstrap = true;
    //text("lol", 100, 100);
}

void handleVolume() {
  
   if (arduino.digitalRead(threeWayDown) == arduino.LOW) {
      volumeChanged = System.currentTimeMillis();
      if (volume+0.01 < 1) {
          volume += 0.01;
          
      } else {
         volume = 1; 
      }
      
  }
  if (arduino.digitalRead(threeWayUp) == arduino.LOW) {
      volumeChanged = System.currentTimeMillis();
      if (volume-0.01 > 0) {
          volume -= 0.01;
      } else {
          volume = 0; 
      }
   } 
}

