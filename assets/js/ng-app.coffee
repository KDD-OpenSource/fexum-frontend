app = angular.module 'predots', ['ngMaterial', 'ngRoute', 'nvd3', 'ngWebSocket']

# Define theme
app.config ['$mdThemingProvider', ($mdThemingProvider) ->
  predotsMap = $mdThemingProvider.extendPalette 'blue'
  $mdThemingProvider.definePalette 'predots', predotsMap
  $mdThemingProvider
		.theme 'default'
		.primaryPalette 'predots'
		.accentPalette 'orange'
  return
]

# Define routes
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
app.constant 'socketUri', 'ws://172.16.18.127/socket'
app.constant 'chartTemplates',
  lineChart:
    options:
      chart:
        type: 'lineChart'
        x: (data) -> data.x
        y: (data) -> data.y
        valueFormat: d3.format '.2e'
        xAxis:
          tickFormat: d3.format '.2e'
        yAxis:
          tickFormat: d3.format '.2e'
        margin:
          top: 20
          right: 20
          bottom: 45
          left: 60
  historicalBarChart:
    options:
      chart:
        type: 'historicalBarChart'
        x: (data) -> data.range[1]
        y: (data) -> data.count
        valueFormat: d3.format '.2e'
        xAxis:
          axisLabel: 'Value'
          tickFormat: d3.format '.2e'
        yAxis:
          axisLabel: 'Count'
          tickFormat: d3.format '.2e'
        margin:
          top: 20
          right: 20
          bottom: 45
          left: 60
  multiBarChart:
    options:
      chart:
        type: 'multiBarChart'
        x: (data) -> data.x
        y: (data) -> data.y
        valueFormat: d3.format '.2e'
        xAxis:
          tickFormat: d3.format '.2e'
        yAxis:
          tickFormat: d3.format '.2e'
        margin:
          top: 50
          right: 20
          bottom: 45
          left: 60
