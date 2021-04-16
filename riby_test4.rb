#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

h = Env.new
h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
d1 = Connect.new(h, '*LOCAL')
d1.Empower(ARGV[0],ARGV[1])
s1 = Stmt.new(d1)
puts s1.handle.unpack('l')
s2 = Stmt.new(d1)
puts s2.handle.unpack('l')
GC.stress = true
20.times {
  di = Connect.new(h, '*LOCAL')
  di.Empower(ARGV[0],ARGV[1])
  si = Stmt.new(di)
  puts si.handle.unpack('l')
}
s3 = Stmt.new(d1)
puts s3.handle.unpack('l')
