#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

h = Env.new
h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
d1 = Connect.new(h, '*LOCAL')
d1.empower(ARGV[0],ARGV[1])
Stmt.new(d1)
Stmt.new(d1)
GC.stress = true
10.times {
  di = Connect.new(h, '*LOCAL')
  di.Empower(ARGV[0],ARGV[1])
  Stmt.new(di)
}
Stmt.new(d1)
