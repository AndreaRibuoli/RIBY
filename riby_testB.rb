#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql> <GET/BIND>" if ARGV.length != 4
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE }
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
# GC.stress = true
s = Stmt.new(c)
s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
if ARGV[3] == 'GET'
  s.prepare(ARGV[2])
  n = s.numcols
  cols = []
  n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
  m = s.numparams
  pars = []
  m.times {|i| seq = i+1; pars << Param.new(s, seq, s.param_data(seq)) }
  pars.each { |f| f.bind }
  pars[0].buffer= [3].pack('s*')
  pars[0].pcbValue= 2
  puts "Without bind using get"
  s.execute
  pp s.error
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.get.to_s << ', '}
    pp row
  end
end
=begin
if ARGV[3] == 'BIND'
  s.prepare(ARGV[2])
  n = s.columns_count[:SQL_DESC_COUNT]
  cols = []
  n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
  cols.each { |f| f.bind }
  puts "With bind using buffer"
  s.execute
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.buffer.to_s << ', '}
    pp row
  end
end
=end
