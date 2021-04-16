#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

h = Env.new
puts "Env #{h.handle.unpack('l')[0]}"
h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
d1 = Connect.new(h, '*LOCAL')
puts "Connect #{d1.handle.unpack('l')[0]}"
d1.Empower(ARGV[0],ARGV[1])
s1 = Stmt.new(d1)
puts "Stmt #{s1.handle.unpack('l')[0]}"
s2 = Stmt.new(d1)
puts "Stmt #{s2.handle.unpack('l')[0]}"
GC.stress = true
20.times {
  di = Connect.new(h, '*LOCAL')
  puts "Connect #{di.handle.unpack('l')[0]}"
  di.Empower(ARGV[0],ARGV[1])
  si = Stmt.new(di)
  puts "Stmt #{si.handle.unpack('l')[0]}"
}
s3 = Stmt.new(d1)
puts "Stmt #{s3.handle.unpack('l')[0]}"
