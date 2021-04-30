#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql>" if ARGV.length != 3
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
# GC.stress = true
s = Stmt.new(c)
20.times {
  s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
  s.prepare(ARGV[2])
  n = s.columns_count[:SQL_DESC_COUNT]
  cols = []
  n.times {|i|
    seq = i+1
    cols << Column.new(s, seq, s.column_data(seq))
  }
  puts "Without bind using get"
  s.execute
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.get.to_s << ', '}
    pp row
  end
  s.close
}
return
cols = []
s.close
s.prepare(ARGV[2])
n = s.columns_count[:SQL_DESC_COUNT]
n.times {|i|
  seq = i+1
  cols << Column.new(s, seq, s.column_data(seq))
}
cols.each { |f|
  f.bind
}
s.execute
puts "With bind using buffer"
while s.fetch == 0
  row = ''
  cols.each { |f| row << f.buffer.to_s << ', '}
  pp row
end


