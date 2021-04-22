#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sch> <nam> <typ>" if ARGV.length != 5
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
pp c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
s.tables(ARGV[2], ARGV[3], ARGV[4])
pp s.error(0)
s2 = Stmt.new(c)
s2.primarykeys(ARGV[2], ARGV[3])
pp s2.error(0)
pp c.error
