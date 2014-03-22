xmpp = require 'node-xmpp'
elements = require './xmpp-elements'
logger = require 'winston'
sys = require 'sys'
async = require 'async'

class Handler
  constructor : (@xmppPublisher) ->
    @client = @xmppPublisher.driver
    @q = {}
  send : (stanza) =>
    @client.send(stanza)
    id = stanza.attrs.id
    if(id? and not @q[id]?)
      @q[id] = (result) ->
        logger.verbose("result of id[#{id}] is #{result}")

  iq : (stanza) =>
    logger.verbose "got `iq` message from server:"
    logger.verbose stanza
#    if stanza.attrs.type isnt 'error'
      #check the id from xmpp publisher for handler
    id = stanza.attrs.id
    if id? and @q[id]?
      @q[id](stanza.attrs.type isnt 'error', stanza)
      delete @q[id]
    else
      async.each( stanza.children, @next, () -> )

#  message : (stanza) ->
#    logger.verbose "got `message` from server"
#    logger.verbose stanza
#    async.each( stanza.children, @next, () -> )
#
#  active : (stanza) ->
#    logger.verbose "got `active` from server"
#    logger.verbose stanza
#
#  body : (stanza) ->
#    logger.verbose "got `body` from server"
#    logger.verbose stanza

  ping : (stanza) ->
    if stanza.attrs.xmlns is 'urn:xmpp:ping'
      stanza = stanza.up()
      from = stanza.attrs.to
      to = stanza.attrs.from
      stanza.remove('ping', 'urn:xmpp:ping')
      stanza.attrs.to = to
      stanza.attrs.from = from
      stanza.attrs.type = 'result'
      @client.send stanza
    else
      logger.verbose "got `ping` message but the xmlns[#{stanza.attrs.xmlns}] is not expected"

  presence : (stanza) ->

  next : (stanza) =>
    m = stanza.name
    if @[m]?
      @[m](stanza)
    else
      logger.verbose "there is no handler for #{m}"

  setup : () ->
    #send presence when this client is online
    @client.on 'online', () =>
      @client.send(elements.presence())

    @client.on 'error', (stanza) =>
      #todo some error handle here
      logger.error "something wrong happening"
      logger.error stanza

    @client.on "stanza", (stanza) =>
      @next(stanza)

exports.Handler = Handler
