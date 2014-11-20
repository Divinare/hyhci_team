import org.firmata.*;
import cc.arduino.*;
import processing.video.*;
import processing.serial.*;
import java.io.*;
import TUIO.*;

TuioProcessing tuioClient;
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
float xBegin;

void setup() {
  size(displayWidth, displayHeight);
  background(0);
  
  initializeVideoLibrary();
  
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  initializePins(); //Set Arduino pins on INPUT, except IR Led Pin is marked as OUTPUT 
  frame.setResizable(true);
  tuioClient  = new TuioProcessing(this);
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
  videoSelectScreen();
 } 
 if (key == 'p') {
  firstVideoOnSelectionIndex -= 5;
  if (firstVideoOnSelectionIndex < 0) {
   firstVideoOnSelectionIndex = 0; 
  }
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
  
    //Kelausviiva
  drawVideoSpeedLine();
  
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
    // current movie is stopped and its position is saved
    float movTime = mov.time();
    Movie currentMov = mov;
    
    // a (new) mov is selected by the user
    //videoSelect = true;
    videoSelectScreen();
    //mov.pause();
    
    
    // if the user didn't pick a new mov, old mov is continued from its current position    
    if (mov.filename.equals(currentMov.filename)) {
        mov = currentMov;
        mov.loop();
        mov.jump(movTime);        
    }
    else {
      currentMov = null;
    }
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

boolean pressureOn() {
  if (pressureRating > 500) {
    return true;
  }
  return false;
}

void drawVideoSpeedLine() {
   ArrayList<TuioCursor> tuioCursorList = tuioClient.getTuioCursorList();
   for (int i=0;i<tuioCursorList.size();i++) {
      TuioCursor tcur = tuioCursorList.get(i);
      ArrayList<TuioPoint> pointList = tcur.getPath();
      
      if (pointList.size()>0) {
        stroke(255,0,0);
        TuioPoint start_point = pointList.get(0);
        for (int j=0;j<pointList.size();j++) {
           TuioPoint end_point = pointList.get(j);
           line(start_point.getScreenX(width),start_point.getScreenY(height),end_point.getScreenX(width),start_point.getScreenY(height));
           //start_point = end_point;
        }
      }
   } 
}

// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {
  xBegin = tobj.getX();
  println("add obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  if (pressureOn()) {
    playbackSpeed = map((0+(tobj.getX()-xBegin)), 0.0, 0.5, 0.1, 3);
    if (playbackSpeed > 3) {
      playbackSpeed = 3; 
    }
    else if (playbackSpeed < -3) {
      playbackSpeed = -3;
    }
  }
  
  println("set obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
          +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  if (!pressureOn()){
    playbackSpeed = 1;
  }
  
  println("del obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}

// --------------------------------------------------------------
// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  xBegin = tcur.getX();
  println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  //playbackSpeed = map(tcur.getX(), 0.0, 1.0, 0.1, 3);
    playbackSpeed = map((0+(tcur.getX()-xBegin)), -0.5, 0.5, -3, 3);
    if (playbackSpeed > 3) {
      playbackSpeed = 3; 
    } else if (playbackSpeed < -3) {
      playbackSpeed = -3;
    }
  
  println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) { 
  playbackSpeed = 1;
  println("del cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+")" + "  " + tcur.getX());
}

// --------------------------------------------------------------
// called when a blob is added to the scene
void addTuioBlob(TuioBlob tblb) {
  println("add blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea());
}

// called when a blob is moved
void updateTuioBlob (TuioBlob tblb) {
  println("set blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+") "+tblb.getX()+" "+tblb.getY()+" "+tblb.getAngle()+" "+tblb.getWidth()+" "+tblb.getHeight()+" "+tblb.getArea()
          +" "+tblb.getMotionSpeed()+" "+tblb.getRotationSpeed()+" "+tblb.getMotionAccel()+" "+tblb.getRotationAccel());
}

// called when a blob is removed from the scene
void removeTuioBlob(TuioBlob tblb) {
  println("del blb "+tblb.getBlobID()+" ("+tblb.getSessionID()+")");
}

// --------------------------------------------------------------
// called at the end of each TUIO frame
void refresh(TuioTime frameTime) { 
  //println("frame #"+frameTime.getFrameID()+" ("+frameTime.getTotalMilliseconds()+")");
}
