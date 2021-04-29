#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sch> <nam> <typ>" if ARGV.length != 5
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
puts "==== s.tables('#{ARGV[2]}', '#{ARGV[3]}', '#{ARGV[4]}') ==========================================="
s.tables(ARGV[2], ARGV[3], ARGV[4])
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer.to_s << ', ' }
  pp row
end
s = Stmt.new(c)
puts "==== s.pkeys('#{ARGV[2]}', '#{ARGV[3]}') ====================================================="
s.pkeys(ARGV[2], ARGV[3])
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer << ', ' }
  pp row
end
s = Stmt.new(c)
puts "==== s.fkeys_using('#{ARGV[2]}', '#{ARGV[3]}') ==============================================="
s.fkeys_using(ARGV[2], ARGV[3])
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer << ', ' }
  pp row
end
s = Stmt.new(c)
puts "==== s.fkeys_used('#{ARGV[2]}', '#{ARGV[3]}') ================================================"
s.fkeys_used_by(ARGV[2], ARGV[3])
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer << ', ' }
  pp row
end
s = Stmt.new(c)
puts "==== s.columns('#{ARGV[2]}', '#{ARGV[3]}', '%') =============================================="
s.columns(ARGV[2], ARGV[3], '%')
n = s.columns_count[:SQL_DESC_COUNT]
cols = []
n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
cols.each { |f| f.bind }
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer.to_s << ', ' }
  pp row
end
s = Stmt.new(c)
puts "==== s.languages() =========================================================================="
s.languages()
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
