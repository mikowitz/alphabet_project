PImage img;
JSONArray coordsJSON;
int[][] graphLine = new int[202][2];
int THRESHOLD = 200;
String letter;
String pngFilename;

void settings() {
  size(int(args[1]), int(args[2]));
}

void setup() {
  letter = args[0];
  pngFilename = letter + ".png";
  img = loadImage("originals/" + pngFilename);
  coordsJSON = new JSONArray();
  strokeWeight(2);
  stroke(0, 255, 0);
  image(img, 0, 0);
}

void draw() {
  detectGraphLine();
  save("data/with_graph_line/" + pngFilename);
  convertToBlackAndWhite();
  save("data/bw/" + pngFilename);
  int xAxisY = detectXAxis();
  save("data/with_x_axis/" + pngFilename);

  for (int i = 0; i < width; i++) {
    int[] coords = graphLine[i];
    JSONArray coordJSON = new JSONArray();
    coordJSON.setInt(0, coords[0]);
    coordJSON.setInt(1, xAxisY - coords[1]);
    coordsJSON.setJSONArray(i, coordJSON);
  }
  saveJSONArray(coordsJSON, "data/coordinates/" + letter + ".json");
  noLoop();
  delay(100);
  exit();
};

int detectXAxis() {
  loadPixels();
  for (int y = height-1; y >= 0 ; y--) {
    int p = pixels[y * width];
    float avg = (red(p) + green(p) + blue(p)) / 3;
    if (avg == 0.0) {
      line(0, y, width, y);
      return y;
    }
  }
  return 0;
}

void convertToBlackAndWhite() {
  loadPixels();

  for (int i = 0; i < pixels.length; i++) {
    int p = pixels[i];
    float avg = (red(p) + green(p) + blue(p)) / 3;
    if (avg > 200) {
      pixels[i] = color(255);
    } else {
      pixels[i] = color(0);
    }
  }
  updatePixels();
}

void detectGraphLine() {
  loadPixels();

  for (int x = 0; x < width; x++) {
    float lowestColorAvg = 255.0;
    float highestDiff = 0.0;
    int yIndex = 0;
    for (int y = 1; y < height-2; y++) {
      int p0 = pixels[(y-1) * width + x];
      int p1 = pixels[y * width + x];
      int p2 = pixels[(y+1) * width + x];
      int p3 = pixels[(y+2) * width + x];
      float avg0 = (red(p0) + green(p0) + blue(p0)) / 3;
      float avg1 = (red(p1) + green(p1) + blue(p1)) / 3;
      float avg2 = (red(p2) + green(p2) + blue(p2)) / 3;
      float avg3 = (red(p3) + green(p3) + blue(p3)) / 3;
      float prevAvg = (avg0 + avg1 + avg2) / 3;
      float finalAvg = (avg1 + avg2 + avg3) / 3;
      if (finalAvg < lowestColorAvg && (prevAvg - finalAvg) > highestDiff) {
        lowestColorAvg = finalAvg;
        highestDiff = prevAvg - finalAvg;
        yIndex = y;
      }
    }
    int[] coords = new int[2];
    coords[0] = x;
    coords[1] = yIndex;
    graphLine[x] = coords;
    point(x, yIndex);
  }
}
