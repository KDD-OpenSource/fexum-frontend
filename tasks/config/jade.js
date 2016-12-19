/**
 * Precompiles jade templates to a `.jst` file.
 *
 * ---------------------------------------------------------------
 *
 * (i.e. basically it takes JADE files and turns them into tiny little
 *  javascript functions that you pass data to and return HTML. This can
 *  speed up template rendering on the client, and reduce bandwidth usage.)
 *
 * For usage docs see:
 * 		https://github.com/gruntjs/grunt-contrib-jade
 *
 */

module.exports = function(grunt) {

	grunt.config.set('jade', {
		dev: {
			options: {
				client: true
			},
			files: {
				'.tmp/public/jst.js': require('../pipeline').templateFilesToInject
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-jade');
};
