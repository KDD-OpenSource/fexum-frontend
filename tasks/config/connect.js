/**
 * `connect`
 *
 * ---------------------------------------------------------------
 *
 * Run a static web server for serving during development
 *
 * For usage docs see:
 *   https://github.com/gruntjs/grunt-contrib-connect
 *   https://github.com/drewzboto/grunt-connect-proxy
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
        },
        middleware: function (connect, options, defaultMiddleware) {
          var proxy = require('grunt-connect-proxy/lib/utils').proxyRequest;
          return [proxy].concat(defaultMiddleware);
        }
      },
      proxies: [{
        context: ['/socket', '/api'],
        host: grunt.option('api-host') || '172.16.18.127',
        port: grunt.option('api-port') || 80,
        ws: true,
        https: false,
        xforward: false
      }]
    }
  });

  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-connect-proxy');
};
