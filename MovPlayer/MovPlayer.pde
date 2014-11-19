import org.firmata.*;
import cc.arduino.*;
import processing.video.*;
import processing.serial.*;
import java.io.*;

//MOVIE PLAYING AND VIDEO SELECTION
Movie mov;
Movie[] movieObjects;
int firstVideoOnSelectionIndex = 0;
boolean videoSelect; //Are we just selecting the video to play
//ARDUINO
Arduino arduino;
int pressureRating;
boolean buttonState = false; //true for pressed down
// for pausing
long timeWhenPressed = 0;
boolean pressed = false;
boolean movPaused = false;
int IRLed = 9;
int threeWayDown = 3;
int threeWayIn = 4;
int threeWayUp = 5;
long threeWayInPressed = 10000;
//VIDEO PLAYBACK
float playbackSpeed;
float volume = 0.5;
long skipVideosChanged = 0;
long volumeChanged = 0;
boolean skipVideos = false;

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
  int selectedMovie = firstVideoOnSelectionIndex + (int)map(mouseX, 0, width, 0, 4);
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

void keyPressed() {
 if (key == 'n') {
  if (firstVideoOnSelectionIndex+5 < movieObjects.length) {
   firstVideoOnSelectionIndex += 5; 
  }
  drawMovieSelectScreen();
 } 
 if (key == 'p') {
  firstVideoOnSelectionIndex -= 5;
  if (firstVideoOnSelectionIndex < 0) {
   firstVideoOnSelectionIndex = 0; 
  }
  drawMovieSelectScreen(); 
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


   handlePause();
   
  readValues();
  changePlaybackSpeed();
  handleVolumeAndSkip();

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
 int usedWidth = 10;
 int maxNumberOfVideosOnScreen = 5;
 background(0);
 
 for (int i=firstVideoOnSelectionIndex; i < firstVideoOnSelectionIndex + maxNumberOfVideosOnScreen; i++) {
  if (i >= movieObjects.length) {
   break; 
  }
  String[] videoname = splitTokens(movieObjects[i].filename, System.getProperty("file.separator"));
  String title = videoname[videoname.length-1];
  image(movieObjects[i], usedWidth, height/2, width/5, height/5);
  text(title, usedWidth, height/2 + height/3);
  usedWidth += movieObjects[i].width; 
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
    text("video paused " + movPaused, 10, 130);
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

void muteBasedOnPlaybackSpeed(float downLimit, float upLimit) {
  if ( playbackSpeed < downLimit || playbackSpeed > upLimit ) {
     mov.speed(playbackSpeed);  
     mov.volume(0);
  }
  else {
     mov.speed(1); //Normal speed
     mov.volume(volume); // Normal volume
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

void handlePause() {
  
  if (pressureRating >= 800 && pressed == false) {
       pressed = true;
       boolean saveMovPaused = movPaused;
       if(timeWhenPressed + 1000 > System.currentTimeMillis()) {
            if(movPaused) {
                movPaused = false;
            } else {
                movPaused = true;
            }
       }
       if (saveMovPaused != movPaused) {
           // to get pause changed with 2 click
           timeWhenPressed = 0;
       } else {
           // video didnt pause with pressing, save last time when pressed
           timeWhenPressed = System.currentTimeMillis();
       }
  }
  if (pressureRating <= 200 && pressed) {
      pressed = false;
  }
  
  if (movPaused) {
     mov.pause();
  } else { 
     mov.play();
  }
   
}

