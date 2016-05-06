contract     = require('./serviceContract')
url          = require('url')
HoSCom       = require('hos-com')
swaggerTools = require('swagger-tools')
Promise      = require 'bluebird'

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

hos = {}
swaggerToolsMiddleware = {}
String.prototype.endsWith = (suffix)->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1

setHeaders= (req, method, pathParts)->
    if req.headers and req.headers.sid
        destinationService += ".#{req.headers.sid}"

    headers =
        method: method
        task: '/' + pathParts[1]

    if req.query
        for key in Object.keys(req.query)
            if req.query[key] is 'true'
                req.query[key] = true
            if req.query[key] is 'false'
                req.query[key] = false

        headers.query = req.query
    if pathParts[2]
        headers.taskId = pathParts[2]
    if req.headers and req.headers.token
        headers.token = req.headers.token
    headers.expiration = 1000
    headers.replyWholeMessage = true
    headers.httpHeaders= {}

    for key in Object.keys(req.headers)
        headers.httpHeaders[key] = req.headers[key]

    return headers

sendHoSMessage = (req, res, next, method)=>
    try
        if typeof req.body is "string"
            req.body = JSON.parse req.body
        body = req.body ? {}

        parseUrl = url.parse(req.url)
        pathParts = parseUrl.pathname.split('/').filter (e)->
            return e.replace(/(\r\n|\n|\r)/gm,"")

        destinationService = '/' + pathParts[0];

        headers = setHeaders(req, method, pathParts)

    catch error
        res.status(400)
        res.send 'wrong argument in the request'
        return

    hos.sendMessage body, destinationService, headers
    .then (reply)=>
        res.status(reply.properties.headers.statusCode ? 200)
        if typeof reply.properties.headers.httpHeaders is 'object'
            for key in Object.keys(reply.properties.headers.httpHeaders)
                res.setHeader key, reply.properties.headers.httpHeaders[key]

        res.json reply.content

    .catch (err)=>
        res.status(err.code)
        res.send JSON.stringify err.reason

getDocPeriodically = (host)=>
    tick = ()->
        hos.sendMessage({} , '/ctrlr', {task: '/tasks', method: 'get', query: {docincluded: true, host: host}})
        .then (replyPayload)=>
            swaggerTools.initializeMiddleware replyPayload.doc, (middleware)->
                swaggerToolsMiddleware = middleware
        .catch
            # ignore
    setInterval(tick, 10 * 60 * 1000);

module.exports =
    init: (useSwaggerTool, host)->
        new Promise (fullfil, reject) =>
            @hos = new HoSCom contract, amqpurl, username, password
            @hos.connect()
            .then ()=>
                hos = @hos
                if useSwaggerTool is true
                    hos.sendMessage({} , '/ctrlr', {task: '/tasks', method: 'get', query: {docincluded: true, host: host}})
                    .then (replyPayload)=>
                        swaggerTools.initializeMiddleware replyPayload.doc, (middleware)->
                            swaggerToolsMiddleware = middleware
                            fullfil()
                            getDocPeriodically(host)
                else
                    fullfil()

    middleware: (req, res, next)->
        if req and req.method
            method = req.method.toLowerCase()
            if req.url.endsWith('.html')
                next()
            else
                sendHoSMessage(req, res, next, method)

    swaggerMetadata: (req, res, next)->
        if swaggerToolsMiddleware
            swaggerToolsMiddleware.swaggerMetadata()(req, res, next)

    swaggerValidator: (req, res, next)->
        if swaggerToolsMiddleware
            swaggerToolsMiddleware.swaggerValidator()(req, res, next)

    swaggerUi: (req, res, next)->
        if swaggerToolsMiddleware
            swaggerToolsMiddleware.swaggerUi()(req, res, next)

    destroy: ()->
        @hos.destroy()
