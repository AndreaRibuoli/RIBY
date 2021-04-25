#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql>" if ARGV.length != 3
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
pp c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
# s.execdirect(ARGV[2])
# pp s.error
s.prepare(ARGV[2])
pp s.error
pp s.numcols
pp s.error
pp s.numparams
pp s.error
pp s.columns_count
pp s.error
