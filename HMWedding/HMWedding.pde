import processing.opengl.*;
import codeanticode.glgraphics.*;
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;

// start in London
float latStart = 51.498;
float lonStart = -0.128;
float maxRadius = 0.002;

de.fhpotsdam.unfolding.Map map;
Location locStart = new Location(latStart, lonStart);
int initZoom = 13;

// an example output of this controller is the file /data/sample_data.xml
String jsonSrcPosts = "http://test.net/tools/index.php/api_fom_viz/get_post_rw";
// all the locations will be stored here
ArrayList locations;

int width = 800;
int height = 600;

String postChunkTime = "click anyware on the map to start";
boolean loadStarted = false;
boolean loadFinished = false;
int loadCount = 0;
int pageSize = 1000;

// setup frame
public void setup() {
  size(width, height, GLConstants.GLGRAPHICS);

  noStroke();

  // sign up for a free api key here: http://maps.cloudmade.com/ so you can create your personalized map id
  map = new de.fhpotsdam.unfolding.Map(this, new OpenStreetMap.CloudmadeProvider("get-your-api-key-buddy", 48535));
  map.setTweening(true);
  map.zoomToLevel(initZoom);
  map.panTo(locStart);

  MapUtils.createDefaultEventDispatcher(this, map);
  locations = new ArrayList();
}

// draw frame
public void draw() {
  background(0);
  map.draw();

  drawLocations();
  drawChunkTime();
  
  // we load a page of tweets every 10 frames, this way we create time lapse and avoid overload
  if( loadStarted && 0 == frameCount % 10) {
    loadPostChunk();
    // only if you want to create a nice video of what you're showing on the map
    saveFrame();
  }
}

// start
void mouseClicked() {
  loadStarted = true;
}

// load a chunk of elements
void loadPostChunk()
{
  if(!loadFinished) {
    String request = jsonSrcPosts + "/" + (loadCount * pageSize) + "/" + pageSize + "/xml/" + latStart + "/" + lonStart;
    println( "sending request - " + request );
    loadCount++;

    XMLElement xml = new XMLElement(this, request);
    XMLElement[] posts = xml.getChildren("success/posts/post");
    
    if( posts.length > 0 ) {
      for(int j = 0; j < posts.length; j++) {
        if( j == 0 ) {
          postChunkTime = posts[j].getChild("created").getContent();
          println("post chunk time - " + postChunkTime);
        }
        float distance = float(posts[j].getChild("distance").getContent());
        if( distance < maxRadius ) {
          float lat = float(posts[j].getChild("lat").getContent());
          float lon = float(posts[j].getChild("lon").getContent());
          locations.add( new PVector(lat, lon, distance) );
        }
      }
    } else {
      loadFinished = true;
    }
  }
};

// draw the array of locations
void drawLocations() {
  // Draws locations on screen positions according to their geo-locations.
  for( int i = 0; i < locations.size() - 1; i++ ) {
    PVector loc = (PVector)locations.get(i);
    float xy[] = map.getScreenPositionFromLocation(new Location(loc.x, loc.y));
    
    // distColor is 0 when close to map origin
    int distColor = int(255 * pow((loc.z / maxRadius),2));
    fill(255, distColor, distColor);
    ellipse(xy[0], xy[1], 4, 4);
  }
}

// draw the clock on top of the frame
void drawChunkTime() {
  fill(0, 0, 0, 135);
  rect(0, 0, width, 30);
  fill(255, 255, 255);
  text(postChunkTime, 10, 20);
}
