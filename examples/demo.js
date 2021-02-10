

let currMusic = null;

/**
 * Plays music.
 * @param {number} n The music pattern.
 */
function play(n) {
  stop();
  currMusic = pico8.music(n);
}

/**
 * Stops music if currently playing.
 */
function stop() {
  if (currMusic) {
    currMusic.stop();
    currMusic = null;
  }
}
