async = require 'async'
logger = require 'winston'

class PushServices
    services: {}

    addService: (protocol, service) ->
        @services[protocol] = service

    getService: (protocol) ->
        return @services[protocol]

    push: (subscriber, subOptions, payload, cb) ->
        subscriber.get (info) =>
            if info? and info['proto']? then @services[info.proto]?.push(subscriber, subOptions, payload)
            cb() if cb

exports.PushServices = PushServices
