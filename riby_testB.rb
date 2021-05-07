#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'csv'
                                                                       
raise "Usage: #{__FILE__} <user> <password> <sql> <val> [BIND]" if ARGV.length < 4
                                                                       
e = Env.new
e.attrs = { :SQL_ATTR_SERVER_MODE => :SQL_TRUE,
            :SQL_ATTR_NON_HEXCCSID => :SQL_TRUE }
pp e.error
c = Connect.new(e)
c.empower(ARGV[0], ARGV[1])
s = Stmt.new(c)
s.attrs = { :SQL_ATTR_EXTENDED_COL_INFO => :SQL_TRUE }
s.prepare(ARGV[2])
pp s.error
n = s.numcols
pp s.error
cols = []
n.times {|i|
  seq = i+1
  cols << Column.new(s, seq)
}
cols.each { |f| f.bind } if ARGV[4] == 'BIND'
m = s.numparams
pars = []
m.times {|i|
  seq = i+1
  pars << Param.new(s, seq)
}
pars.each { |f| f.bind }
pars[0].buffer= ARGV[3]
s.execute
records = []
while s.fetch == 0
  row = []
  cols.each { |f|
    row << f.buffer.to_s if ARGV[4] == 'BIND'
    row << f.get.to_s    if ARGV[4] == 'GET'
  }
  records << row
end
CSV.open("../demo.csv", "w") do |csv|
  records.each do |row|
    csv << row
  end
end
