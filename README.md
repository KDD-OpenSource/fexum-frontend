# FEXUM frontend
_Framework for Exploring and Understanding Multivariate Correlations_

This repository contains the web frontend of [FEXUM](https://github.com/KDD-OpenSource/fexum) and
is built on [AngularJS](https://angularjs.org), [D3.js](https://d3js.org), and [CoffeeScript](http://coffeescript.org).

It allows the user to upload and explore datasets on an interactive feature map. Individual features may also be selected and their distributions inspected, explaining the correlations between them and enabling the user to select a good feature subset.

![screenshot](https://raw.githubusercontent.com/KDD-OpenSource/fexum-frontend/gallery/screenshot.png)

The basis for this application has been made into a [paper](https://doi.org/10.1007/978-3-319-71273-4_40), which was submitted to and accepted by ECML PKDD 2017, and published as part of the conference proceedings in the "Lecture Notes in Computer Science" (LNCS) series.

## Contributors
* [Louis Kirsch](https://github.com/timediv)
* [Niklas Riekenbrauck](https://github.com/nikriek)
* [Daniel Thevessen](https://github.com/danthe96)
* [Marcus Pappik](https://github.com/marcuspappik)
* [Axel Stebner](https://github.com/xasetl)
* [Julius Kunze](https://github.com/JuliusKunze)
* [Alexander Meißner](https://github.com/Lichtso)


## Installation
```
npm install -g grunt-cli bower coffeelint
npm install
bower install
```

## Building
Compile and link assets
```
grunt build
```

Also minify for production use
```
grunt buildProd
```

Parameters
- `--out=directory` output directory (default: www)

## Serve locally
To build and serve locally without minification (and watch for changes)
```
grunt serve
```

Parameters
- `--port=PORT` allows specifying a port to serve on (default: 1337)
- `--api-host=HOST` specify the host to use as the application's API (default: 172.16.18.127)
- `--api-port=PORT` specify the API's port (default: 80)
- `--api-websocket-port=PORT` specify the websocket's port (default: 80)

Then access your browser at http://localhost:1337

## Deployment
Automatically compile, link and minify all assets and then deploy to the server
```
grunt deploy --host HOSTNAME
```
