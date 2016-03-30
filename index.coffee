HoSCom              = require('hos-com')
express             = require 'express'
http                = require 'http'
path                = require 'path'
bodyParser          = require 'body-parser'
cors                = require 'cors'
url                 = require 'url'
contract            = require('./src/serviceContract')
HosAuth             = require('hos-auth')
fs                  = require('fs')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

port        = process.env.HOS_API_PORT ? 8080

String.prototype.endsWith = (suffix)->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1

@hos = new HoSCom contract, amqpurl, username, password
@hos.connect().then ()=>
    createHTTPServer()

createHTTPServer= ()=>
    app = express()

    app.set 'port', port
    app.set 'views', path.join __dirname, '../views'
    app.set 'view engine', 'html'
    app.use express.static path.join __dirname, '../public'
    app.use bodyParser.json()
    app.use cors()

    http.createServer(app).listen app.get('port'), () ->
        console.log 'Express server listening on port ' + app.get 'port'

    app.post '*', (req, res) ->
        sendHoSMessage(req, res, 'post')

    app.get '*', (req, res) ->
        if req.url.endsWith('.html')
            try
                if fs.statSync(path.join __dirname, "views/" + req.url.slice(1)).isFile()
                    res.sendFile path.join __dirname,"views/" + req.url.slice(1)
                else
                    sendHoSMessage(req, res, 'get')
            catch error
                sendHoSMessage(req, res, 'get')
        else
            sendHoSMessage(req, res, 'get')


    app.put '*', (req, res) ->
        sendHoSMessage(req, res, 'put')

    app.delete '*', (req, res) ->
        sendHoSMessage(req, res, 'delete')

sendHoSMessage= (req, res, method)=>
    try
        body = req.body ? {}

        parseUrl = url.parse(req.url.slice(1))
        pathParts = parseUrl.pathname.split('/')

        destinationService = '/' + pathParts[0];
        if req.headers and req.headers.sid
            destinationService += ".#{req.headers.sid}"

        headers =
            method: method
            task: '/' + pathParts[1]
        if req.query
            headers.query = req.query
        if pathParts[2]
            headers.taskId = pathParts[2]
        if req.headers and req.headers.token
            headers.token = req.headers.token
        headers.expiration = 100

    catch error
        res.status(400)
        res.send "wrong argument in the request"
        return

    @hos.sendMessage body, destinationService, headers
    .then (reply)=>
        res.status(200)
        res.send JSON.stringify reply
    .catch (err)=>
        res.status(err.code)
        res.send JSON.stringify err.reason
