/**
 * `connect`
 *
 * ---------------------------------------------------------------
 *
 * Run a static web server for serving during development
 *
 * For usage docs see:
 *   https://github.com/gruntjs/grunt-contrib-connect
 *
 */
module.exports = function(grunt) {

  grunt.config.set('connect', {
    server: {
      options: {
        port: grunt.option('port') || 1337,
        base: {
          path: '.tmp/public',
          options: {
            index: 'homepage.html'
          }
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-connect');
};
