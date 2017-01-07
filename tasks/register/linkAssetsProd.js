/**
 * `linkAssetsProd`
 *
 * ---------------------------------------------------------------
 *
 * This Grunt tasklist is not designed to be used directly-- rather
 * it is a helper called by the `default` tasklist and the `watch` task
 * (but only if the `grunt-sails-linker` package is in use).
 *
 * For more information see:
 *   http://sailsjs.org/documentation/anatomy/my-app/tasks/register/link-assets-js
 *
 */
module.exports = function(grunt) {
  grunt.registerTask('linkAssetsProd', [
    'sails-linker:prodJs',
    'sails-linker:prodStyles',
    'sails-linker:devTpl',
    'sails-linker:prodJsJade',
    'sails-linker:prodStylesJade',
    'sails-linker:devTplJade'
  ]);
};
