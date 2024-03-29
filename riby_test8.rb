#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'
                                                                       
raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2
                                                                       
h = Env.new
h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
# GC.stress = true
1000.times {
  di = Connect.new(h, '*LOCAL')
  di.empower(ARGV[0],ARGV[1])
  Stmt.new(di)
  puts "#{di.handle.unpack('H*')} #{'%10.7f' % Time.now.to_f} Connect: #{di.jobname}"
  di.disconnect
}
h.release
