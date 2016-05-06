http            = require 'http'
Promise         = require 'bluebird'
bodyParser      = require 'body-parser'
crypto          = require 'crypto'
HosCom          = require 'hos-com'
HoSAuth         = require 'hos-auth'
generalContract = require './serviceContract'
HoSController   = require 'hos-controller'
request         = require('supertest')
hosApi          = require '../index'
express         = require('express')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"


@serviceCon = JSON.parse(JSON.stringify(generalContract))
@serviceCon.serviceDoc.basePath = "/serviceTest#{crypto.randomBytes(4).toString('hex')}"
@serviceDist = new HosCom @serviceCon, amqpurl, username, password
@hosAuth = new HoSAuth(amqpurl, username, password)
@hosController = new HoSController(amqpurl, username, password)

promises = []
promises.push @hosAuth.connect()
promises.push @serviceDist.connect()
promises.push @hosController.connect()
Promise.all(promises).then ()=>
    @hosAuth.on 'message', (msg)=>
        msg.accept()

    hosApi.init(true, 'localhost:8091').then ()=>
        @serviceDist.on '/users.post', (msg)=>
            msg.reply(msg.content)

        app = express()
        app.set 'port', 8091
        app.use bodyParser.json()
        app.use hosApi.swaggerMetadata
        app.use hosApi.swaggerValidator
        app.use hosApi.swaggerUi
        app.use hosApi.middleware

        http.createServer(app).listen app.get('port'), () ->
            console.log 'Express server listening on port ' + app.get 'port'
