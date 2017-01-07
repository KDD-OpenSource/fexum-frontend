/**
 * Precompiles jade templates to a `.jst` file and views into respective html files.
 *
 * ---------------------------------------------------------------
 *
 * JST:
 * 	i.e. basically it takes JADE files and turns them into tiny little
 *  javascript functions that you pass data to and return HTML. This can
 *  speed up template rendering on the client, and reduce bandwidth usage.
 *
 * For usage docs see:
 * 		https://github.com/gruntjs/grunt-contrib-jade
 *
 */

module.exports = function(grunt) {

  grunt.config.set('jade', {
    jst: {
      options: {
        client: true
      },
      files: {
        '.tmp/public/jst.js': require('../pipeline').templateFilesToInject
      }
    },
    views: {
      files: [{
        expand: true,
        cwd: './views',
        src: require('../pipeline').viewsToCompile,
        dest: '.tmp/public/',
        ext: '.html'
      }]
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jade');
};
