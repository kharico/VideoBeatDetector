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
int offsetY = 0;;
int seed = 3; // 2x max rate of change
int dx = int(random(seed)-seed/2);;
int dy = int(random(seed)-seed/2);
int frames = 10;

Movie mov;
color movColors[];
color pointColors[];

void setup() {
  size(640, 360);
  background(0);
  mov = new Movie(this, "sample_iTunes.mov");
  mov.loop();
  mov.volume(0);
  
  oscP5 = new OscP5(this,12000);
  oscAudio = new OscP5(this,9001);
  
  myRemoteLocation = new NetAddress("127.0.0.1", 12000);
  audioLocation = new NetAddress("127.0.0.1", 9001);
  
  movColors = new color[width * height];
}

void draw() { 
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
   
  if(theOscMessage.checkAddrPattern("/jitter")==true) {
    if(theOscMessage.checkTypetag("i")) {
    
      jitterOscMsg = theOscMessage.get(0).intValue(); 
      //println("jitter: "+jitterOscMsg);
      return;
    } 
  } 
  
  if(theOscMessage.checkAddrPattern("/desaturate")==true) {
    if(theOscMessage.checkTypetag("i")) {
    
      desaturateOscMsg = theOscMessage.get(0).intValue(); 
      //println("desaturate: "+desaturateOscMsg);
      return;
    } 
  } 
  
  if(theOscMessage.checkAddrPattern("/static")==true) {
    if(theOscMessage.checkTypetag("i")) {
    
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
    }
    else {
      println("jitter OFF");
    }
  }
  
  if (key == 'd' || key == 'D') {
    desaturateON = !desaturateON;
    
    //Test
    if (desaturateON) {
      println("desaturate ON");
      colorMode(HSB);
    }
    else {
      println("desaturate OFF");
      colorMode(RGB);
    }
  }
  
  if (key == 'n' || key == 'N') {
    noizeON = !noizeON;
    
    //Test
    if (noizeON) {
      println("noize ON");
    }
    else {
      println("noize OFF");
    }
  }
  
  if (key == 's' || key == 'S') {
    staticON = !staticON;
    
    //Test
    if (staticON) {
      println("static ON");
    }
    else {
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
    fill(255,0,0);
    
    recordAudio.add(1);
    oscP5.send(recordAudio, audioLocation);
  }
  else {
    fill(192,192,192);
    
    recordAudio.add(0);
    oscP5.send(recordAudio, audioLocation);
  }
  
  ellipse(15, 15, 20, 20);
}