require './riby_qsqcli'


h = Env.new
d = Connect.new(h)
s = Stmt.new(d)

puts h::handle.unpack("H*")
puts d::handle.unpack("H*")
puts s::handle.unpack("H*")

puts h::handle.unpack("l")
puts d::handle.unpack("l")
puts s::handle.unpack("l")
