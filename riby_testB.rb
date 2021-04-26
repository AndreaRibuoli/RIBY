#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql>" if ARGV.length != 3
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
pp c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
# s.execdirect(ARGV[2])
# pp s.error
s.prepare(ARGV[2])
pp s.error
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i|
  seq = i+1
   cols << Column.new(s, seq, s.column_data(seq))
}
cols.each { |c|
  c.bind
}
s.execute
pp s.error
s.fetch
cols.each { |c|
  pp c.buffer
}
