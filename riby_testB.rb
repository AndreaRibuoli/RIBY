#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'csv'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql> <val> [BIND]" if ARGV.length < 4
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE,
            :SQL_ATTR_NON_HEXCCSID => :SQL_TRUE }
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
s.prepare(ARGV[2])
n = s.numcols
cols = []
head = []
dci = Desc.new(s, false, false)
n.times {|i|
  seq = i+1
  head << dci.desc_data(seq)[:SQL_DESC_NAME]
  cols << Column.new(s, seq)
}
cols.each { |f| f.bind } if ARGV[4] == 'BIND'
m = s.numparams
pars = []
dpa = Desc.new(s)
dpi = Desc.new(s, true, false)
m.times {|i|
  seq = i+1
  da = dpa.desc_data(seq)
  di = dpi.desc_data(seq)
  pars << Param.new(s, seq, da, di)
}
pars.each { |f| f.bind }
pars[0].buffer= ARGV[3].encode('IBM280')
pars[0].pcbValue= ARGV[3].length
s.execute
records = [head]
while s.fetch == 0
  row = []
  cols.each { |f|
    if ARGV[4] == 'BIND'
      row << f.buffer.to_s
    else
      row << f.get.to_s
    end
  }
  records << row
end
CSV.open("../demo.csv", "w") do |csv|
  records.each do |row|
    csv << row
  end
end
