app = angular.module 'predots', ['ngMaterial', 'ngRoute', 'nvd3']
app.config ['$mdThemingProvider', ($mdThemingProvider) ->
  predotsMap = $mdThemingProvider.extendPalette 'blue'
  $mdThemingProvider.definePalette 'predots', predotsMap
  $mdThemingProvider
		.theme 'default'
		.primaryPalette 'predots'
		.accentPalette 'orange'
  return
]
app.config ['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->
  $routeProvider
		.when('/',
			template: JST['assets/templates/featureList']
			controller: 'FeatureListCtrl')
		.when('/feature-list',
			template: JST['assets/templates/featureList']
			controller: 'FeatureListCtrl')
		.when('/feature/:featureName',
			template: JST['assets/templates/featureInfo']
			controller: 'FeatureInfoCtrl')
  $locationProvider.html5Mode true
  return
]
app.constant 'apiUri', 'http://172.16.18.127/api/'
