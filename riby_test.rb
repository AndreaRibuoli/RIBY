#! /QOpenSys/pkgs/bin/ruby
require './riby_qsqcli'

h = Env.new
d = Connect.new(h, '*LOCAL')
d.Empower('*CURRENT','')
s = Stmt.new(d)

puts h::handle.unpack("l")
puts d::handle.unpack("l")
puts s::handle.unpack("l")
