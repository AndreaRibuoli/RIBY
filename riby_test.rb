require 'riby_qsqcli.rb'


h = RibyCli::Env.new
d = RibyCli::Connect.new(h)
s = RibyCli::Stmt.new(d)
