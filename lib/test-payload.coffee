Payload = require('./payload').Payload

#data = {
#  'title' : 't1',
#  'msg' : 'm2',
#  'sound' : 's1'
#
#}
#p = new Payload(data)
#
#console.log(p)
#
#console.log('-----------')
#p.compile()
#console.log(p)
#
#console.log("-------------------------")
#
data = {
  'title' : 't1',
  'title.zh' : '标题1',
  'msg' : 'm2',
  'msg.zh' : "这是中文的消息",
  'sound' : 's1',
  'data.d1' : 'd1',
  'var.v1' : 'v1'

}
p = new Payload(data)
console.log(p)

console.log('-----------')
p.compile()
console.log(p)
console.log(p.localizedTitle('zh'))
console.log(p.variable('data.d1'))


#data = {
#  'title' : 'this is ${var.location}, welcome',
#  'title.zh' : '标题1',
#  'msg' : 'm2',
#  'sound' : 's1',
#  'data.d1' : 'd1',
#  'var.v1' : 'v1',
#  'var.location' : '北京'
#
#}
#p = new Payload(data)
#console.log(p)
#
#console.log('-----------')
#p.compile()
#console.log(p)
#console.log(p.localizedTitle('zh'))
#console.log(p.variable('data.d1'))