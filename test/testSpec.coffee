Promise         = require 'bluebird'
express         = require 'express'
http            = require 'http'
bodyParser      = require 'body-parser'
enableDestroy   = require 'server-destroy'
crypto          = require 'crypto'
HosCom          = require 'hos-com'
HoSAuth         = require 'hos-auth'
hosApi          = require '../index'
generalContract = require './serviceContract'

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"
port        = 8089

describe "Create service", ()->
    beforeEach ()->
        @serviceCon = JSON.parse(JSON.stringify(generalContract))
        @serviceCon.serviceDoc.basePath = "/serviceTest#{crypto.randomBytes(4).toString('hex')}"
        @serviceDist = new HosCom @serviceCon, amqpurl, username, password

        @hosAuth = new HoSAuth(amqpurl, username, password)

        @app = express()
        @app.set 'port', port
        @app.use bodyParser.json()
        @app.use hosApi()

    afterEach ()->
        @serviceDist.destroy()
        @server.destroy()
        @hosAuth.destroy()

    it "and it should get all the promisses to connect into hos and send a basic message", (done)->
        @server = http.createServer(@app).listen @app.get('port'), () =>
            promises = []
            promises.push @hosAuth.connect()
            promises.push @serviceDist.connect()

            Promise.all(promises).then ()=>
                body = JSON.stringify({foo: "bar"})

                options =
                    path: "/#{@serviceCon.serviceDoc.basePath}/users"
                    hostname: "localhost",
                    port: port,
                    method: "post",
                    headers:
                        "Content-Type": "application/json",
                        "Content-Length": Buffer.byteLength(body)

                callback = (response)=>
                    str = ''
                    response.on 'data', (chunk)=>
                        str += chunk;
                    response.on 'end', ()=>
                        replyPayload = JSON.parse str
                        expect(replyPayload.foo).toEqual('bar');
                        done()

                request = http.request(options, callback)
                request.end(body)

        enableDestroy(@server);
        @serviceDist.on '/users.post', (msg)=>
            msg.reply(msg.content)

        @hosAuth.on 'message', (msg)=>
            msg.accept()

    it "and it senda a message have the reply change in headers", (done)->
        @server = http.createServer(@app).listen @app.get('port'), () =>
            promises = []
            promises.push @hosAuth.connect()
            promises.push @serviceDist.connect()

            Promise.all(promises).then ()=>
                body = JSON.stringify({foo: "bar"})

                options =
                    path: "/#{@serviceCon.serviceDoc.basePath}/users"
                    hostname: "localhost",
                    port: port,
                    method: "post",
                    headers:
                        "Content-Type": "application/json",
                        "Content-Length": Buffer.byteLength(body)

                callback = (response)=>
                    str = ''
                    response.on 'data', (chunk)=>
                        str += chunk;
                    response.on 'end', ()=>
                        replyPayload = JSON.parse str
                        expect(replyPayload.foo).toEqual('bar');
                        expect(response.headers['x-hos-test']).toEqual('something');
                        expect(response.statusCode).toEqual(301);
                        done()

                request = http.request(options, callback)
                request.end(body)

        enableDestroy(@server);
        @serviceDist.on '/users.post', (msg)=>
            msg.properties.headers.httpHeaders = {'x-hos-test': 'something'}
            msg.properties.headers.statusCode = 301
            msg.reply(msg.content)

        @hosAuth.on 'message', (msg)=>
            msg.accept()
