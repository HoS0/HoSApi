module.exports = (HoSCom, uuid, Promise) ->
    class HoSApi
        constructor: (@_serviceContract, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
