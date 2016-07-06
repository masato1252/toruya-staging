@UI ?= {}

UI.define = (name, target) ->
  throw "Defining a namespace requires a name" unless name
  scope = UI
  scopeNames = name.split(".")
  last = scopeNames[scopeNames.length - 1]

  for scopeName in _.initial(scopeNames)
    scope = scope[scopeName] ?= {}
  if _.has(scope, last) &&
     !(typeof scope[last] == "object" && scope[last].constructor == Object)
    throw "UI.#{name} is already defined"

  target = if _.isFunction(target) then target() else target
  scope[last] = _.extend(target, scope[last])
  target
