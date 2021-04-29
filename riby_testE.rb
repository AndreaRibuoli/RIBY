#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sch> <nam> <typ>" if ARGV.length != 5
                                                                       
e = Env.new
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
puts "==== s.languages() =========================================================================="
pp s.languages()
pp s.error
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind; pp s.error }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer.to_s << ', ' }
  pp row
end
