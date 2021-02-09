

let currMusic = null;

/**
 * Plays music.
 * @param {!Cartridge} cartridge The PICO-8 cartridge data.
 * @param {number} n The music pattern.
 */
function play(cartridge, n) {
  stop();
  currMusic = pico8.music(cartridge, n);
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
