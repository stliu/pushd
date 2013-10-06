async = require 'async'
logger = require 'winston'

class PushServices
    services: {}
    createEvent: (subscriber, event, options) ->
        for own protocol, service of @services
            service.createEvent? subscriber, event, options
#            if service.createEvent?
#                service.createEvent subscriber, event, options

    addService: (protocol, service) ->
        @services[protocol] = service

    getService: (protocol) ->
        return @services[protocol]

    push: (subscriber, subOptions, payload, cb) ->
        subscriber.get (info) =>
            if info then @services[info.proto]?.push(subscriber, subOptions, payload)
            cb() if cb



exports.PushServices = PushServices
