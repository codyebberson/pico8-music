const fs = require('fs');

const BASE_SPEED = 120;

/**
 * Parses a hex substring into a decimal number.
 * @param {string} str
 * @param {number} start
 * @param {number} len
 * @return {number}
 */
const parseHex = (str, start, len) => parseInt(str.substr(start, len), 16);

/**
 * Parses a sfx line.
 * @param {string} line
 * @return {!Array.<number>}
 */
const parseSfxLine = (line) => {
  const result = [
    // Ignore byte 0, editor mode
    parseHex(line, 2, 2), // Note duration
    parseHex(line, 4, 2), // Loop range start
    parseHex(line, 6, 2), // Loop range end
  ];
  for (let note = 0; note < 32; note++) {
    const start = 8 + note * 5;
    result.push(parseInt(line.substr(start, 2), 16)); // Pitch
    result.push(parseInt(line.substr(start + 2, 1), 16)); // Waveform
    result.push(parseInt(line.substr(start + 3, 1), 16)); // Volume
    result.push(parseInt(line.substr(start + 4, 1), 16)); // Effect
  }
  return result;
};

/**
 * Parses a music line.
 * @param {string} line
 * @return {!Array.<number>}
 */
const parseMusicLine = (line) => {
  return [
    parseInt(line.substr(0, 2), 16),
    parseInt(line.substr(3, 2), 16),
    parseInt(line.substr(5, 2), 16),
    parseInt(line.substr(7, 2), 16),
    parseInt(line.substr(9, 2), 16),
  ];
};

/**
 * Returns the base part of the file name.
 * @param {string} str
 * @return {string}
 */
const getBaseName = (str) => str.substring(Math.max(0, str.lastIndexOf('/') + 1), str.lastIndexOf('.p8'));

/**
 * Reads all file contents as a string.
 * @param {string} filename
 * @return {string}
 */
const readFile = (filename) => fs.readFileSync(filename, {encoding: 'utf8', flag: 'r'});

/**
 * Returns the P8 file section contents by section name.
 * @param {string} contents The full P8 file contents.
 * @param {string} sectionName The section name (not including underscores).
 * @return {string} Section contents.
 */
const getSection = (contents, sectionName) => {
  const startTag = '__' + sectionName + '__';
  const startIndex = contents.indexOf(startTag);
  if (startIndex < 0) {
    throw new Error('Section "' + startTag + '" not found');
  }
  let endIndex = contents.indexOf('__', startIndex + startTag.length);
  if (endIndex < 0) {
    endIndex = contents.length;
  }
  return contents.substring(startIndex + startTag.length, endIndex).trim();
};

/**
 *
 * @param {!Array.<!Array.<number>>} sfxInput
 * @param {!Array.<!Array.<number>>} musicInput
 * @param {number} startPattern
 * @param {string} name
 */
const convertSong = (sfxInput, musicInput, startPattern, name) => {
  // number->number map
  // key is the original sfx index
  // value is the output sfx index
  const sfxIndexMap = {};
  const sfxOutput = [];
  const musicOutput = [];
  let songLength = 0;
  let loopStartTime = 0;
  let endPattern = musicInput.length - 1;

  for (let patternIndex = startPattern; patternIndex <= endPattern; patternIndex++) {
    const musicInputRow = musicInput[patternIndex];
    const musicOutputRow = [];
    const flags = musicInputRow[0];

    if ((flags & 1) === 1) {
      loopStartTime = songLength;
    }

    let foundPatternLength = false;

    for (let channel = 1; channel <= 4; channel++) {
      const sfxInputIndex = musicInputRow[channel];
      if (sfxInputIndex >= sfxInput.length) {
        continue;
      }

      const sfxInputRow = sfxInput[sfxInputIndex];
      if (!sfxInputRow) {
        throw new Error('Missing sfx input row: ' + sfxInputIndex);
      }

      let timePattern = false;
      if (!foundPatternLength && sfxInputRow[2] === 0) {
        // Found the first non-looping channel
        // See: https://www.lexaloffle.com/bbs/?pid=12781
        const noteLength = sfxInputRow[0] / BASE_SPEED;
        songLength += 32 * noteLength;
        foundPatternLength = true;
        timePattern = true;
      }

      // Map the "input index" to an "output index"
      // If this is the first time encountering the "input index",
      // create the mapping.
      let sfxOutputIndex = sfxIndexMap[sfxInputIndex];
      if (sfxOutputIndex === undefined) {
        sfxOutputIndex = sfxOutput.length;
        sfxIndexMap[sfxInputIndex] = sfxOutputIndex;
        sfxOutput.push([...sfxInputRow]);
      }

      if (timePattern) {
        // If this is the time pattern, make sure it is at the front of the array
        musicOutputRow.unshift(sfxOutputIndex);
      } else {
        // Otherwise append to the end
        musicOutputRow.push(sfxOutputIndex);
      }
    }
    musicOutput.push(musicOutputRow);
    if ((flags & 2) === 2) {
      endPattern = patternIndex;
      break;
    }
  }

  const result = [
    Math.ceil(songLength * 1000) / 1000, // Round up to nearest thousandths of a second
    Math.ceil(loopStartTime * 1000) / 1000, // Round up to nearest thousandths of a second
    sfxOutput,
    musicOutput,
  ];

  console.log(`const ${name} = ${JSON.stringify(result)};`);
};

/**
 * Converts
 * @param {string} p8file The .p8 filename.
 */
const convertP8 = (p8file) => {
  const contents = readFile(p8file);
  const sfxStr = getSection(contents, 'sfx');
  const musicStr = getSection(contents, 'music');
  const sfxInput = sfxStr.split('\n').map(parseSfxLine);
  const musicInput = musicStr.split('\n').map(parseMusicLine);
  const baseName = getBaseName(p8file);
  let track = 1;
  for (let pattern = 0; pattern < musicInput.length; pattern++) {
    if (pattern === 0) {
      convertSong(sfxInput, musicInput, pattern, `${baseName}_${track++}`);
    }
    const flags = musicInput[pattern][0];
    if ((flags & 2) === 2 && pattern + 1 < musicInput.length) {
      convertSong(sfxInput, musicInput, pattern + 1, `${baseName}_${track++}`);
    }
  }
};

if (require.main === module) {
  if (process.argv.length !== 3) {
    console.log('Usage: node convert.js [myfile.p8]');
    console.log('Example: node convert.js tunes1.p8');
    return;
  }
  convertP8(process.argv[2]);
}
