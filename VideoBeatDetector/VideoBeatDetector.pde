/* Records image fx triggered by pd patch, as well as pd audio 
 v1.0
 */

import oscP5.*;
import netP5.*;
import processing.video.*;

// OSC Settings
OscP5 oscP5;
OscP5 oscAudio;
NetAddress myRemoteLocation;
NetAddress audioLocation;
int jitterOscMsg = 0;
int desaturateOscMsg = 0;
int noizeOscMsg = 0;
int staticOscMsg = 0;

// FX Settings
boolean jitterActive = false;
boolean recording = false;
float zoff = 0.0;
float increment = 0.01;
float zincrement = 0.02;

// Key Activation
boolean jitterON = false; 
boolean desaturateON = false;
boolean noizeON = false;
boolean staticON = false;

// Image Settings
PImage img;
int offsetX = 0;
int offsetY = 0;

int seed = 3; // 2x max rate of change
int dx = int(random(seed)-seed/2);

int dy = int(random(seed)-seed/2);
int frames = 10;

Movie mov;
color movColors[];
color pointColors[];

//control settings
PWindow win;
ArrayList<Movie> queue;
PApplet ref = this;

public void settings() {
  size(640, 360);
  //fullScreen();
}

void setup() {
  background(0);
  queue = new ArrayList<Movie>();
  
  oscP5 = new OscP5(this, 12000);
  oscAudio = new OscP5(this, 9001);

  myRemoteLocation = new NetAddress("127.0.0.1", 12000);
  audioLocation = new NetAddress("127.0.0.1", 9001);

  movColors = new color[width * height];
  
  win = new PWindow();
}

void draw() { 
  if (mov != null) 
    image(mov, 0, 0);  // Display at full opacity
 
  if (jitterON)
    jitter();

  if (desaturateON)
    desaturate();
  else
    tint(255);

  if (noizeON)
    noize();

  if (staticON) 
    stat();

  display();
  record();
}

void oscEvent(OscMessage theOscMessage) {

  if (theOscMessage.checkAddrPattern("/jitter")==true) {
    if (theOscMessage.checkTypetag("i")) {

      jitterOscMsg = theOscMessage.get(0).intValue(); 
      //println("jitter: "+jitterOscMsg);
      return;
    }
  } 

  if (theOscMessage.checkAddrPattern("/desaturate")==true) {
    if (theOscMessage.checkTypetag("i")) {

      desaturateOscMsg = theOscMessage.get(0).intValue(); 
      //println("desaturate: "+desaturateOscMsg);
      return;
    }
  } 

  if (theOscMessage.checkAddrPattern("/static")==true) {
    if (theOscMessage.checkTypetag("i")) {

      staticOscMsg = theOscMessage.get(0).intValue(); 
      //println("static: "+staticOscMsg);
      return;
    }
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    recording = !recording;
  }

  if (key == 'j' || key == 'J') {
    jitterON = !jitterON;

    //Test
    if (jitterON) {
      println("jitter ON");
    } else {
      println("jitter OFF");
    }
  }

  if (key == 'd' || key == 'D') {
    desaturateON = !desaturateON;

    //Test
    if (desaturateON) {
      println("desaturate ON");
      colorMode(HSB);
    } else {
      println("desaturate OFF");
      colorMode(RGB);
    }
  }

  if (key == 'n' || key == 'N') {
    noizeON = !noizeON;

    //Test
    if (noizeON) {
      println("noize ON");
    } else {
      println("noize OFF");
    }
  }

  if (key == 's' || key == 'S') {
    staticON = !staticON;

    //Test
    if (staticON) {
      println("static ON");
    } else {
      println("static OFF");
    }
  }
}

void movieEvent (Movie m) {
  m.read();
}

void jitter() {
  if (jitterActive) {
    dx = int(random(seed)-seed/2);  
    dy = int(random(seed)-seed/2);
    jitterActive = false;  
    offsetX = 0;
    offsetY = 0;
  }

  if (!jitterActive && jitterOscMsg == 1) {
    jitterActive = true;
    offsetX += dx * 15;
    offsetY += dy * 15;
  }

  tint(255, 70);
  image(mov, offsetX, offsetY);
}

void desaturate() {
  if (desaturateOscMsg == 1) {
    noize();
    colorMode(HSB);

    //filter(POSTERIZE, 4);
    //filter(DILATE);
  }
}

void noize() {

  loadPixels();

  float xoff = 0.0; // Start xoff at 0
  //float detail = map(mouseX, 0, width, 0.1, 0.6);
  //noiseDetail(8, detail);

  // For every x,y coordinate in a 2D space, calculate a noise value and produce a brightness value
  for (int x = 0; x < width; x++) {
    xoff += increment;   // Increment xoff 
    float yoff = 0.0;   // For every xoff, start yoff at 0
    for (int y = 0; y < height; y++) {
      yoff += increment; // Increment yoff

      // Calculate noise and scale by 255
      //float bright = noise(xoff, yoff, zoff) * 255;
      float dark = noise(xoff, yoff, zoff);
      float bright = 1/dark;
      // Try using this line instead
      //float bright = random(0,255);

      color newColor = mov.get(x, y);
      float rValue = red(newColor);
      float gValue = green(newColor);
      float bValue = blue(newColor);

      pixels[x+y*width] = color(rValue*bright, gValue*bright, bValue*bright);
    }
  }

  updatePixels();

  zoff += zincrement; // Increment zoff
}

void stat() {
  if (staticOscMsg == 1) {
    loadPixels();

    boolean previousPixelGlitched = false;

    // random color 
    // 0-255, red, green, blue, alpha
    color randomColor = color(random(255), random(255), random(255), 255);

    // for each column of pixels
    for (int x = 0; x < mov.width; x++) {

      // for each row of pixels
      for (int y = 0; y < mov.height; y++) {

        // 25% chance to glitch this pixels, a second 80% chance if the previous pixel was glitched
        if (random(100) < 25 || (previousPixelGlitched == true && random(100) < 80))
        {
          previousPixelGlitched = true;

          // get the color for the pixel at coordinates x/y
          color pixelColor = mov.pixels[y + x * mov.height];

          // percentage to mix
          float mixPercentage = .5 + random(50)/100;

          // mix colors by random percentage of new random color
          mov.pixels[y + x * mov.height] =  lerpColor(pixelColor, randomColor, mixPercentage);
        } else
        {
          // didn't glitch this pixel
          previousPixelGlitched = false;

          // choose a new random mix color
          // 0-255, red, green, blue, alpha
          randomColor = color(random(255), random(255), random(255), 255);
        }
      }
    }

    updatePixels();
  }
}

void display() {
  //tint(255, 127);  // Display at half opacity
  //image(mov, 0, 0);
}

void record() {

  OscMessage recordAudio = new OscMessage("/recordAudio");

  if (recording) {
    saveFrame("output/beat_####.png");
    fill(255, 0, 0);

    recordAudio.add(1);
    oscP5.send(recordAudio, audioLocation);
  } else {
    fill(192, 192, 192);

    recordAudio.add(0);
    oscP5.send(recordAudio, audioLocation);
  }

  ellipse(15, 15, 20, 20);
}

void mousePressed() {
  println("mousePressed in primary window");
}  

public class PWindow extends PApplet {
  ArrayList<track> trackList;
  trackEditButton trackEdit;
  playButton play;
  int trackLength = 3;
  PFont mono;
  boolean buttonOver = false;
  int trackSelected = -1;
  int trackHighlighted = -1;
  int trackEdited = -1;
  boolean playing = false;
  
  
  PWindow() {
    super();
    PApplet.runSketch(new String[] {this.getClass().getSimpleName()}, this);
    println("contextual TESTING: " + ref);
  }

  void settings() {
    size(400, 300);
  }

  void setup() {
    background(150);
    trackList = new ArrayList<track>();
    trackList.add(new track(height/6, width, " ", 0));
    trackList.add(new track(height/2, width, " ", 1));
    trackList.add(new track((5*height)/6, width, " ", 2));
    mono = createFont("BodoniMT-Bold-48.vlw", 16);
    
    trackEdit = new trackEditButton(width/8,(5*height)/6);
    play = new playButton(width/8,height/6); 
  }

  void draw() {
    trackHighlighted = update();
    
    for (int i = 0; i < trackLength; i++) {
        track t = trackList.get(i);
        t.display();
        t.tChange.display();
    }
    trackEdit.display();
    play.display();
  }

  void mousePressed() {
    //println("mousePressed in secondary window");
    
    if (buttonOver && trackList.get(trackHighlighted).populated) {
      trackSelected = trackHighlighted;
      println("trackSelected: " + trackSelected);
      mov = queue.get(trackSelected);
      //println(mov.filename);
      println(mov.duration());
    }
    
    //track edit button
    if (trackEdit.highlighted) {
      
      if (!trackEdit.selected) {
        trackEdit.selected = true;
        editTracks();
      }
      else {
        trackEdit.selected = false;
        background(150);
        
        for (int i = 0; i < win.trackLength; i++) {
          track t = win.trackList.get(i);
          t.tChange.show = false;
        }
      }
    }
    
    // play button
    if (play.highlighted && trackSelected != -1 && !queue.isEmpty()) {
      if (!play.selected) 
        play.selected = true;
      else    
        play.selected = false;
        
      playTracks();
    }
    
    // track change button
    for (int i = 0; i < win.trackLength; i++) {
      track t = win.trackList.get(i);
      if (t.tChange.highlighted) {
        
        if (!t.tChange.selected) {
          t.tChange.selected = true;
          trackEdited = i;
          selectInput("Select a video:", "fileSelected");
          //t.tChange.selected = false;
        }
      }
    }
    
  }
  
  void fileSelected(File selection) {
    if (selection == null) {
      println("Window was closed or the user hit cancel. ");
    }
    else {
      
      String path = selection.getAbsolutePath();
      String fileName = selection.getName();
      println("User selected " + path);
      queue.add(win.trackEdited, new Movie(ref, path));
      println("trackEdited : " + win.trackEdited);
      println(selection.getName());
      track t = win.trackList.get(win.trackEdited);
      t.tName = fileName;   
      t.tChange.selected = false;
      t.populated = true;
    }
  }
}

class track { 
  int tWidth, tHeight, xPos, yPos;
  String tName;
  int tNum;
  color c, cHighlight, cSelect;
  boolean highlighted = false;
  boolean populated = false;
  trackChangeButton tChange;
  
  track(int y, int winWidth, String name, int num) {
    tWidth = winWidth/2;
    tHeight = 40;
    xPos = winWidth/2;
    yPos = y;
    tName = name;
    tNum = num;
    c = color(112, 142, 119);
    cHighlight = color(92, 122, 99);
    cSelect = color(202, 232, 209);
    tChange = new trackChangeButton(winWidth-40, yPos);
  }
  
  void display() {
    win.noStroke();
    
    if (tNum == win.trackSelected)
      win.fill(cSelect);
    else if (win.buttonOver && tNum == win.trackHighlighted)
      win.fill(cHighlight);
    else
      win.fill(c);
      
    win.rectMode(CENTER);
    win.rect(xPos, yPos, tWidth, tHeight, 20);
    win.fill(0);
    win.textFont(win.mono);
    win.text(tName, xPos/2+10, yPos + 5);
  }
}

class trackEditButton {
  int r, xPos, yPos; 
  color c, cHighlight, cSelect;
  boolean highlighted, selected = false;
  int rectW1 = 5;
  int rectH1 = r/2;
  int rectW2 = r/2;
  int rectH2 = 5;
  
  trackEditButton(int x, int y) {
    r = 40;
    xPos = x;
    yPos = y;
    c = color(82, 112, 89);
    cHighlight = color(62, 92, 69);
    cSelect = color(172, 202, 179);
  }
  
  void display() {
    win.noStroke();
    
    if (selected)
      win.fill(cSelect);
    else if (highlighted)
      win.fill(cHighlight);
    else
      win.fill(c);
    
    win.ellipseMode(CENTER);
    win.ellipse(xPos, yPos, r, r);
    win.fill(0);
    win.rectMode(CENTER);
    win.rect(xPos, yPos, 5, 2*r/3, 1);
    win.rect(xPos, yPos, 2*r/3, 5, 1);
  }
  
}

class trackChangeButton {
  int r, xPos, yPos; 
  color c, cHighlight, cSelect;
  boolean highlighted, selected = false;
  boolean show = false;
  
  trackChangeButton(int x, int y) {
    r = 40;
    xPos = x;
    yPos = y;
    c = color(210, 180, 25);
    cHighlight = color(190, 160, 5);
    cSelect = color(250, 220, 65);
  }
  
  void display() {
    win.noStroke();
    
    if(show) {
      if (selected)
        win.fill(cSelect);
      else if (highlighted)
        win.fill(cHighlight);
      else
        win.fill(c); 
    
      win.ellipseMode(CENTER);
      win.ellipse(xPos, yPos, r, r);
      win.fill(0);
      win.rect(xPos, yPos, 2*r/3, 5, 1);
    }
  }
}

class playButton {
  int r, xPos, yPos; 
  color c, cHighlight, cSelect;
  boolean highlighted, selected = false;
  
  playButton(int x, int y) {
    r = 40;
    xPos = x;
    yPos = y;
    c = color(82, 112, 89);
    cHighlight = color(62, 92, 69);
    cSelect = color(172, 202, 179);
  }
  
  void display() {
    win.noStroke();
    
    if (selected)
      win.fill(cSelect);
    else if (highlighted)
      win.fill(cHighlight);
    else
      win.fill(c);
    
    win.ellipseMode(CENTER);
    win.ellipse(xPos, yPos, r, r);
    win.fill(0);
    win.triangle(xPos-r/4, yPos-r/4, xPos-r/4, yPos+r/4, xPos+r/4, yPos);
  }
  
}

int update() {
  int highlightedTrack = -1;
  win.buttonOver = false;
  trackEditButton tEdit = win.trackEdit;
  playButton play = win.play;
  tEdit.highlighted = false;
  play.highlighted = false;
  
  if (overButton(tEdit.xPos, tEdit.yPos, tEdit.r, tEdit.r))
    tEdit.highlighted = true;
    
  if (overButton(play.xPos, play.yPos, play.r, play.r))
    play.highlighted = true;
  
  for (int i = 0; i < win.trackLength; i++) {
    track t = win.trackList.get(i);
    if (overButton(t.xPos, t.yPos, t.tWidth, t.tHeight)) {
      win.buttonOver = true;
      t.highlighted = true;
      highlightedTrack = i;
    }
    else {
      t.highlighted = false;
    }
    
    if (overEdit(t.tChange.xPos, t.tChange.yPos, t.tChange.r)) {
      t.tChange.highlighted = true;
      //println("overEdit| " + i);
    }
    else {
      t.tChange.highlighted = false;
    }
    
  }
  
  return highlightedTrack;
}

boolean overButton(int x, int y, int tWidth, int tHeight) {
  if (win.mouseX >= x/2 && win.mouseX <= x/2+tWidth &&
      win.mouseY >= (y-(tHeight/2)) && win.mouseY <= (y+(tHeight/2))) {
    return true;
  }  
  else {
    return false;
  }
}

boolean overEdit(int x, int y, int radius) {
  if (win.mouseX >= (x-radius/2) && win.mouseX <= (x+radius/2) &&
      win.mouseY >= (y-(radius/2)) && win.mouseY <= (y+(radius/2))) {
    return true;
  }  
  else {
    return false;
  }
}

void editTracks() {
  
  for (int i = 0; i < win.trackLength; i++) {
    track t = win.trackList.get(i);
    t.tChange.show = true; 
  }
}

void playTracks() {
  if (!win.playing) {
    println("playing now");
    mov.loop();
    mov.volume(0);
  }
  else {
    println("paused");
    mov.pause();
  }
  
  win.playing = !win.playing;
}
