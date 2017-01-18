/**
 * `coffeelint`
 *
 * ---------------------------------------------------------------
 *
 * Run the coffeelinter on assets/js
 *
 * For usage docs see:
 *   https://github.com/vojtajina/grunt-coffeelint
 *
 */
module.exports = function(grunt) {

  coffeeFiles = [{
      expand: true,
      cwd: 'assets/js/',
      src: ['**/*.coffee']
  }];

  grunt.config.set('coffeelint', {
    strict: {
      options: {
        configFile: 'coffeelint.json'
      },
      files: coffeeFiles
    },
    // Only warn but do not fail task. This can be used in the watch task for example
    warn: {
      options: {
        force: true,
        configFile: 'coffeelint.json'
      },
      files: coffeeFiles
    }
  });

  grunt.loadNpmTasks('grunt-coffeelint');
};
