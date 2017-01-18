/**
 * `quality`
 *
 * ---------------------------------------------------------------
 *
 * Runs serveral quality assurance tasks
 *
 */
module.exports = function(grunt) {
  grunt.registerTask('quality:strict', [
    'coffeelint:strict'
  ]);
  grunt.registerTask('quality:warn', [
    'coffeelint:warn'
  ]);
};
