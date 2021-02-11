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

/**
 * Global audio context.
 * Using a global will create a warning in Chrome, but appears to be fine.
 * @const {!AudioContext}
 */
const audioCtx = new AudioContext();

/**
 * Creates a new PICO-8 cartridge.
 * @param {string} sfx
 * @param {string} music
 * @constructor
 */
window['Pico8'] = function(sfx, music) {
  /**
   * Previous brown noise.
   * Need to track this to trim frequency ranges.
   * See the noise oscillator.
   * @type {number}
   */
  let prevNoise = 0;

  /**
   * Parses a hex substring into a decimal number.
   * @param {string} str
   * @param {number} start
   * @param {number} len
   * @return {number}
   * @noinline
   */
  const parseHex = (str, start, len) => parseInt(str.substr(start, len), 16);

  /**
   * Rounds a number.
   * This compresses better than Math.round.
   * Google Closure Compiler inlines the calls.
   * @param {number} x Input number.
   * @return {number} Output number.
   */
  const round = (x) => (x + 0.5) | 0;

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
  const sawOscillator = (t) => 0.6 * (t < 0.5 ? t : t - 1.0);

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
  const pulseOscillator = (t) => t < 0.3 ? 0.5 : -0.5;

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
  const getFreq = (pitch) => 65 * 2 ** (pitch / 12);

  /**
   * Cache of pre-built sounds.
   * Key is `${sfxIndex}-${pitchOffset}
   * Value is a Float32Array.
   * @const {!Object}
   */
  const soundCache = {};

  /**
   * Builds the sound from scratch.
   * @param {!Array.<string>} sfxData
   * @param {number} sfxIndex
   * @param {number} pitchOffset
   * @return {!Float32Array}
   */
  const buildSound = (sfxData, sfxIndex, pitchOffset) => {
    const sfxRow = sfxData[sfxIndex];
    const noteLength = parseHex(sfxRow, 2, 2) / BASE_SPEED;
    const loopStart = parseHex(sfxRow, 4, 2);
    const loopEnd = parseHex(sfxRow, 6, 2) || 32;
    const length = loopEnd * SAMPLE_RATE;
    const data = new Float32Array(length);

    /**
     * Returns the next note index.
     * Handles loop start/end.
     * @param {number} i The current note index.
     * @return {number} The next note index.
     */
    const getNextIndex = (i) => i + 1 >= loopEnd ? loopStart : i + 1;

    /**
     * Returns a data element from the sfx row.
     * @param {number} index The note index. (0-32).
     * @param {number} offset The element offset (0-4).
     * @param {number} len The length in hex characters.
     * @return {number} The sfx value.
     */
    const getSfx = (index, offset, len) => parseHex(sfxRow, 8 + index * 5 + offset, len);

    let offset = 0;
    let phi = 0;
    let i = 0;

    let prevNote = 24;
    let prevFreq = getFreq(24);
    let prevWaveform = -1;
    let prevVolume = -1;
    let prevEffect = -1;

    let currNote;
    let currFreq;
    let currWaveform;
    let currVolume;
    let currEffect;

    while (offset < length) {
      currNote = getSfx(i, 0, 2) + pitchOffset;
      currFreq = getFreq(currNote);
      currWaveform = getSfx(i, 2, 1);
      currVolume = getSfx(i, 3, 1) / 8.0;
      currEffect = getSfx(i, 4, 1);

      const next = getNextIndex(i);
      const nextNote = getSfx(next, 0, 2) + pitchOffset;
      const nextWaveform = getSfx(next, 2, 1);
      const nextVolume = getSfx(next, 3, 1);
      const nextEffect = getSfx(next, 4, 1);

      let attack = 0.02;
      if (currEffect === FX_FADE_IN ||
        (currWaveform === prevWaveform &&
          (currNote === prevNote || currEffect === FX_SLIDE) &&
          prevVolume > 0 &&
          prevEffect !== FX_FADE_OUT)) {
        attack = 0;
      }
      let release = 0.05;
      if (currEffect === FX_FADE_OUT ||
        (currWaveform === nextWaveform &&
          (currNote === nextNote || nextEffect === FX_SLIDE) &&
          nextVolume > 0 &&
          nextEffect !== FX_FADE_IN)) {
        release = 0;
      }

      const samples = round(noteLength * SAMPLE_RATE);
      const customInstrument = currWaveform > 7 && getSound(sfxData, currWaveform - 8, pitchOffset + currNote - 24);
      let k = 0;
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

        let freq = currFreq;
        let volume = currVolume;

        if (currEffect === FX_SLIDE) {
          freq = (1 - noteFactor) * prevFreq + noteFactor * currFreq;
          if (prevVolume > 0) {
            volume = (1 - noteFactor) * prevVolume + noteFactor * currVolume;
          }
        }
        if (currEffect === FX_VIBRATO) {
          freq *= 1.0 + 0.02 * Math.sin(7.5 * noteFactor);
        }
        if (currEffect === FX_DROP) {
          freq *= 1.0 - noteFactor;
        }
        if (currEffect === FX_FADE_IN) {
          volume *= noteFactor;
        }
        if (currEffect === FX_FADE_OUT) {
          volume *= 1.0 - noteFactor;
        }
        if (currEffect >= FX_ARP_FAST) {
          // From the documentation:
          //   6 arpeggio fast  //  Iterate over groups of 4 notes at speed of 4
          //   7 arpeggio slow  //  Iterate over groups of 4 notes at speed of 8
          //   If the SFX speed is <= 8, arpeggio speeds are halved to 2, 4
          // const m = (speed <= 8 ? 32 : 16) / (effect === FX_ARP_FAST ? 4 : 8);
          // const n = (int)(m * 7.5 * offset / offsetPerSecond);
          // const arp_note = (note_id & ~3) | (n & 3);
          // freq = key_to_freq(sfx.notes[arp_note].key);
          freq = currFreq;
        }

        phi += freq / SAMPLE_RATE;
        if (currWaveform < 8) {
          data[j] += volume * envelope * oscillators[currWaveform](phi % 1, phi);
        } else {
          data[j] += volume * envelope * customInstrument[k];
          k = (k + 1) % customInstrument.length;
        }
      }

      offset += samples;
      prevNote = currNote;
      prevFreq = currFreq;
      prevWaveform = currWaveform;
      prevVolume = currVolume;
      prevEffect = currEffect;
      i = getNextIndex(i);
    }
    return data;
  };

  /**
   * Returns a sound buffer.
   * Uses a cached buffer if available.
   * Otherwise builds the sound from scratch.
   * @param {!Array.<string>} sfxData
   * @param {number} sfxIndex
   * @param {number} pitchOffset
   * @return {!Float32Array}
   */
  const getSound = (sfxData, sfxIndex, pitchOffset) => {
    const key = sfxIndex + '-' + pitchOffset;
    let sound = soundCache[key];
    if (!sound) {
      sound = buildSound(sfxData, sfxIndex, pitchOffset);
      soundCache[key] = sound;
    }
    return sound;
  };

  /**
   * @param {!Array.<string>} sfxData
   * @param {!Float32Array} data
   * @param {number} offset
   * @param {number} endOffset
   * @param {number} sfxIndex
   * @param {number=} pitchOffset
   */
  const buildMusic = (sfxData, data, offset, endOffset, sfxIndex, pitchOffset = 0) => {
    const sfxBuffer = getSound(sfxData, sfxIndex, pitchOffset);
    let i = 0;
    while (offset < endOffset) {
      data[offset] += sfxBuffer[i];
      i = (i + 1) % sfxBuffer.length;
      offset++;
    }
  };

  /**
   * Builds and plays a song.
   * @param {number=} startPattern
   * @return {!AudioBufferSourceNode}
   */
  const playMusic = (startPattern = 0) => {
    const sfxData = sfx.split('\n');
    const musicData = music.split('\n');

    // Preprocess loop
    // Need to do 4 things on this loop:
    // 1) Find the "time" channels
    //    Channels can run at different speeds, and therefore have different lengths
    //    The length of a pattern is defined by the first non-looping channel
    //    See: https://www.lexaloffle.com/bbs/?pid=12781
    // 2) Calculate the pattern lengths
    //    After we know the time channel, we can convert that into number of samples
    // 3) Find the loop start time (if one exists)
    //    Find the pattern with the "start loop" flag set
    //    Otherwise default to beginning of the song
    // 4) Find the end pattern and total song length
    //    Find the pattern with the "end loop" flag set
    //    Otherwise default to end of the song
    const timeChannels = [];
    const patternSamples = [];
    let loopStart = 0;
    let songLength = 0;
    let endPattern = musicData.length - 1;
    for (let pattern = startPattern; pattern <= endPattern; pattern++) {
      const musicRow = musicData[pattern];
      const flags = parseHex(musicRow, 0, 2);

      timeChannels[pattern] = 0;
      for (let channel = 0; channel < 4; channel++) {
        const sfxIndex = parseHex(musicRow, 3 + channel * 2, 2);
        if (sfxIndex < sfxData.length) {
          const sfxRow = sfxData[sfxIndex];
          const loopEnd = parseHex(sfxRow, 6, 2);
          if (loopEnd === 0) {
            timeChannels[pattern] = channel;
            break;
          }
        }
      }

      const sfxIndex = parseHex(musicRow, 3 + timeChannels[pattern] * 2, 2);
      const sfxRow = sfxData[sfxIndex];
      const noteLength = parseHex(sfxRow, 2, 2) / BASE_SPEED;
      patternSamples[pattern] = round(32 * noteLength * SAMPLE_RATE);

      if ((flags & 1) === 1) {
        loopStart = songLength;
      }

      songLength += 32 * noteLength;

      if ((flags & 2) === 2) {
        endPattern = pattern;
        break;
      }
    }

    // Now we have everything we need to build the song
    const frameCount = SAMPLE_RATE * songLength;
    const audioBuffer = audioCtx.createBuffer(1, frameCount, SAMPLE_RATE);
    const data = audioBuffer.getChannelData(0);

    // Main music generator loop
    let offset = 0;
    for (let pattern = startPattern; pattern <= endPattern; pattern++) {
      const musicRow = musicData[pattern];
      const samples = patternSamples[pattern];
      for (let channel = 0; channel < 4; channel++) {
        const sfxIndex = parseHex(musicRow, 3 + channel * 2, 2);
        if (sfxIndex < sfxData.length) {
          buildMusic(sfxData, data, offset, offset + samples, sfxIndex);
        }
      }
      offset += samples;
    }

    const source = audioCtx.createBufferSource();
    source.buffer = audioBuffer;
    source.loop = true;
    source.loopStart = loopStart;
    source.connect(audioCtx.destination);
    source.start();
    return source;
  };

  this['music'] = playMusic;
};
