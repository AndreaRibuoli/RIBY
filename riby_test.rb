#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

h = Env.new
d = Connect.new(h, '*LOCAL')
d.Empower('*CURRENT','')
s = Stmt.new(d)

# puts h.handle.unpack("l")
pp h.attrs
# puts d.handle.unpack("l")
pp d.attrs
# puts s.handle.unpack("l")
pp s.attrs
