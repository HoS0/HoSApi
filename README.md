# HoSApi

HoS API is in charge of translating HTTP and HTTPS calls into the HoS environment, it listens to the calls on the web API and sends the call into the appropriate service, after which it will send the reply back into the caller.

## Example

You can simply expose an api to your hos environment:

``` javascript
var express = require('express');
var http = require('http');
var bodyParser = require('body-parser');
var hosApi = require('hos-api');

app = express();
hosApi.init().then(function() {
  app = express();
  app.set('port', 8080);
  app.use(bodyParser.json());
  app.use(hosApi.middleware);
  http.createServer(app).listen(app.get('port'), function() {
    console.log('Express server listening on port ' + app.get('port'));
    console.log('make sure hos-auth is running on your environment');
    return;
  });
});
```
After running mentioned code you can open any routes for the given service running and get the response.

Lets step further and plug in swagger validation and middlewares to the environment:

``` javascript
var express = require('express');
var http = require('http');
var bodyParser = require('body-parser');
var hosApi = require('hos-api');
var HoSAuth = require('hos-auth');
var cors = require('cors');

var amqpurl     = "localhost"
var amqpusername    = "guest"
var amqppassword    = "guest"
hosAuth = new HoSAuth(amqpurl, amqpusername, amqppassword)
hosAuth.on('message', (function(msg){ msg.accept(); }));

app = express();
hosAuth.connect()
.then(function() {
    hosApi.init(true, 'localhost:8080').then(function() {
      app = express();
      app.set('port', 8080);
      app.use(cors());
      app.use(bodyParser.json());
      app.use(hosApi.swaggerMetadata);
      app.use(hosApi.swaggerValidator);
      app.use(hosApi.swaggerUi);
      app.use(hosApi.middleware);
      http.createServer(app).listen(app.get('port'), function() {
        console.log('Express server listening on port ' + app.get('port'));
        console.log('try opening http://localhost:8080/docs/');
        return;
      });
    });
});

You need to have a running hos-auth, in this example authentication service simply accept all the incoming calls, in hosApi init method you can specify is you require to initialize swagger middlewere and the host address to serve the swaggerui with, hos-api initializes an instance of hos-controller, collecting swagger docs for each service merging them and serve them as once in `/docs` or `/api-docs` of your host server address, every 10 minutes by default swagger file for the api gets updated.

```

### url

`http://{YOURSERVER}/{SERVICE}/{TASK}/{ID}?{QUERYSTRING}`

- `YOURSERVER`: server address
- `SERVICE`: destination HoS service
- `TASK`: required task from that service
- `ID` (optional): can be used to specify id of resource in specific task
- `QUERYSTRING` (optional): can be used for an query statement recommend to be written as `con1=val1&con2=val2...` destination service specify the requirement.

### headers

- sid (optional): instance of destination service unique id.
- token (optional): user token of the caller, should be provided to authorize the call if needed.

### body

JSON request for destination service, depends on service documentation.

## Time out

For each calls the timeout of 30 sec has been define which will end up in returning 404 if the call does not have a reply in requested time.

## Static pages

Put the static pages in `views` directory and resources in `public` directory, making a `GET` request if the file exist web server will send the `HTML` file to requester.

This software is licensed under the MIT License.
