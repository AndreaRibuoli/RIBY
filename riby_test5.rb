#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

h = Env.new
h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
d1 = Connect.new(h, '*LOCAL')
d1.Empower(ARGV[0],ARGV[1])
s1 =Stmt.new(d1)
s2 =Stmt.new(d1)
GC.stress = true
5.times {
  di = Connect.new(h, '*LOCAL')
  di.empower(ARGV[0],ARGV[1])
  Stmt.new(di)
  puts "Connect #{di.handle.unpack('l')[0]}: #{di.jobname}"
}
s3 =Stmt.new(d1)
puts "Statements #{s1.handle.unpack('l')[0]}, #{s2.handle.unpack('l')[0]} and #{s3.handle.unpack('l')[0]} are still allocated"
