contract            = require('./serviceContract')
url                 = require 'url'
HoSCom              = require('hos-com')

amqpurl     = process.env.AMQP_URL ? "localhost"
username    = process.env.AMQP_USERNAME ? "guest"
password    = process.env.AMQP_PASSWORD ? "guest"

String.prototype.endsWith = (suffix)->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1

@hos = new HoSCom contract, amqpurl, username, password
@hos.connect()

setHeaders= (req, method, pathParts)=>
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
    headers.expiration = 1000
    headers.replyWholeMessage = true

    return headers

sendHoSMessage= (req, res, next, method)=>
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
        res.send "wrong argument in the request"
        next()
        return

    @hos.sendMessage body, destinationService, headers
    .then (reply)=>
        res.status(reply.properties.headers.statusCode ? 200)

        if typeof reply.properties.headers.httpHeaders is 'object'
            for key in Object.keys(reply.properties.headers.httpHeaders)
                res.setHeader key, reply.properties.headers.httpHeaders[key]

        res.send JSON.stringify reply.content
        next()
    .catch (err)=>
        res.status(err.code)
        res.send JSON.stringify err.reason
        next()

middlewareWrapper = (o)=>
    if typeof o is 'object' and typeof o.on is 'function'
        o.on 'destroy', ()=>
            @hos.destroy()

    return (req, res, next)->
        if req and req.method
            method = req.method.toLowerCase()
            if req.url.endsWith('.html')
                next()
            else
                sendHoSMessage(req, res, next, method)

module.exports = middlewareWrapper
