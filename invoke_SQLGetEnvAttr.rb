#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLAllocHandle.rb <user> <password>" if ARGV.length != 2
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
INFObuffer  = struct [ 'char i[4096]' ]
SQLretsize  = struct [ 'char s[2]' ]
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
buffer = INFObuffer.malloc
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
ILEarguments[  36,  4] = ['00002713'].pack("H*")         # SQL_ATTR_DEFAULT_LIB (10003)
ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  4] = ['00001000'].pack("H*")         # 4096
ILEarguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLGetEnvAttr, ILEarguments, ['FFFBFFFBFFF5FFFB0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts 'SQL_ATTR_DEFAULT_LIB: ' + buffer[ 0, 20].unpack("H*")[0]
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
size   = SQLretsize.malloc
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = dbc_handle[ 0, 4]               # hdbc
ILEarguments[  36,  2] = ['0006'].pack("H*")             # SQL_DRIVER_NAME  (6)
ILEarguments[  38, 10] = ['0'.rjust(20,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  2] = ['1000'].pack("H*")             # 4096
ILEarguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")
rc = ilecallx.call(pSQLGetInfoW, ILEarguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
puts 'SQL_DRIVER_NAME: ' + buffer[ 0, len].force_encoding('UTF-16BE').encode('utf-8')
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  36,  2] = ['0011'].pack("H*")             # SQL_DBMS_NAME  (17)
rc = ilecallx.call(pSQLGetInfoW, ILEarguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
puts 'SQL_DBMS_NAME: ' + buffer[ 0, len].force_encoding('UTF-16BE').encode('utf-8')
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  36,  2] = ['0012'].pack("H*")             # SQL_DBMS_VER  (18)
rc = ilecallx.call(pSQLGetInfoW, ILEarguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
puts 'SQL_DBMS_VER: ' + buffer[ 0, len].force_encoding('UTF-16BE').encode('utf-8')
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  36,  2] = ['00C9'].pack("H*")             # SQL_KEYWORDS  (201)
rc = ilecallx.call(pSQLGetInfoW, ILEarguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
lista = buffer[ 0, len-2].force_encoding('UTF-16BE').encode('utf-8').split(',')
puts 'SQL_KEYWORDS: ' + lista.to_s
