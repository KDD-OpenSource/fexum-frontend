app = angular.module 'predots', [
  'ngMaterial',
  'ngRoute',
  'nvd3',
  'ngWebSocket',
  'ngFileUpload',
  'rzModule']

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
      template: JST['assets/templates/featureSubset']
      controller: 'FeatureSubsetCtrl')
    .when('/selections',
      template: JST['assets/templates/featureSubset']
      controller: 'FeatureSubsetCtrl')
    .when('/analyze',
      template: JST['assets/templates/analysis']
      controller: 'AnalysisCtrl')
    .when('/change-target',
      template: JST['assets/templates/featureList']
      controller: 'FeatureListCtrl')
    .when('/change-dataset',
      template: JST['assets/templates/changeDataset']
      controller: 'ChangeDatasetCtrl')
    .when('/feature-list',
      template: JST['assets/templates/featureList']
      controller: 'FeatureListCtrl')
    .when('/feature/:featureName',
      template: JST['assets/templates/featureInfo']
      controller: 'FeatureInfoCtrl')
  $locationProvider.html5Mode true
  return
]
