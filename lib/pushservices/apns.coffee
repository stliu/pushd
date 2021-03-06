apns = require 'apn'
logger = require 'winston'
util = require 'util'
class PushServiceAPNS
    tokenFormat: /^[0-9a-f]{64}$/i
    validateToken: (token) ->
        if PushServiceAPNS::tokenFormat.test(token)
            return token.toLowerCase()

    constructor: (conf, @logger, tokenResolver) ->
        conf.errorCallback = (errCode, note, device) =>
            @logger?.error("APNS Error #{errCode} for subscriber #{device?.subscriberId}")
        @driver = new apns.Connection(conf)

        @payloadFilter = conf.payloadFilter

        @feedback = new apns.Feedback(conf)
        # Handle Apple Feedbacks
        @feedback.on 'feedback', (feedbackData) =>
            feedbackData.forEach (item) =>
                tokenResolver 'apns', item.device.toString(), (subscriber) =>
                    subscriber?.get (info) ->
                        if info.updated < item.time
                            @logger?.warn("APNS Automatic unregistration for subscriber #{subscriber.id}")
                            subscriber.delete()


    push: (subscriber, subOptions, payload) ->
        subscriber.get (info) =>
            note = new apns.Notification()
            if subOptions?.ignore_message isnt true
                note.alert = payload.title
            #note.badge = badge if not isNaN(badge = (parseInt(info.badge) + 1))
            note.badge = 0
            note.sound = 'default'
            if(payload.data? and payload.data["android:details"]?)
                delete payload.data["android:details"]
            note.payload.data = payload.data

            device = new apns.Device(info.token)
            device.subscriberId = subscriber.id # used for error logging
            logger.verbose "pushing alert [#{util.inspect(note.alert)}] and data[#{util.inspect(note.payload)}] to device #{subscriber.id}"
            @driver.pushNotification note, device
            # On iOS we have to maintain the badge counter on the server
#            subscriber.incr 'badge'

exports.PushServiceAPNS = PushServiceAPNS
