HoSCom      = require 'hos-com'
express     = require 'express'
http        = require 'http'
path        = require 'path'
bodyParser  = require 'body-parser'
cors        = require 'cors'
HosAuth     = require 'hos-auth'
hos         = require '../src/HoSApi'

port        = process.env.HOS_API_PORT ? 8080
amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

app = express()

app.set 'port', port
app.set 'view engine', 'html'
app.use express.static path.join __dirname, '../public'
app.use express.static path.join __dirname, '../views'
app.use bodyParser.json()
app.use cors()
app.use hos()

http.createServer(app).listen app.get('port'), () ->
    console.log 'Express server listening on port ' + app.get 'port'

@HoSAuth = new HosAuth(amqpurl, username, password)
@HoSAuth.connect()
@HoSAuth.on 'message', (msg)=>
    if msg.properties.headers.method is 'post' and msg.content.foo is "bar"
        msg.reject("ali happy")
