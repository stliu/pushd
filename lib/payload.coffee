serial = 0
logger = require 'winston'
util = require 'util'

class Payload
    constructor: (data) ->
        throw new Error('Invalid payload') unless typeof data is 'object'
        logger.verbose "get payload data: #{util.inspect(data)}"
        @id = serial++
        # Read fields
        for own key, value of data
            if typeof key isnt 'string' or key.length == 0
                throw new Error("Invalid field (empty)")

            switch key
                when 'title' then @title = value
                when 'msg' then @msg = value
                when 'sound' then @sound = value
                when 'data' then @data = value

        # Detect empty payload
        sum = 0
        sum += (key for own key of @[type]).length for type in ['title', 'msg', 'data']
        if sum is 0 then throw new Error('Empty payload')

exports.Payload = Payload