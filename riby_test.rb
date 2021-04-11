require 'riby_test.rb'


h = RibyCli::Env.new
d = RibyCli::Connect.new(h)
s = RibyCli::Stmt.new(d)
