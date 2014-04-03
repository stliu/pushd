events = require 'events'
Payload = require('./payload').Payload

class EventPublisher extends events.EventEmitter
    constructor: (@pushServices, @logger) ->

    send: (subscriber, data, cb) ->
        try
            payload = new Payload(data)
            @pushServices.push(subscriber, {}, payload)
        catch e
            @logger.error 'Invalid payload ' + e
            cb(-1) if cb
            return


    publish: (event, data, cb) ->
        try
            payload = new Payload(data)
#            payload.event = event
        catch e
            # Invalid payload (empty, missing key or invalid key format)
            @logger.error 'Invalid payload ' + e
            cb(-1) if cb
            return
      # 广播这个消息出去, 这是因为下面的逻辑其实是获取到每一个subscriber, 然后对其依次调用push service
      # 这样, xmpp的pubsub就没办法了, 而通过接收这个广播消息, xmpp的pubsub就可以工作了
        @.emit('publish_event', event, payload)
        @.emit(event.name, event, payload)

        event.exists (exists) =>
            if not exists
                @logger.verbose "Tried to publish to a non-existing event #{event.name}"
                cb(0) if cb
                return

            @logger.verbose "Pushing message for event #{event.name}"
            @logger.silly 'Title: ' + payload.title
            @logger.silly payload.msg

            protoCounts = {}
            action = (subscriber, subOptions, done) =>
              # action
              subscriber.get (info) =>
                if info?.proto?
                  if protoCounts[info.proto]?
                    protoCounts[info.proto] += 1
                  else
                    protoCounts[info.proto] = 1

              @pushServices.push(subscriber, subOptions, payload, done)

            finished =  (totalSubscribers) =>
              # finished
              @logger.verbose "Pushed to #{totalSubscribers} subscribers"
              for proto, count of protoCounts
                @logger.verbose "#{count} #{proto} subscribers"

              if totalSubscribers > 0
                # update some event' stats
                event.log =>
                  cb(totalSubscribers) if cb
              else
                # if there is no subscriber, cleanup the event
                event.delete =>
                  cb(0) if cb

            event.forEachSubscribers(action, finished)

exports.EventPublisher = EventPublisher