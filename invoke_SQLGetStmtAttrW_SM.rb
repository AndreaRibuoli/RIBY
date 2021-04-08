#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLGetStmtAttrW_SM.rb <user> <pass>" if ARGV.length != 2
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
INFObuffer  = struct [ 'char i[4096]' ]
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
pSQLSetEnvAttr = ILEpointer.malloc
rc = ilesymx.call(pSQLSetEnvAttr, qsqcli, 'SQLSetEnvAttr')
raise "Loading SQLSetEnvAttr failed" if rc != 1
pSQLGetEnvAttr = ILEpointer.malloc
rc = ilesymx.call(pSQLGetEnvAttr, qsqcli, 'SQLGetEnvAttr')
raise "Loading SQLGetEnvAttr failed" if rc != 1

pSQLConnectW = ILEpointer.malloc
rc = ilesymx.call(pSQLConnectW, qsqcli, 'SQLConnectW')
raise "Loading SQLConnectW failed" if rc != 1
pSQLGetStmtAttrW = ILEpointer.malloc
rc = ilesymx.call(pSQLGetStmtAttrW, qsqcli, 'SQLGetStmtAttrW')
raise "Loading SQLGetStmtAttrW failed" if rc != 1
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
sizeint[0, 4] = ['00000001'].pack("H*")
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
ILEarguments[  36,  4] = [ 10004.to_s(16).rjust(8,'0')].pack("H*")
ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")
ILEarguments[  48, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64, 80] = ['0'.rjust(160,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLSetEnvAttr, ILEarguments, ['FFFBFFFBFFF5FFFB0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
sizeint = SQLintsize.malloc
buffer  = INFObuffer.malloc
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
  ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  64,  4] = ['00001000'].pack("H*")         # 4
  ILEarguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*")
  rc = ilecallx.call(pSQLGetEnvAttr, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  puts "#{k.to_s} (#{key}): 0x#{buffer[0, 4].unpack("H*")[0]}" if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
}
dbc_handle = SQLhandle.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0002'].pack("H*")             # htype (SQL_HANDLE_DBC)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = env_handle[ 0, 4]               # ihandle
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [dbc_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts 'DB Connection handle 0x' + dbc_handle[ 0, 4].unpack("H*")[0]
dsn = '*LOCAL'.encode('UTF-16BE')
user = ARGV[0].encode('UTF-16BE')
pass = ARGV[1].encode('UTF-16BE')
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = dbc_handle[ 0, 4]               # hdbc
ILEarguments[  36, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [Fiddle::Pointer[dsn].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[  80, 16] = [Fiddle::Pointer[user].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  96,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[ 112, 16] = [Fiddle::Pointer[pass].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[ 128,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[ 130, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLConnectW, ILEarguments, ['FFFBFFF5FFFDFFF5FFFDFFF5FFFD0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
stm_handle = SQLhandle.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0003'].pack("H*")             # htype (SQL_HANDLE_STM)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = dbc_handle[ 0, 4]               # ihandle
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [stm_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts 'Statement handle 0x' + stm_handle[ 0, 4].unpack("H*")[0]
ILEarguments[  32,  4] = stm_handle[ 0, 4]               # stmt
ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
ILEarguments[  64,  4] = ['00001000'].pack("H*")         # 4
ILEarguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
working = []
12000.times { |key|
  ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*")
  rc = ilecallx.call(pSQLGetStmtAttrW, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  working.push(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
}
{
  SQL_ATTR_APP_ROW_DESC:       10010,
  SQL_ATTR_APP_PARAM_DESC:     10011,
  SQL_ATTR_IMP_ROW_DESC:       10012,
  SQL_ATTR_IMP_PARAM_DESC:     10013,
  SQL_ATTR_FOR_FETCH_ONLY:     10014,
  SQL_ATTR_CURSOR_SCROLLABLE:  10015,
  SQL_ATTR_ROWSET_SIZE:        10016,
  SQL_ATTR_CURSOR_HOLD:        10017,
  SQL_ATTR_FULL_OPEN:          10018,
  SQL_ATTR_EXTENDED_COL_INFO:  10019,
  SQL_ATTR_BIND_TYPE:          10049,
  SQL_ATTR_CURSOR_TYPE:        10050,
  SQL_ATTR_CURSOR_SENSITIVITY: 10051,
  SQL_ATTR_ROW_BIND_TYPE:      10056,
  SQL_ATTR_PARAM_BIND_TYPE:    10057,
  SQL_ATTR_PARAMSET_SIZE:      10058
}.each { |k,key|
  ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*")
  rc = ilecallx.call(pSQLGetStmtAttrW, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  working.delete(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
  puts "#{k.to_s} (#{key}): 0x#{buffer[0, 4].unpack("H*")[0]}"
}
working.each {|key|
  puts "Attribute #{key} unknown"
}
