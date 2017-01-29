/**
 * String replace tasks
 *
 * ---------------------------------------------------------------
 *
 * Replaces strings in given files
 * 		Currently this is only used to have multiple d3 versions included
 *
 */

module.exports = function(grunt) {

	grunt.config.set('string-replace', {
		versionFix: {
			src: './assets/vendor/d3-v4/d3.js',
			dest: './assets/vendor/d3-v4/d3.js',
			options: {
				replacements: [{
						pattern: /global.d3/g,
						replacement: 'global.d4'
				}]
			}
		}
	});

	grunt.loadNpmTasks('grunt-string-replace');
};
