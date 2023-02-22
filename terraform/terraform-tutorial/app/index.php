<!DOCTYPE html>
<html>

<head>
  <title>Terramino</title>
  <link rel="icon" href="https://www.terraform.io/favicon.ico" type="image/x-icon" />
  <style>
    html,
    body {
      height: 100%;
      margin: 0;
    }

    body {
      background-image: url("https://github.com/hashicorp/learn-terramino/raw/master/background.png");
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-family: Arial, Helvetica, sans-serif
    }

    h1 {
      font-family: Impact, Charcoal, sans-serif
    }

    canvas {
      border: 1px solid white;
    }

    .container {
      position: relative;
      margin: 0 auto;
    }

    .content {
      position: relative;
      left: 0;
      top: 0;
    }

    .attribute-name {
      display: inline-block;
      font-weight: bold;
      width: 10em;
    }
  </style>
</head>
<?php
  $ch = curl_init();
  $params= array('api-version'=>'2021-02-01', 'format'=>'text');
  $vm_name_url = "http://169.254.169.254/metadata/instance/compute/name" . '?' . http_build_query($params);
  $zone_url = "http://169.254.169.254/metadata/instance/compute/zone" . '?' . http_build_query($params);
  $resourceid_url = "http://169.254.169.254/metadata/instance/compute/resourceId" . '?' . http_build_query($params);// set url
curl_setopt($ch, CURLOPT_URL, $vm_name_url);

// set header
curl_setopt($ch, CURLOPT_HTTPHEADER, array('Metadata:true'));

//return the transfer as a string
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

// $output contains the output string
$vm_name = curl_exec($ch);

curl_setopt($ch, CURLOPT_URL, $zone_url);
$zone = curl_exec($ch);

curl_setopt($ch, CURLOPT_URL, $resourceid_url);
$resource_id = curl_exec($ch);

// close curl resource to free up system resources
curl_close($ch);

  ?>

<body>
  <div class="container">
    <div class="content">
      <h1>Terramino</h1>
      <p><span class="attribute-name">VM Name:</span><code><?php echo $vm_name; ?></code></p>
      <p><span class="attribute-name">Instance ID:</span><code><?php echo $resource_id; ?></code></p>
      <p><span class="attribute-name">Availability Zones:</span><code><?php echo $zone; ?></code></p>
      <p>Use left and right arrow keys to move blocks.<br />Use up arrow key to flip block.</p>
    </div>
    <div class="content">
      <canvas width="320" height="640" id="game"></canvas>
    </div>
  </div>
  <script>
    // https://tetris.fandom.com/wiki/Tetris_Guideline

    // get a random integer between the range of [min,max]
    // @see https://stackoverflow.com/a/1527820/2124254
    function getRandomInt(min, max) {
      min = Math.ceil(min);
      max = Math.floor(max);

      return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    // generate a new tetromino sequence
    // @see https://tetris.fandom.com/wiki/Random_Generator
    function generateSequence() {
      const sequence = ["I", "J", "L", "O", "S", "T", "Z"];

      while (sequence.length) {
        const rand = getRandomInt(0, sequence.length - 1);
        const name = sequence.splice(rand, 1)[0];
        tetrominoSequence.push(name);
      }
    }

    // get the next tetromino in the sequence
    function getNextTetromino() {
      if (tetrominoSequence.length === 0) {
        generateSequence();
      }

      const name = tetrominoSequence.pop();
      const matrix = tetrominos[name];

      // I and O start centered, all others start in left-middle
      const col = playfield[0].length / 2 - Math.ceil(matrix[0].length / 2);

      // I starts on row 21 (-1), all others start on row 22 (-2)
      const row = name === "I" ? -1 : -2;

      return {
        name: name, // name of the piece (L, O, etc.)
        matrix: matrix, // the current rotation matrix
        row: row, // current row (starts offscreen)
        col: col // current col
      };
    }

    // rotate an NxN matrix 90deg
    // @see https://codereview.stackexchange.com/a/186834
    function rotate(matrix) {
      const N = matrix.length - 1;
      const result = matrix.map((row, i) =>
        row.map((val, j) => matrix[N - j][i])
      );

      return result;
    }

    // check to see if the new matrix/row/col is valid
    function isValidMove(matrix, cellRow, cellCol) {
      for (let row = 0; row < matrix.length; row++) {
        for (let col = 0; col < matrix[row].length; col++) {
          if (
            matrix[row][col] &&
            // outside the game bounds
            (cellCol + col < 0 ||
              cellCol + col >= playfield[0].length ||
              cellRow + row >= playfield.length ||
              // collides with another piece
              playfield[cellRow + row][cellCol + col])
          ) {
            return false;
          }
        }
      }

      return true;
    }

    // place the tetromino on the playfield
    function placeTetromino() {
      for (let row = 0; row < tetromino.matrix.length; row++) {
        for (let col = 0; col < tetromino.matrix[row].length; col++) {
          if (tetromino.matrix[row][col]) {
            // game over if piece has any part offscreen
            if (tetromino.row + row < 0) {
              return showGameOver();
            }

            playfield[tetromino.row + row][tetromino.col + col] =
              tetromino.name;
          }
        }
      }

      // check for line clears starting from the bottom and working our way up
      for (let row = playfield.length - 1; row >= 0;) {
        if (playfield[row].every(cell => !!cell)) {
          // drop every row above this one
          for (let r = row; r >= 0; r--) {
            playfield[r] = playfield[r - 1];
          }
        } else {
          row--;
        }
      }

      tetromino = getNextTetromino();
    }

    // show the game over screen
    function showGameOver() {
      cancelAnimationFrame(rAF);
      gameOver = true;

      context.fillStyle = "black";
      context.globalAlpha = 0.75;
      context.fillRect(0, canvas.height / 2 - 30, canvas.width, 60);

      context.globalAlpha = 1;
      context.fillStyle = "white";
      context.font = "36px monospace";
      context.textAlign = "center";
      context.textBaseline = "middle";
      context.fillText("GAME OVER!", canvas.width / 2, canvas.height / 2);
    }

    const canvas = document.getElementById("game");
    const context = canvas.getContext("2d");
    const grid = 32;
    const tetrominoSequence = [];

    // keep track of what is in every cell of the game using a 2d array
    // tetris playfield is 10x20, with a few rows offscreen
    const playfield = [];

    // populate the empty state
    for (let row = -2; row < 20; row++) {
      playfield[row] = [];

      for (let col = 0; col < 10; col++) {
        playfield[row][col] = 0;
      }
    }

    // how to draw each tetromino
    // @see https://tetris.fandom.com/wiki/SRS
    const tetrominos = {
      I: [[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]],
      J: [[1, 0, 0], [1, 1, 1], [0, 0, 0]],
      L: [[0, 0, 1], [1, 1, 1], [0, 0, 0]],
      O: [[1, 1], [1, 1]],
      S: [[0, 1, 1], [1, 1, 0], [0, 0, 0]],
      Z: [[1, 1, 0], [0, 1, 1], [0, 0, 0]],
      T: [[0, 1, 0], [1, 1, 1], [0, 0, 0]]
    };

    // color of each tetromino
    const colors = {
      I: "#623CE4",
      O: "#7C8797",
      T: "#00BC7F",
      S: "#CA2171",
      Z: "#1563ff",
      J: "#00ACFF",
      L: "white"
    };

    let count = 0;
    let tetromino = getNextTetromino();
    let rAF = null; // keep track of the animation frame so we can cancel it
    let gameOver = false;

    // game loop
    function loop() {
      rAF = requestAnimationFrame(loop);
      context.clearRect(0, 0, canvas.width, canvas.height);

      // draw the playfield
      for (let row = 0; row < 20; row++) {
        for (let col = 0; col < 10; col++) {
          if (playfield[row][col]) {
            const name = playfield[row][col];
            context.fillStyle = colors[name];

            // drawing 1 px smaller than the grid creates a grid effect
            context.fillRect(col * grid, row * grid, grid - 1, grid - 1);
          }
        }
      }

      // draw the active tetromino
      if (tetromino) {
        // tetromino falls every 35 frames
        if (++count > 35) {
          tetromino.row++;
          count = 0;

          // place piece if it runs into anything
          if (!isValidMove(tetromino.matrix, tetromino.row, tetromino.col)) {
            tetromino.row--;
            placeTetromino();
          }
        }

        context.fillStyle = colors[tetromino.name];

        for (let row = 0; row < tetromino.matrix.length; row++) {
          for (let col = 0; col < tetromino.matrix[row].length; col++) {
            if (tetromino.matrix[row][col]) {
              // drawing 1 px smaller than the grid creates a grid effect
              context.fillRect(
                (tetromino.col + col) * grid,
                (tetromino.row + row) * grid,
                grid - 1,
                grid - 1
              );
            }
          }
        }
      }
    }

    // listen to keyboard events to move the active tetromino
    document.addEventListener("keydown", function (e) {
      if (gameOver) return;

      // left and right arrow keys (move)
      if (e.which === 37 || e.which === 39) {
        const col = e.which === 37 ? tetromino.col - 1 : tetromino.col + 1;

        if (isValidMove(tetromino.matrix, tetromino.row, col)) {
          tetromino.col = col;
        }
      }

      // up arrow key (rotate)
      if (e.which === 38) {
        const matrix = rotate(tetromino.matrix);
        if (isValidMove(matrix, tetromino.row, tetromino.col)) {
          tetromino.matrix = matrix;
        }
      }

      // down arrow key (drop)
      if (e.which === 40) {
        const row = tetromino.row + 1;

        if (!isValidMove(tetromino.matrix, row, tetromino.col)) {
          tetromino.row = row - 1;

          placeTetromino();
          return;
        }

        tetromino.row = row;
      }
    });

    // start the game
    rAF = requestAnimationFrame(loop);
  </script>
</body>

</html>