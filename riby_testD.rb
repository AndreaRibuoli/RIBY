#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sch> <nam> <typ>" if ARGV.length != 5
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
pp c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
#s.tables(ARGV[2], ARGV[3], ARGV[4])
#s.pkeys(ARGV[2], ARGV[3])
s.fkeys_using(ARGV[2], ARGV[3])
n = s.columns_count[:SQL_DESC_COUNT]
puts n 
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  cols.each { |f| pp f.buffer }
end
c.commit
s1 = Stmt.new(c)
s1.fkeys_used_by(ARGV[2], ARGV[3])
n = s1.columns_count[:SQL_DESC_COUNT]
puts n
cols1 = []
n.times {|i| seq = i+1; cols1 << Column.new(s1, seq, s1.column_data(seq)) }
cols1.each { |f| f.bind }
while s1.fetch == 0
  cols1.each { |f| pp f.buffer }
end
pp s1.error
