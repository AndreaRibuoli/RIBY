require './riby_qsqcli'


h = RibyCli::Env.new
d = RibyCli::Connect.new(h)
s = RibyCli::Stmt.new(d)
