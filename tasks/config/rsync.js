/**
 * `rsync`
 *
 * ---------------------------------------------------------------
 *
 * Rsync data to server
 *
 * For usage docs see:
 *   https://github.com/jedrichards/grunt-rsync
 *
 */
module.exports = function(grunt) {

  grunt.config.set('rsync', {
    prod: {
      options: {
        src: '.tmp/public/',
        dest: '/var/www/predots/public/',
        host: grunt.option('host') || 'BP7',
        delete: true,
        recursive: true
      }
    }
  });

  grunt.loadNpmTasks('grunt-rsync');
};
