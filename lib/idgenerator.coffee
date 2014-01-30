random = require('secure_random');

class Generator
  start = 10000;
  end = 9999999;

  constructor: (@redis, @key) ->

  gen: (cb) =>
    random.getRandomInt start, end, (e1, value) =>
      if e1?
        cb(e1)
      else
        @redis.setbit @key, (value - start), 1, (e2, exist)->
          if e2?
            cb(e2)
          else
            if(exist == 0)
              cb(null, value)
            else
              gen(cb)

exports.Generator = Generator
