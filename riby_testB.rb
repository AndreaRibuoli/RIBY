#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql> <GET/BIND> <val>" if ARGV.length != 5
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE, :SQL_ATTR_NON_HEXCCSID => :SQL_TRUE }
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
# GC.stress = true
s = Stmt.new(c)
s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
if ARGV[3] == 'GET'
  s.prepare(ARGV[2])
  n = s.numcols
  cols = []
  dc = Desc.new(s, false)
  dci = Desc.new(s, false, false)
  head = ''
  n.times {|i| seq = i+1; head << dci.desc_data(seq)[:SQL_DESC_NAME] << ', ' }
  n.times {|i| seq = i+1; cols << Column.new(s, seq, dc.desc_data(seq), dci.desc_data(seq)) }
  m = s.numparams
  pars = []
  dp = Desc.new(s)
  dpi = Desc.new(s, true, false)
  m.times {|i| seq = i+1; pars << Param.new(s, seq, dp.desc_data(seq), dpi.desc_data(seq)) }
  pars.each { |f| f.bind }
  pars[0].buffer= ARGV[4].encode('IBM280')
  pars[0].pcbValue= ARGV[4].length
  puts "Without bind using get"
  puts head
  s.execute
  pp s.error
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.get.to_s << ', '}
    puts row
  end
end
if ARGV[3] == 'BIND'
  s.prepare(ARGV[2])
  n = s.numcols
  cols = []
  dc  = Desc.new(s, false)
  dci = Desc.new(s, false, false)
  head = ''
  n.times {|i| seq = i+1; head << dci.desc_data(seq)[:SQL_DESC_NAME] << ', ' }
  n.times {|i| seq = i+1; cols << Column.new(s, seq, dc.desc_data(seq), dci.desc_data(seq)) }
  cols.each { |f| f.bind }
  m = s.numparams
  pars = []
  dp  = Desc.new(s)
  dpi = Desc.new(s, true, false)
  m.times {|i| seq = i+1; pars << Param.new(s, seq, dp.desc_data(seq), dpi.desc_data(seq)) }
  pars.each { |f| f.bind }
  pars[0].buffer= ARGV[4].encode('IBM280')
  pars[0].pcbValue= ARGV[4].length
  puts "With bind using buffer"
  puts head
  s.execute
  while s.fetch == 0
    row = ''
    cols.each { |f| row << f.buffer.to_s << ', '}
    puts row
  end
end
