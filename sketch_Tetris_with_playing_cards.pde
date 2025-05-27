import processing.sound.*;

int cols = 10, rows = 20, blockSize = 30;
int[][] grid = new int[cols][rows];
int[][] current, ghost;
PVector currentPos;
PImage[] blockImages = new PImage[52];
int[][][] tetrominos;
int score = 0, level = 1;
ArrayList<Integer> linesToClear = new ArrayList<Integer>();
int clearFrameCounter = 0;
boolean clearing = false;
int clearFrameMax = 10;
//SoundFile bgm;
boolean gameOver = false;
int dropCounter = 0;
int dropInterval = 30;
boolean paused = false;
int[][] next;
int[][] hold = null;
boolean canHold = true;

void setup() {
size(500,700);
frameRate(60);

// BGM
//bgm = new SoundFile(this, "bgm.mp3");
//bgm.loop();

// トランプ画像読み込み（0.png ~ 51.png）
for (int i = 0; i <= 51; i++) {
blockImages[i] = loadImage( i + ".png");
blockImages[i].resize(blockSize, blockSize);
}


initTetrominos();
spawnNewPiece();
}

void draw() {
  if (gameOver) {
  fill(0);
  textSize(40);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width / 2, height / 2);
  //bgm.stop();
  noLoop();
  return;
}
if (paused) {
  fill(0, 150);
  rect(0, 0, width, height);
  fill(255);
  textSize(40);
  textAlign(CENTER, CENTER);
  text("PAUSED\nPress the P button to resume", width / 2, height / 2);
  return;
}

background(255);
drawGrid();
drawTetromino(current, currentPos, false);
drawTetromino(ghost, currentPos, true);
drawScoreBoard();
drawNextPiece(); 
drawHoldPiece(); 
// 自動落下
dropCounter++;
if (dropCounter >= dropInterval) {
  dropCounter = 0;
  if (canMove(current, currentPos.x, currentPos.y + 1)) {
    currentPos.y++;
  } else {
    mergePiece();
    checkLines();
    spawnNewPiece();
  }
  updateGhost();
}

if (clearing) {
clearFrameCounter++;
if (clearFrameCounter % 2 == 0) drawClearAnimation();
if (clearFrameCounter >= clearFrameMax) {
removeClearedLines();
clearing = false;
}
}
}

void initTetrominos() {
tetrominos = new int[][][] {
{ {1, 1, 1, 1} }, // I
{ {1, 1}, {1, 1} }, // O
{ {0, 1, 0}, {1, 1, 1} }, // T
{ {1, 0, 0}, {1, 1, 1} }, // J
{ {0, 0, 1}, {1, 1, 1} }, // L
{ {1, 1, 0}, {0, 1, 1} }, // S
{ {0, 1, 1}, {1, 1, 0} } // Z
};
}

void spawnNewPiece() {
  if (next == null) {
    next = assignRandomImage(tetrominos[(int)random(tetrominos.length)]);
  }

  current = next;
  currentPos = new PVector(cols/2 - current[0].length/2, 0);

  if (!canMove(current, currentPos.x, currentPos.y)) {
    gameOver = true;
    return;
  }

  next = assignRandomImage(tetrominos[(int)random(tetrominos.length)]);
  updateGhost();
  canHold = true;
}
void drawNextPiece() {
  fill(0);
  textSize(20);
  text("Next:", cols * blockSize + 20, 120);

  if (next == null) return;

  for (int y = 0; y < next.length; y++) {
    for (int x = 0; x < next[y].length; x++) {
      if (next[y][x] > 0) {
        image(blockImages[next[y][x]], cols * blockSize + 20 + x * blockSize, 140 + y * blockSize);
      }
    }
  }
}
void drawHoldPiece() {
  fill(0);
  textSize(20);
  text("Hold:", cols * blockSize + 20, 300);

  if (hold == null) return;

  for (int y = 0; y < hold.length; y++) {
    for (int x = 0; x < hold[y].length; x++) {
      if (hold[y][x] > 0) {
        image(blockImages[hold[y][x]], cols * blockSize + 20 + x * blockSize, 320 + y * blockSize);
      }
    }
  }
}



int getRandomCardID() {
return (int)random(1, 52); // card_1 ~ card_9
}

int[][] assignRandomImage(int[][] shape) {
int[][] newShape = new int[shape.length][shape[0].length];
int id = getRandomCardID();
for (int y = 0; y < shape.length; y++) {
for (int x = 0; x < shape[0].length; x++) {
newShape[y][x] = shape[y][x] == 1 ? id : 0;
}
}
return newShape;
}

void updateGhost() {
ghost = copyShape(current);
PVector tempPos = currentPos.copy();
while (canMove(ghost, tempPos.x, tempPos.y + 1)) {
tempPos.y += 1;
}
ghost = ghost;
}

void drawTetromino(int[][] shape, PVector pos, boolean ghostFlag) {
for (int y = 0; y < shape.length; y++) {
for (int x = 0; x < shape[y].length; x++) {
if (shape[y][x] > 0) {
if (ghostFlag) fill(200, 100);
else image(blockImages[shape[y][x]], (int)(pos.x + x) * blockSize, (int)(pos.y + y) * blockSize);
if (ghostFlag)
rect((int)(pos.x + x) * blockSize, (int)(pos.y + y) * blockSize, blockSize, blockSize);
}
}
}
}

void drawGrid() {
for (int y = 0; y < rows; y++) {
for (int x = 0; x < cols; x++) {
if (grid[x][y] > 0) {
image(blockImages[grid[x][y]], x * blockSize, y * blockSize);
}
stroke(200);
noFill();
rect(x * blockSize, y * blockSize, blockSize, blockSize);
}
}
}

void drawScoreBoard() {
fill(0);
textSize(20);
text("Score: " + score, cols * blockSize + 20, 50);
text("Level: " + level, cols * blockSize + 20, 80);
}

void rotatePiece() {
int[][] rotated = rotateMatrix(current);
if (canMove(rotated, currentPos.x, currentPos.y)) {
current = rotated;
}
}
int[][] rotateMatrix(int[][] matrix) {
int w = matrix.length;
int h = matrix[0].length;
int[][] result = new int[h][w];
for (int y = 0; y < h; y++) {
for (int x = 0; x < w; x++) {
result[y][x] = matrix[w - 1 - x][y];
}
}
return result;
}
void rotatePieceCounter() {
  int[][] rotated = rotateMatrixCounter(current);
  if (canMove(rotated, currentPos.x, currentPos.y)) {
    current = rotated;
  }
}

int[][] rotateMatrixCounter(int[][] matrix) {
  int w = matrix.length;
  int h = matrix[0].length;
  int[][] result = new int[h][w];
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      result[y][x] = matrix[x][h - 1 - y];
    }
  }
  return result;
}

void keyPressed() {
 if (key == 'p' || key == 'P') {
    paused = !paused;
    return;
  }

  if (paused || gameOver) return;
 if (key == 's' || key == 'S') {
    holdPiece();
    return;
  }
  if (keyCode == LEFT && canMove(current, currentPos.x - 1, currentPos.y)) currentPos.x--;
  if (keyCode == RIGHT && canMove(current, currentPos.x + 1, currentPos.y)) currentPos.x++;
  if (keyCode == DOWN && canMove(current, currentPos.x, currentPos.y + 1)) currentPos.y++;
  if (key == ' ') dropPiece();
  if(key =='c'||key=='C') rotatePiece();
  if(key =='z' ||key=='Z')rotatePieceCounter();
  updateGhost();
}

void dropPiece() {
while (canMove(current, currentPos.x, currentPos.y + 1)) {
currentPos.y++;
}
mergePiece();
checkLines();
spawnNewPiece();
}

void mergePiece() {
for (int y = 0; y < current.length; y++) {
for (int x = 0; x < current[y].length; x++) {
if (current[y][x] > 0) {
grid[(int)currentPos.x + x][(int)currentPos.y + y] = current[y][x];
}
}
}
}

boolean canMove(int[][] shape, float x, float y) {
for (int j = 0; j < shape.length; j++) {
for (int i = 0; i < shape[j].length; i++) {
if (shape[j][i] > 0) {
int gx = (int)x + i;
int gy = (int)y + j;
if (gx < 0 || gx >= cols || gy >= rows) return false;
if (gy >= 0 && grid[gx][gy] > 0) return false;
}
}
}
return true;
}

int[][] copyShape(int[][] src) {
int[][] copy = new int[src.length][src[0].length];
for (int y = 0; y < src.length; y++) {
arrayCopy(src[y], copy[y]);
}
return copy;
}

void checkLines() {
linesToClear.clear();
for (int y = 0; y < rows; y++) {
boolean full = true;
for (int x = 0; x < cols; x++) {
if (grid[x][y] == 0) full = false;
}
if (full) linesToClear.add(y);
}
if (!linesToClear.isEmpty()) {
clearing = true;
clearFrameCounter = 0;
}
}

void drawClearAnimation() {
fill(255);
for (int row : linesToClear) {
for (int x = 0; x < cols; x++) {
rect(x * blockSize, row * blockSize, blockSize, blockSize);
}
}
}

void removeClearedLines() {
for (int row : linesToClear) {
for (int y = row; y > 0; y--) {
for (int x = 0; x < cols; x++) {
grid[x][y] = grid[x][y - 1];
}
}
for (int x = 0; x < cols; x++) {
grid[x][0] = 0;
}
}
score += linesToClear.size() * 100;
level = score / 500 + 1;
}
void holdPiece() {
  if (!canHold) return;

  if (hold == null) {
    // 初めてのホールド：hold に保存し、新しいミノを出す
    hold = copyShape(current);
    spawnNewPiece();
  } else {
    // 現在のミノとホールドを交換
    int[][] temp = copyShape(current);
    current = copyShape(hold);
    hold = temp;
    currentPos = new PVector(cols/2 - current[0].length/2, 0);
    
    if (!canMove(current, currentPos.x, currentPos.y)) {
      gameOver = true;
      return;
    }
    updateGhost();
  }

  canHold = false; // 1ターンに1回だけホールド
}
