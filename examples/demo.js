
const tunes1 = new Pico8(sfx1, music1);
const tunes2 = new Pico8(sfx2, music2);

let currMusic = null;

/**
 * Plays music.
 * @param {!Pico8} pico8 The PICO-8 cartridge.
 * @param {number} n The music pattern.
 */
function play(pico8, n) {
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
