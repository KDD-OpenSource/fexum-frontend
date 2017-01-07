/**
 * `deploy`
 *
 * ---------------------------------------------------------------
 *
 * Deploy all files to the server
 *
 */
module.exports = function(grunt) {
  grunt.registerTask('deploy', [
    'compileAssets',
    'concat',
    'uglify',
    'cssmin',
    'linkAssetsProd',
    'jade:views',
    'rsync:prod'
  ]);
};

