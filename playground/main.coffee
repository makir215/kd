class V extends KDView
  constructor: (options, data) ->
    super options, data

  viewAppended: ->
    console.log 'view appended is called for', @options.name
    console.trace()
    super()

a = new V name: 'a'
b = new V name: 'b'
c = new V name: 'c'
d = new V name: 'd'

a.addSubView b
b.addSubView c
c.addSubView d

a.appendToDomBody()
