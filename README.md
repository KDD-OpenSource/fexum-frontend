# *framework_name*-frontend

This is the frontend implementation of *framework_name*, a tool to explain relationships in Feature Selection. It allows the user to upload and explore datasets on an interactive feature map. Individual features may also be selected and their distributions inspected, explaining the correlations between them and enabling the user to select a good feature subset.

*Nice screenshot here*

The web app is built on AngularJS, D3.js, and implemented in CoffeeScript. All calculations are done by a Python Django backend (implementation [here](https://github.com/KDD-OpenSource/predots)), which uses a [Python implementation](https://github.com/KDD-OpenSource/python-hics) of the HiCS algorithm, described in [this paper](http://ieeexplore.ieee.org/abstract/document/6228154/), for relevance and redundancy estimation.

## Installation

```
npm install -g grunt-cli bower coffeelint
npm install
bower install
```

## Build frontend

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

## Build & serve locally

To build and serve locally without minification (and watch for changes)

```
grunt
grunt serve		# alternatively
```

To build and serve in production mode with minification (not watching for changes)

```
grunt serveProd
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
