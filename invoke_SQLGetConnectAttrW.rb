#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLGetConnectAttrW.rb <user> <password>" if ARGV.length != 2

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
pSQLConnectW = ILEpointer.malloc
rc = ilesymx.call(pSQLConnectW, qsqcli, 'SQLConnectW')
raise "Loading SQLConnectW failed" if rc != 1
pSQLGetConnectAttrW = ILEpointer.malloc
rc = ilesymx.call(pSQLGetConnectAttrW, qsqcli, 'SQLGetConnectAttrW')
raise "Loading SQLGetConnectAttrW failed" if rc != 1
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
ILEarguments[  80, 16] = ['0'.rjust(32,'0')].pack("H*")
ILEarguments[  96,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[ 112, 16] = [Fiddle::Pointer[pass].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[ 112, 16] = ['0'.rjust(32,'0')].pack("H*")
ILEarguments[ 128,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[ 130, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLConnectW, ILEarguments, ['FFFBFFF5FFFDFFF5FFFDFFF5FFFD0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
sizeint = SQLintsize.malloc
buffer  = INFObuffer.malloc
ILEarguments[  32,  4] = dbc_handle[ 0, 4]               # hdbc
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
  rc = ilecallx.call(pSQLGetConnectAttrW, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  working.push(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
}
{
  SQL_ATTR_TXN_ISOLATION: 0,
  SQL_ATTR_XML_DECLARATION: 2552,
  SQL_ATTR_CURRENT_IMPLICIT_XMLPARSE_OPTION: 2553,
  SQL_ATTR_CONCURRENT_ACCESS_RESOLUTION: 2595,
  SQL_ATTR_AUTO_IPD: 10001,
  SQL_ATTR_ACCESS_MODE: 10002,
  SQL_ATTR_AUTOCOMMIT: 10003,
  SQL_ATTR_DBC_SYS_NAMING: 10004,
  SQL_ATTR_DBC_DEFAULT_LIB: 10005,
  SQL_ATTR_ADOPT_OWNER_AUTH: 10006,
  SQL_ATTR_SYSBAS_CMT: 10007,
  SQL_ATTR_DATE_FMT: 10020,
  SQL_ATTR_DATE_SEP: 10021,
  SQL_ATTR_TIME_FMT: 10022,
  SQL_ATTR_TIME_SEP: 10023,
  SQL_ATTR_DECIMAL_SEP: 10024,
  SQL_ATTR_TXN_EXTERNAL: 10026,
  SQL_ATTR_SAVEPOINT_NAME: 10028,
  SQL_ATTR_INCLUDE_NULL_IN_LEN: 10031,
  SQL_ATTR_UTF8: 10032,
  SQL_ATTR_UCS2: 10035,
  SQL_ATTR_MAX_PRECISION: 10040,
  SQL_ATTR_MAX_SCALE: 10041,
  SQL_ATTR_MIN_DIVIDE_SCALE: 10042,
  SQL_ATTR_HEX_LITERALS: 10043,
  SQL_ATTR_CORRELATOR: 10044,
  SQL_ATTR_CONN_SORT_SEQUENCE: 10046,
  SQL_ATTR_INFO_USERID: 10103,
  SQL_ATTR_INFO_WRKSTNNAME: 10104,
  SQL_ATTR_INFO_APPLNAME: 10105,
  SQL_ATTR_INFO_ACCTSTR: 10106,
  SQL_ATTR_INFO_PROGRAMID: 10107,
  SQL_ATTR_DECFLOAT_ROUNDING_MODE: 10112
}.each { |k,key|
  ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
  ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
  buffer[0, 4] = ['00000000'].pack("H*")
  rc = ilecallx.call(pSQLGetConnectAttrW, ILEarguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
  working.delete(key) if ILEarguments[16, 8].unpack("H*")[0] != 'ffffffffffffffff'
  puts "#{k.to_s} (#{key}): 0x#{buffer[0, 4].unpack("H*")[0]}"
}
working.each {|key|
  puts "Attribute #{key} unknown"
}
