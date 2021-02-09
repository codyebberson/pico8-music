
/**
 * Sound effects data definition.
 * @typedef {!Array.<!Array.<number>>}
 */
const SfxData = {};

/**
 * Sound effects data definition.
 * @typedef {!Array.<!Array.<number>>}
 */
const MusicData = {};

/**
 * Cartridge data definition.
 * Tuple with expected elements:
 *   0: {!SfxData} sfx data
 *   1: {!MusicData} music data
 * @typedef {!Array.<!SfxData|!MusicData>}
 */
const Cartridge = {};

const FX_NO_EFFECT = 0;
const FX_SLIDE = 1;
const FX_VIBRATO = 2;
const FX_DROP = 3;
const FX_FADE_IN = 4;
const FX_FADE_OUT = 5;
const FX_ARP_FAST = 6;
const FX_ARP_SLOW = 7;

const SAMPLE_RATE = 44100;

const BASE_SPEED = 120;

const audioCtx = new AudioContext();
let prevNoise = 0;

/**
 * Triangle oscillator.
 * @param {number} t
 * @return {number}
 */
const triangleOscillator = (t) => Math.abs(2 * t - 1) - 1.0;

/**
 * Tilted saw oscillator.
 * @param {number} t
 * @return {number}
 */
const tiltedSawOscillator = (t) => {
  const a = 0.9;
  const ret = t < a ? 2.0 * t / a - 1.0 : 2.0 * (1.0 - t) / (1.0 - a) - 1.0;
  return ret * 0.5;
};

/**
 * Saw oscillator.
 * 0->1 ramp
 * @param {number} t
 * @return {number}
 */
const sawOscillator = (t) => 0.653 * (t < 0.5 ? t : t - 1.0);

/**
 * Square oscillator.
 * 50% duty cycle square wave
 * @param {number} t
 * @return {number}
 */
const squareOscillator = (t) => t < 0.5 ? 0.5 : -0.5;

/**
 * Pulse oscillator.
 * 20% duty cycle square wave
 * @param {number} t
 * @return {number}
 */
const pulseOscillator = (t) => t < 0.333 ? 0.5 : -0.5;

/**
 * Organ oscillator.
 * tri-uneven: 100% tri 75% tri on loop
 * @param {number} t
 * @return {number}
 */
const organOscillator = (t) => (
  t < 0.5 ?
    3.0 - Math.abs(24.0 * t - 6.0) :
    1.0 - Math.abs(16.0 * t - 12.0)
) / 9.0;

/**
 * Noise oscillator.
 * @return {number}
 */
const noiseOscillator = () => {
  const white = Math.random() * 2 - 1;
  const brown = (prevNoise + (0.02 * white)) / 1.02;
  prevNoise = brown;
  return brown * 10; // (roughly) compensate for gain
};

/**
 * Phaser oscillator.
 * @param {number} t
 * @param {number} value
 * @return {number}
 */
const phaserOscillator = (t, value) => {
  // This one has a subfrequency of freq/128 that appears
  // to modulate two signals using a triangle wave
  // FIXME: amplitude seems to be affected, too
  const k = Math.abs(2.0 * ((value / 128.0) % 1.0) - 1.0);
  const u = (t + 0.5 * k) % 1.0;
  const ret = Math.abs(4.0 * u - 2.0) - Math.abs(8.0 * t - 4.0);
  return ret / 6.0;
};

/**
 * Oscillators.
 * Order and indices are important!
 * @const {!Array.<function(number=, number=): number>}
 */
const oscillators = [
  triangleOscillator,
  tiltedSawOscillator,
  sawOscillator,
  squareOscillator,
  pulseOscillator,
  organOscillator,
  noiseOscillator,
  phaserOscillator,
];

/**
 * Returns note frequency from pitch index (0-63).
 * From C-0 to D#-5 in chromatic scale.
 * @param {number} pitch
 * @return {number}
 */
const getNote = (pitch) => 65.4 * 2 ** (pitch / 12);

/**
 * @param {!SfxData} sfxData
 * @param {!Float32Array} data
 * @param {number} offset
 * @param {number} endOffset
 * @param {number} sfxIndex
 */
const buildSound = (sfxData, data, offset, endOffset, sfxIndex) => {
  const sfxRow = /** @const {!Array.<number>} */ (sfxData[sfxIndex]);
  const noteLength = sfxRow[0] / BASE_SPEED;
  let phi = 0;
  let i = 0;

  while (offset < endOffset) {
    const prevNote = i == 0 ? -1 : sfxRow[3 + (i - 1) * 4];
    const prevFreq = getNote(prevNote);
    const prevWaveform = i == 0 ? -1 : sfxRow[3 + (i - 1) * 4 + 1];
    const prevVolume = i == 0 ? -1 : sfxRow[3 + (i - 1) * 4 + 2] / 8.0;
    const prevEffect = i == 0 ? -1 : sfxRow[3 + (i - 1) * 4 + 3];

    const currNote = sfxRow[3 + i * 4];
    const noteFreq = getNote(sfxRow[3 + i * 4]);
    const waveForm = sfxRow[3 + i * 4 + 1] % oscillators.length;
    const noteVolume = sfxRow[3 + i * 4 + 2] / 8.0;
    const effect = sfxRow[3 + i * 4 + 3];

    const nextNote = i == 31 ? -1 : sfxRow[3 + (i + 1) * 4];
    const nextWaveform = i == 31 ? -1 : sfxRow[3 + (i + 1) * 4 + 1];
    const nextVolume = i == 31 ? -1 : sfxRow[3 + (i + 1) * 4 + 2] / 8.0;
    const nextEffect = i == 31 ? -1 : sfxRow[3 + (i + 1) * 4 + 3];

    let attack = 0.01;
    if (effect === FX_FADE_IN) {
      attack = 0;
    } else if (waveForm === prevWaveform &&
      (currNote === prevNote || effect === FX_SLIDE) &&
      prevVolume > 0 &&
      prevEffect !== FX_FADE_OUT) {
      attack = 0;
    }
    let release = 0.05;
    if (effect === FX_FADE_OUT) {
      release = 0;
    } else if (
      waveForm === nextWaveform &&
      (currNote === nextNote || nextEffect === FX_SLIDE) &&
      nextVolume > 0 &&
      nextEffect !== FX_FADE_IN) {
      release = 0;
    }

    // const samples = (noteLength * SAMPLE_RATE) | 0;
    const samples = Math.round(noteLength * SAMPLE_RATE);
    for (let j = offset; j < offset + samples; j++) {
      // Note factor is the percentage of completion of the note
      // 0.0 is the beginning
      // 1.0 is the end
      const noteFactor = (j - offset) / samples;

      let envelope = 1.0;
      if (noteFactor < attack) {
        envelope = noteFactor / attack;
      } else if (noteFactor > (1.0 - release)) {
        envelope = (1.0 - noteFactor) / release;
      }

      let freq = noteFreq;
      let volume = noteVolume;

      if (effect === FX_SLIDE) {
        freq = (1 - noteFactor) * prevFreq + noteFactor * noteFreq;
        if (prevVolume > 0) {
          volume = (1 - noteFactor) * prevVolume + noteFactor * noteVolume;
        }
      }
      if (effect === FX_VIBRATO) {
        freq *= 1.0 + 0.02 * Math.sin(7.5 * noteFactor);
      }
      if (effect === FX_DROP) {
        freq *= 1.0 - noteFactor;
      }
      if (effect === FX_FADE_IN) {
        volume *= noteFactor;
      }
      if (effect === FX_FADE_OUT) {
        volume *= 1.0 - noteFactor;
      }
      if (effect >= FX_ARP_FAST) {
        // From the documentation:
        //   6 arpeggio fast  //  Iterate over groups of 4 notes at speed of 4
        //   7 arpeggio slow  //  Iterate over groups of 4 notes at speed of 8
        //   If the SFX speed is <= 8, arpeggio speeds are halved to 2, 4
        // const m = (speed <= 8 ? 32 : 16) / (effect === FX_ARP_FAST ? 4 : 8);
        // const n = (int)(m * 7.5 * offset / offsetPerSecond);
        // const arp_note = (note_id & ~3) | (n & 3);
        // freq = key_to_freq(sfx.notes[arp_note].key);
        freq = getNote(sfxRow[3 + i * 4]);
      }

      phi += freq / SAMPLE_RATE;
      data[j] += volume * envelope * oscillators[waveForm](phi % 1, phi);
    }
    offset += samples;
    // prevFreq = noteFreq;
    // prevVolume = noteVolume;

    // TODO: Use loop end, not 32
    i = (i + 1) % 32;
  }
};

/**
 * Builds and plays a song.
 * @param {!Cartridge} cartridge
 * @param {number=} startPattern
 * @return {!AudioBufferSourceNode}
 */
const playMusic = (cartridge, startPattern = 0) => {
  const sfxData = /** @const {!SfxData} */ (cartridge[0]);
  const musicData = /** @const {!MusicData} */ (cartridge[1]);

  // Find the end pattern
  // The end pattern is either:
  //   1) The first pattern after start with the "loop" flag set
  //   2) Or the last pattern in the cartridge
  const endPattern = /** @const {number} */ (musicData.findIndex(
      (row, index) =>
        // Looping pattern after start
        (/** @type {number} */ (index) >= /** @type {number} */ (startPattern) && (row[0] & 2) === 2) ||
        // Or the last pattern in the cartridge
        index === musicData.length - 1));

  // Calculate the loop start time and the song length.
  let loopStart = 0;
  let songLength = 0;
  for (let pattern = startPattern; pattern <= endPattern; pattern++) {
    const musicRow = musicData[pattern];
    const noteLength = sfxData[musicRow[0]][0] / BASE_SPEED;
    if ((musicRow[0] & 1) === 1) {
      loopStart = songLength;
    }
    songLength += 32 * noteLength;
  }

  const frameCount = SAMPLE_RATE * songLength;
  const audioBuffer = audioCtx.createBuffer(1, frameCount, SAMPLE_RATE);
  const data = audioBuffer.getChannelData(0);
  let offset = 0;
  for (let pattern = startPattern; pattern <= endPattern; pattern++) {
    const musicRow = musicData[pattern];
    const noteLength = sfxData[musicRow[0]][0] / BASE_SPEED;
    const patternSamples = Math.round(32 * noteLength * SAMPLE_RATE);
    for (let channel = 0; channel < musicRow.length; channel++) {
      const sfxIndex = musicRow[channel];
      if (sfxIndex < sfxData.length) {
        // TODO: Note length can vary across channels
        // If one channel is faster, need to repeat for duration of the longest channel...
        buildSound(sfxData, data, offset, offset + patternSamples, sfxIndex);
      }
    }
    offset += patternSamples;
  }

  const source = audioCtx.createBufferSource();
  source.buffer = audioBuffer;
  source.loop = true;
  source.loopStart = loopStart;
  source.connect(audioCtx.destination);
  source.start();
  return source;
};

window['pico8'] = {
  'music': playMusic,
};
