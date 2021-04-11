require './riby_qsqcli'


h = Env.new
d = Connect.new(h)
s = Stmt.new(d)

puts h::handle
puts d::handle
puts s::handle
