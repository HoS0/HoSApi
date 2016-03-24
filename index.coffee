HoSCom              = require('hos-com')
express             = require 'express'
http                = require 'http'
path                = require 'path'
bodyParser          = require 'body-parser'
cors                = require 'cors'
url                 = require 'url'
contract            = require('./src/serviceContract')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

@hos = new HoSCom contract, amqpurl, username, password
@hos.connect().then ()=>
    createHTTPServer()

createHTTPServer= ()=>
    app = express()

    app.set 'port', 8080
    app.set 'views', path.join __dirname, '../views'
    app.set 'view engine', 'html'
    app.use express.static path.join __dirname, '../public'
    app.use bodyParser.json()
    app.use cors()

    http.createServer(app).listen app.get('port'), () ->
        console.log 'Express server listening on port ' + app.get 'port'

    app.post '*', (req, res) ->
        sendHoSMessage(req, res, 'POST')

    app.get '*', (req, res) ->
        sendHoSMessage(req, res, 'GET')

    app.put '*', (req, res) ->
        sendHoSMessage(req, res, 'PUT')

    app.delete '*', (req, res) ->
        sendHoSMessage(req, res, 'DELETE')

sendHoSMessage= (req, res, method)=>
    body = req.body ? {}

    parseUrl = url.parse(req.url.slice(1))
    pathParts = parseUrl.pathname.split('/')

    destinationService = pathParts[0];
    if req.headers and req.headers.sid
        destinationService += ".#{req.headers.sid}"

    headers =
        method: method
        task: pathParts[1]
    if req.query
        headers.query = req.query
    if pathParts[2]
        headers.taskId = pathParts[2]
    if req.headers and req.headers.token
        headers.token = req.headers.token

    headers.expiration = 100

    @hos.sendMessage body, destinationService, headers
    .then (reply)=>
        res.status(200)
        res.send JSON.stringify reply
    .catch (err)=>
        res.status(err.code)
        res.send JSON.stringify err.reason
