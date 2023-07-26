require 'pycall'

math = PyCall.import_module("math")
puts math.sin(math.pi / 4) - Math.sin(Math::PI / 2)
