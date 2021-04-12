#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'

h = Env.new
d = Connect.new(h, '*LOCAL')
d.Empower('*CURRENT','')
s = Stmt.new(d)

puts h.handle.unpack("l")
puts h.attrs
puts d.handle.unpack("l")
puts d.attrs
puts s.handle.unpack("l")
