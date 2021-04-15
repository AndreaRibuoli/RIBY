#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

h = Env.new
h.attrs=({:SQL_ATTR_SERVER:MODE => :SQL_TRUE})
d1 = Connect.new(h, '*LOCAL')
d1.Empower(ARGV[0],ARGV[1])
s1 = Stmt.new(d1)
{
  d2 = Connect.new(h, '*LOCAL')
  d2.Empower(ARGV[0],ARGV[1])
  s2 = Stmt.new(d2)
}
s3 = Stmt.new(d1)
s4 = Stmt.new(d1)
