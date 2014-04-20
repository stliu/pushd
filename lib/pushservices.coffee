async = require 'async'
logger = require 'winston'

class PushServices
    services: {}
#    createEvent: (subscriber, event, options) ->
#        subscriber.get (info) =>
#          if info then @services[info.proto]?.createEvent?(subscriber, event, options)

    addService: (protocol, service) ->
        @services[protocol] = service

    getService: (protocol) ->
        return @services[protocol]

    push: (subscriber, subOptions, payload, cb) ->
        subscriber.get (info) =>
            console.log("push to subscriber: " + info.proto)
            if info then @services[info.proto]?.push(subscriber, subOptions, payload)
            cb() if cb

exports.PushServices = PushServices
