#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: #{__FILE__} <user> <password>" if ARGV.length != 2

15.times {
  h = Env.new
  h.attrs=({:SQL_ATTR_SERVER_MODE => :SQL_TRUE})
  di = Connect.new(h, '*LOCAL')
  di.Empower(ARGV[0],ARGV[1])
  Stmt.new(di)
  puts "DB Connect #{di.handle.unpack('l')[0]}: #{di.jobname}"
}
