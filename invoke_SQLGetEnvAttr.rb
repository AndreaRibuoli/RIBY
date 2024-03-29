#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLGetEnvAttr.rb" if ARGV.length != 0
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
INFObuffer  = struct [ 'char i[4096]' ]
SQLretsize  = struct [ 'char s[2]' ]
SQLintsize  = struct [ 'char s[4]' ]
preload    = Fiddle.dlopen(nil)
ileloadx   = Fiddle::Function.new( preload['_ILELOADX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                           Fiddle::TYPE_LONG_LONG )
ilesymx    = Fiddle::Function.new( preload['_ILESYMX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
                           Fiddle::TYPE_INT )
ilecallx   = Fiddle::Function.new( preload['_ILECALLX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT],
                           Fiddle::TYPE_INT )
qsqcli = ileloadx.call('QSYS/QSQCLI', 1)
pSQLAllocHandle = ILEpointer.malloc
rc = ilesymx.call(pSQLAllocHandle, qsqcli, 'SQLAllocHandle')
raise "Loading SQLAllocHandle failed" if rc != 1
pSQLGetEnvAttr = ILEpointer.malloc
rc = ilesymx.call(pSQLGetEnvAttr, qsqcli, 'SQLGetEnvAttr')
raise "Loading SQLGetEnvAttr failed" if rc != 1
pSQLConnectW = ILEpointer.malloc
rc = ilesymx.call(pSQLConnectW, qsqcli, 'SQLConnectW')
raise "Loading SQLConnectW failed" if rc != 1
pSQLGetInfoW = ILEpointer.malloc
rc = ilesymx.call(pSQLGetInfoW, qsqcli, 'SQLGetInfoW')
raise "Loading SQLGetInfoW failed" if rc != 1
env_handle = SQLhandle.malloc
ILEarguments = ILEarglist.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0001'].pack("H*")             # htype (SQL_HANDLE_ENV)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = ['00000000'].pack("H*")         # ihandle (SQL_NULL_HANDLE)
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [env_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts 'Environment handle 0x' + env_handle[ 0, 4].unpack("H*")[0]
sizeint = SQLintsize.malloc
buffer  = INFObuffer.malloc
ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
ILEarguments[  64,  4] = ['00001000'].pack("H*")         # 4
ILEarguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
working = []
12000.times { |key|
  key
  ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*") 
  rc = ilecallx.call(pSQLGetEnvAttr, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  working.push(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
}
{ SQL_ATTR_OUTPUT_NTS: 10001,
  SQL_ATTR_SYS_NAMING: 10002,
  SQL_ATTR_DEFAULT_LIB: 10003,
  SQL_ATTR_SERVER_MODE: 10004,
  SQL_ATTR_JOB_SORT_SEQUENCE: 10005,
  SQL_ATTR_ENVHNDL_COUNTER: 10009,
  SQL_ATTR_ESCAPE_CHAR: 10010,
  SQL_ATTR_DATE_FMT: 10020,
  SQL_ATTR_DATE_SEP: 10021,
  SQL_ATTR_TIME_FMT: 10022,
  SQL_ATTR_TIME_SEP: 10023,
  SQL_ATTR_DECIMAL_SEP: 10024,
  SQL_ATTR_INCLUDE_NULL_IN_LEN: 10031,
  SQL_ATTR_UTF8: 10032
}.each { |k,key|
  ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*")
  rc = ilecallx.call(pSQLGetEnvAttr, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  working.delete(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
  puts "#{k.to_s} (#{key}): 0x#{buffer[0, 4].unpack("H*")[0]}"
}
working.each {|key|
  puts "Attribute #{key} unknown"
}
