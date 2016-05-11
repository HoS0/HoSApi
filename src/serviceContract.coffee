serviceInfo =
  serviceDoc:
    info:
        title: 'Api'
        version: '0.1.0'
        description: 'HoS Api to open HTTP channel into the environment'
    basePath: "/api"
  prefetch: 1
  consumerNumber: 2
  messageTimeout: 30000

module.exports = serviceInfo
