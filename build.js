const fs = require('fs');
const archiver = require('archiver');
const ClosureCompiler = require('google-closure-compiler').compiler;

const INPUT_FILE = 'src/player.js';
const OUTPUT_FILE = 'dist/player.min.js';

/**
 * Compiles
 * @return {Promise} promise
 */
function compile() {
  return new Promise((resolve, reject) => {
    const closureCompiler = new ClosureCompiler({
      language_in: 'ECMASCRIPT_2019',
      language_out: 'ECMASCRIPT_2019',
      compilation_level: 'ADVANCED',
      strict_mode_input: true,
      warning_level: 'VERBOSE',
      summary_detail_level: 3,
      externs: 'src/externs.js',
      jscomp_error: '*',
      jscomp_off: [
        'missingRequire',
      ],
      js: [INPUT_FILE],
      js_output_file: OUTPUT_FILE,
    });

    closureCompiler.run((exitCode, stdOut, stdErr) => {
      if (stdOut) {
        console.log(stdOut.trim());
      }
      if (exitCode === 0) {
        resolve();
      } else {
        reject(stdErr.trim());
      }
    });
  });
}

/**
 * Remove the "use strict;" added by Google Closure Compiler.
 * @return {Promise}
 */
function removeUseStrict() {
  return new Promise((resolve, reject) => {
    let str = fs.readFileSync(OUTPUT_FILE, {encoding: 'utf8', flag: 'r'});
    str = str.replace('\'use strict\';', '');
    fs.writeFileSync(OUTPUT_FILE, str);
    resolve();
  });
}

/**
 * Creates a zip file of the submission.
 * @return {Promise}
 */
function createZip() {
  return new Promise((resolve, reject) => {
    const archive = archiver('zip', {zlib: {level: 9}});
    const output = fs.createWriteStream('dist/dist.zip');
    output.on('close', () => {
      const packageSize = archive.pointer();
      const percent = packageSize / 13312 * 100;
      console.log(`Package: ${packageSize} bytes (${percent.toFixed(2)}%)`);
      resolve(packageSize);
    });
    output.on('error', (error) => {
      packageSize = -1;
      reject(error);
    });
    archive.on('error', (error) => {
      packageSize = -1;
      reject(error);
    });
    archive.pipe(output);
    archive.file('dist/player.min.js', {name: 'player.min.js'});
    archive.finalize();
  });
}

if (require.main === module) {
  compile()
      .then(removeUseStrict)
      .then(createZip)
      .catch((reason) => console.log(reason));
}
