#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sch> <nam> <typ>" if ARGV.length != 5
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
pp c.empower(ARGV[0], ARGV[1])
#s2 = Stmt.new(c)
#s2.primarykeys(ARGV[2], ARGV[3])
#pp s2.error(1)
s = Stmt.new(c)
s.tables(ARGV[2], ARGV[3], ARGV[4])
n = s.columns_count[:SQL_DESC_COUNT]
puts n 
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
pp cols
while s.fetch == 0
  cols.each { |f| pp f.buffer }
end

#s3 = Stmt.new(c)
#s3.foreignkeys(ARGV[2], ARGV[3], '', '')
#pp s3.error(1)
#s4 = Stmt.new(c)
#s4.indexes(ARGV[2], ARGV[3])
#pp s4.error(1)
