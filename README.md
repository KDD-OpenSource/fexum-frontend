# predots-frontend

The frontend for predots

## Installation

```
npm install -g grunt-cli bower
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


Then access your browser at http://localhost:1337

## Deployment

Automatically compile, link and minify all assets and then deploy to the server

```
grunt deploy --host HOSTNAME
```

## Docker
Docker automatically compiles all files and puts them behind a NGINX proxy. Build a new version using:
```
docker build -t TAG_NAME .
```
