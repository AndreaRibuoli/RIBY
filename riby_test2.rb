#! /QOpenSys/pkgs/bin/ruby
require_relative 'riby_qsqcli'
require 'pp'

raise "Usage: invoke_SQLGetConnectAttrW.rb <user> <password>" if ARGV.length != 2

h = Env.new
h.attrs=({:SQL_ATTR_DATE_FMT    => :SQL_FMT_EUR,
          :SQL_ATTR_INCLUDE_NULL_IN_LEN => :SQL_FALSE,
          :SQL_ATTR_ESCAPE_CHAR => '@'
          :SQL_ATTR_DEFAULT_LIB => 'INTELLIGEN',
         })
d = Connect.new(h, '*LOCAL')
d.Empower(ARGV[0],ARGV[1])
d.attrs=({:SQL_ATTR_TIME_FMT        => :SQL_FMT_EUR,
          :SQL_ATTR_DBC_DEFAULT_LIB => 'PROVAPIENA'
         })
s = Stmt.new(d)
s.attrs=({:SQL_ATTR_FOR_FETCH_ONLY => :SQL_TRUE})
pp h.attrs
pp d.attrs
pp s.attrs
