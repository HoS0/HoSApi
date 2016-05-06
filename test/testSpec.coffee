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

describe "Open express app", ()->
    beforeEach (done)->
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

            hosApi.init(true).then ()=>
                done()

    afterEach (done)->
        hosApi.destroy()
        @serviceDist.destroy()
        @hosAuth.destroy()
        @hosController.destroy()
        done()

    it "GET /ctrlr/tasks", (done)->
        @serviceDist.on '/users.post', (msg)=>
            msg.reply(msg.content)

        app = express()
        app.use bodyParser.json()
        app.use hosApi.middleware

        request(app)
        .get('/ctrlr/tasks?docincluded=true')
        .expect 200
        .end (err, res)=>
            if !err
                expect(typeof res.body.doc).toBe('object')
                done()

        return

    it "POST /@serviceCon.serviceDoc.basePath/users", (done)->
        @serviceDist.on '/users.post', (msg)=>
            msg.content.foo = 'not bar'
            msg.reply(msg.content)

        app = express()
        app.use bodyParser.json()
        app.use hosApi.middleware

        request(app)
        .post("/#{@serviceCon.serviceDoc.basePath}/users")
        .send({foo: 'bar'})
        .expect 200
        .end (err, res)=>
            if !err
                expect(res.body.foo).toBe('not bar')
                done()

        return

    it "POST /@serviceCon.serviceDoc.basePath/users", (done)->
        @serviceDist.on '/users.post', (msg)=>
            msg.properties.headers.httpHeaders['x-hos-test']= 'something'
            msg.properties.headers.statusCode = 301
            msg.reply(msg.content)

        app = express()
        app.use bodyParser.json()
        app.use hosApi.middleware

        request(app)
        .post("/#{@serviceCon.serviceDoc.basePath}/users")
        .send({foo: 'bar'})
        .expect 301
        .end (err, res)=>
            if !err
                expect(res.body.foo).toEqual('bar');
                expect(res.headers['x-hos-test']).toEqual('something');
                done()

    it "GET /ctrlr/tasks adding swagger tool", (done)->
        @serviceDist.on '/users.post', (msg)=>
            msg.reply(msg.content)

        app = express()
        app.use bodyParser.json()
        app.use hosApi.swaggerMetadata
        app.use hosApi.swaggerValidator
        app.use hosApi.swaggerUi
        app.use hosApi.middleware

        request(app)
        .get('/docs')
        .expect 303
        .end (err, res)=>
            if !err
                done()


        return
