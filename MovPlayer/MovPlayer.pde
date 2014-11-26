import org.firmata.*;
import cc.arduino.*;
import processing.video.*;
import processing.serial.*;
import java.io.*;
import TUIO.*;

//PINS
int IRLed = 9;
int pressureSensor = 3;
TuioProcessing tuioClient;
Movie mov;
Movie[] movieObjects;
Arduino arduino;
int pressureRating;
boolean buttonState = false; //true for pressed down
float playbackSpeed;
int threeWayDown = 3;
int threeWayIn = 4;
int threeWayUp = 5;
long threeWayInPressed = 10000;
long skipVideosChanged = 0;
float volume = 0.5;
long volumeChanged = 0;
boolean skipVideos = false;
boolean pausedState = false;
boolean videoSelect; //Are we just selecting the video to play
float xBegin;
int lastTuioEvent;

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

//TODO:
//This needs to be removed after testing that everything works with TUIO
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

   userEvents(); 
  
   image(mov, 0, 0);
  
   fill(255);

   printVideoInfo();
   
   drawVideoSpeedLine();
  }
}

void userEvents() {

  toggleIRLed(arduino.analogRead(pressureSensor));   
  changePlaybackSpeed();
  handleVolumeAndSkip();
   
}

void toggleIRLed(int pinValue) {
  
  pressureRating = pinValue;
  if (pressureRating > 500) {
   arduino.digitalWrite(IRLed, arduino.HIGH); 
  }
  else {
   arduino.digitalWrite(IRLed, arduino.LOW); 
  }
  
}

void changePlaybackSpeed() {
  
  mov.speed(playbackSpeed);
  double speedDownLimit = 0.5;
  double speedUpLimit = 1.3; 
  if ( playbackSpeed < speedDownLimit || playbackSpeed > speedUpLimit ) {  
     mov.volume(0);
  }
  else {
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
    
    text("print coords here, x: y: ", 10, 110);
    
}

void initializePins() {
  for (int i = 0; i <= 53; i++)
  arduino.pinMode(i, Arduino.INPUT);

  //IR Led  
  arduino.pinMode(IRLed, arduino.OUTPUT);  
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
  videoSelect = true;
  mov.stop();
  frame.setSize(displayWidth, displayHeight);
  videoSelectScreen();
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
  if (videoSelect) {
   selectVideo(tobj.getX());
  }
  else {
   if (millis() - lastTuioEvent < 200) {
    togglePause();
   }
   xBegin = tobj.getX();
   lastTuioEvent = millis();
   println("add obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
  }
}

void selectVideo(float selection) {
 int selectedMovie = (int)map(selection, 0, width, 0, movieObjects.length);
 videoSelect = false; 
 mov = new Movie(this, movieObjects[selectedMovie].filename); 
 mov.loop(); 
}

void togglePause() {
 if (pausedState) {
  mov.play();
  pausedState = false;
 } 
 else  {
  mov.pause(); 
  pausedState = true;
 }
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  if (pressureOn()) {
    if (tobj.getX()>xBegin) {
      playbackSpeed = map((0+(tobj.getX()-xBegin)), 0.0, 0.5, 0.1, 3);
      if (playbackSpeed > 3) {
        playbackSpeed = 3; 
      }
    }
    if (tobj.getX()<xBegin) {
      playbackSpeed = map((0+(tobj.getX()-xBegin)), 0.0, -0.5, -0.1, -3);  
      if (playbackSpeed < -3) {    
        playbackSpeed = -3;  
      }
    }
  }
  
  println("set obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
          +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  if (!pressureOn()){
    //mov.volume(1);
    playbackSpeed = 1;
  }
  
  println("del obj "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}

// NOTE! Cursors mainly for testing, obj-methods for actual use with IR-emitter
// --------------------------------------------------------------
// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  xBegin = tcur.getX();
  mov.volume(0);
  println("add cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  if (tcur.getX()>xBegin) {
    playbackSpeed = map((0+(tcur.getX()-xBegin)), 0.0, 0.5, 0.1, 3);
    /*if (playbackSpeed > 3) {
      playbackSpeed = 3; 
    } */
  } else if (tcur.getX()<xBegin) {
    playbackSpeed = map((0+(tcur.getX()-xBegin)), 0.0, -0.5, -0.1, -3);  
    if (playbackSpeed < -3) {    
      playbackSpeed = -3;  
    }
}
  println("set cur "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) { 
  playbackSpeed = 1;
  mov.volume(1);
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
