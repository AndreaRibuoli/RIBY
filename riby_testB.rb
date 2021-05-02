#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql> <GET/BIND> <val>" if ARGV.length != 5
                                                                       
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
  d1 = Desc.new(s)
  pp d1.desc_data(1)
  d2 = Desc.new(s, false)
  pp d2.desc_data(2)
  pars = []
  m.times {|i| seq = i+1; pars << Param.new(s, seq, s.param_data(seq)) }
  pars.each { |f| f.bind }
  pars[0].buffer= ARGV[4].encode('IBM280')
  pars[0].pcbValue= ARGV[4].length
  puts "Without bind using get"
  s.execute
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.get.to_s << ', '}
    pp row
  end
end
if ARGV[3] == 'BIND'
  s.prepare(ARGV[2])
  n = s.columns_count[:SQL_DESC_COUNT]
  cols = []
  n.times {|i| seq = i+1; cols << Column.new(s, seq, s.column_data(seq)) }
  cols.each { |f| f.bind }
  m = s.numparams
#  d1 = Desc.new(s)
#  pp d1.desc_data(1)
#  d2 = Desc.new(s, false)
#  pp d2.desc_data(2)
  pars = []
  m.times {|i| seq = i+1; pars << Param.new(s, seq, s.param_data(seq)) }
  pars.each { |f| f.bind }
  pars[0].buffer= ARGV[4].encode('IBM280')
  pars[0].pcbValue= ARGV[4].length
  puts "With bind using buffer"
  s.execute
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.buffer.to_s << ', '}
    pp row
  end
end
