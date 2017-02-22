app = angular.module 'predots', [
  'ngMaterial',
  'nvd3',
  'ngWebSocket',
  'ngFileUpload',
  'rzModule',
  'angulartics.google.analytics',
  'ui.router']

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
app.config ['$stateProvider', '$locationProvider', ($stateProvider, $locationProvider) ->

  $stateProvider
    .state 'login',
      url: '/login'
      views:
        superView:
          template: JST['assets/templates/login']
          controller: 'LoginCtrl'
      data:
        authenticate: false
    .state 'predots',
      url: '/'
      views:
        superView:
          template: JST['assets/templates/predots']
          controller: 'AppCtrl'
      data:
        authenticate: true
    .state 'predots.subset',
      url: ''
      views:
        predotsView:
          template: JST['assets/templates/featureSubset']
          controller: 'FeatureSubsetCtrl'
    .state 'predots.selections',
      url: 'selections?select&unselect'
      views:
        predotsView:
          template: JST['assets/templates/featureSubset']
          controller: 'FeatureSubsetCtrl'
    .state 'predots.analyze',
      url: 'analyze'
      views:
        predotsView:
          template: JST['assets/templates/analysis']
          controller: 'AnalysisCtrl'
    .state 'predots.change-target',
      url: 'change-target'
      views:
        predotsView:
          template: JST['assets/templates/featureList']
          controller: 'FeatureListCtrl'
    .state 'predots.change-dataset',
      url: 'change-dataset'
      views:
        predotsView:
          template: JST['assets/templates/changeDataset']
          controller: 'ChangeDatasetCtrl'
    .state 'predots.feature-list',
      url: 'feature-list'
      views:
        predotsView:
          template: JST['assets/templates/featureList']
          controller: 'FeatureListCtrl'
    .state 'predots.feature',
      url: 'feature/:featureName'
      views:
        predotsView:
          template: JST['assets/templates/featureInfo']
          controller: 'FeatureInfoCtrl'

  $locationProvider.html5Mode true
  return
]

# Intercept any request, if user is not loggedin forward to login page
app.factory 'loginInterceptor', ['$q', '$location', ($q, $location) ->
    return {
      responseError: (rejection) ->
        if rejection.status == 403
          $location.path '/login'
        return $q.reject rejection
    }
]

app.config ['$httpProvider', ($httpProvider) ->
    $httpProvider.interceptors.push 'loginInterceptor'
]
