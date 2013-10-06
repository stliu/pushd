xmpp = require 'node-xmpp'
elements = require './xmpp-elements'
logger = require 'winston'
sys = require 'sys'
async = require 'async'

class Handler
  constructor : (@xmppPublisher) ->
    @client = @xmppPublisher.driver

  iq : (stanza) =>
    logger.verbose "got `iq` message from server:"
    logger.verbose stanza
    if stanza.attrs.type isnt 'error'
       async.each( stanza.children, @next, () -> )

  message : (stanza) ->
    logger.verbose "got `message` from server"
    logger.verbose stanza
    async.each( stanza.children, @next, () -> )

  active : (stanza) ->
    logger.verbose "got `active` from server"
    logger.verbose stanza

  body : (stanza) ->
    logger.verbose "got `body` from server"
    logger.verbose stanza

  ping : (stanza) ->
    if stanza.attrs.xmlns is 'urn:xmpp:ping'
      stanza = stanza.up()
      logger.verbose( 'got ping from server, now we need to response')
      from = stanza.attrs.to
      to = stanza.attrs.from
      stanza.remove('ping', 'urn:xmpp:ping')
      stanza.attrs.to = to
      stanza.attrs.from = from
      stanza.attrs.type = 'result'
      logger.verbose( 'response xml is' )
      logger.verbose stanza
      @client.send stanza
    else
      logger.verbose "got `ping` message but the xmlns[#{stanza.attrs.xmlns}] is not expected"

  presence : (stanza) ->
    logger.verbose "got the presence response:"
    logger.verbose stanza

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
      logger.verbose "got stanza, now going next:"
      logger.verbose stanza
      @next(stanza)

exports.Handler = Handler
