#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLAllocHandle.rb" if ARGV.length != 0
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
INFObuffer  = struct [ 'char i[256]' ]
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
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts 'Environment handle 0x' + env_handle[ 0, 8].unpack("H*")[0]
dbc_handle = SQLhandle.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0002'].pack("H*")             # htype (SQL_HANDLE_DBC)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = env_handle[ 0, 4]               # ihandle
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [dbc_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts 'DB Connection handle 0x' + dbc_handle[ 0, 8].unpack("H*")[0]
dsn = '*LOCAL'.encode('UTF-16BE')
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = dbc_handle[ 0, 8]               # hdbc
ILEarguments[  36, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [Fiddle::Pointer[dsn].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
# ILEarguments[  80, 16] = [dsn.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = ['0'.rjust(32,'0')].pack("H*")
ILEarguments[  96,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
# ILEarguments[ 112, 16] = [dsn.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[ 112, 16] = ['0'.rjust(32,'0')].pack("H*")
ILEarguments[ 128,  2] = ['FFFD'].pack("H*")             # SQL_NTS
ILEarguments[ 130, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLConnectW, ILEarguments, ['FFFBFFF5FFFDFFF5FFFDFFF5FFFD0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts ILEarguments[  64, 16].unpack("H*")
puts ILEarguments[  80, 16].unpack("H*")
size   = SQLretsize.malloc
buffer = INFObuffer.malloc
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  8] = dbc_handle[ 0, 8]               # hdbc
ILEarguments[  40,  2] = ['0011'].pack("H*")             # SQL_DBMS_NAME  (17)
ILEarguments[  42,  6] = ['0'.rjust(12,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64,  2] = ['0100'].pack("H*")             # 256
ILEarguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")
rc = ilecallx.call(pSQLConnectW, ILEarguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts ILEarguments[  64, 16].unpack("H*")
puts ILEarguments[  80, 16].unpack("H*")
puts 'Returned size 0x' + size[ 0, 2].unpack("H*")[0]
puts 'Returned buffer ' + buffer[ 0, 64].unpack("H*")[0]

