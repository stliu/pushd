xmpp = require 'node-xmpp'

exports.register = (id, jid, password, host) ->
    return new xmpp.Element('iq', {id:id, to:host, type:'set'})
    .c('query', {xmlns:'jabber:iq:register'})
      .c('username').t(jid)
    .up()
      .c('password').t(password)
    .up()
      .c('email')
    .up()
      .c('registered')
    .up()
      .c('name')
    .root()
exports.presence = () ->
  return new xmpp.Element('presence', {}).c('show').t('chat').up().c('status').t('this is the push server, enjoy')

exports.message = (id, to, message, host) ->
  target = to
  if not (/.*@ac2$/).test(to)
    target= to+"@"+host
  return new xmpp.Element("message", {
    id: id,
    to: target,
    from: "admin@#{host}",
    type: 'headline'
  }).c("body").t(message).root()

exports.publish = (id, node, message, host) ->
    return new xmpp.Element('iq', {
        id: id,
        to: "pubsub.#{host}",
        type: 'set'
    }).c('pubsub', {
        xmlns: 'http://jabber.org/protocol/pubsub'
    }).c('publish', {
        node: node
    }).c('item').c('entry', {
        xmlns: 'easemob:pubsub'
    }).t(message).root()

exports.subscribe = (id, node, jid, host) ->
  return new xmpp.Element('iq', {
    id: id,
    to: "pubsub.#{host}",
    type: 'set',
    from: "admin@#{host}"
  } ).c('pubsub', {
    xmlns: 'http://jabber.org/protocol/pubsub#owner'
  }).c('subscriptions', {
    node: node
  })
  .c('subscription',{jid: jid, subscription:'subscribed'})
  .root()

#  <iq id="ujG00-6" to="pubsub.ac2" type="set">
#    <pubsub xmlns="http://jabber.org/protocol/pubsub#owner">
#      <delete node='pushtest3'/>
#    </pubsub>
#  </iq>

exports.delete_node = (id, node_name, host) ->
    return new xmpp.Element('iq', {
        id: id,
        to: "pubsub.#{host}",
        type: set
    }).c('pubsub', {
        xmlns: 'http://jabber.org/protocol/pubsub#owner'
    }).c('delete',{
        node: node_name
    }).root()

exports.create_node = (id, node_name, host) ->
    return new xmpp.Element('iq', {
        id: id,
        to: "pubsub.#{host}",
        type: 'set'
    }).c('pubsub', {
        xmlns: 'http://jabber.org/protocol/pubsub'
    }).c('create', {
        node: node_name
    }).up()
    .c('configure', {})
    .c('x', {
        xmlns: 'jabber:x:data',
        type: 'submit'
    })
        .c('field', {
        'var': 'pubsub#persit_items', type: 'boolean'
    }).c('value').t('0')
        .up()
    .up()
        .c('field', {
        'var': 'pubsub#presence_based_delivery', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#deliver_payloads', type: 'boolean'
    }).c('value').t('1')
        .up().up()
        .c('field', {
        'var': 'pubsub#access_model', type: 'list-single'
    }).c('value').t('open')
        .up().up()
        .c('field', {
        'var': 'pubsub#publish_model', type: 'list-single'
    }).c('value').t('open')
        .up().up()
#        .c('field', {
#        'var': 'pubsub#max_items', type: 'list-single'
#    }).c('value').t('-1')
#        .up().up()
        .c('field', {
        'var': 'pubsub#subscribe', type: 'boolean'
    }).c('value').t('1')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_config', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_delete', type: 'boolean'
    }).c('value').t('0')
        .up().up()
        .c('field', {
        'var': 'pubsub#notify_retract', type: 'boolean'
    }).c('value').t('0')
    .root()

