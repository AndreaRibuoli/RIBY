#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLAllocHandle.rb <dsn> <user> <pass>" if ARGV.length != 3
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
SQLerror    = struct [ 'char e[4]' ]
SQLstate    = struct [ 'char s[12]' ]
SQLmsg      = struct [ 'char s[1026]' ]
SQLmsglen   = struct [ 'char l[2]' ]
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
pSQLErrorW = ILEpointer.malloc
rc = ilesymx.call(pSQLErrorW, qsqcli, 'SQLErrorW')
raise "Loading SQLErrorW failed" if rc != 1
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
dsn  = ARGV[0].encode('UTF-16BE')
user = ARGV[1].encode('UTF-16BE')
pass = ARGV[2].encode('UTF-16BE')
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
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts ILEarguments[  64, 16].unpack("H*")
puts ILEarguments[  80, 16].unpack("H*")
puts ILEarguments[  96, 16].unpack("H*")
puts ILEarguments[ 112, 16].unpack("H*")
puts ILEarguments[ 128, 16].unpack("H*")
state  = SQLstate.malloc
error  = SQLerror.malloc
msg    = SQLmsg.malloc
msglen = SQLmsg.malloc
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
ILEarguments[  36,  4] = dbc_handle[ 0, 4]               # hdbc
ILEarguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
ILEarguments[  48, 16] = [state.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64, 16] = [error.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = [msg.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  96,  2] = ['0402'].pack("H*")             # SQL_NTS
ILEarguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[ 112, 16] = [msglen.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLErrorW, ILEarguments, ['FFFBFFFBFFFBFFF5FFF5FFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[   0, 16].unpack("H*")
puts ILEarguments[  16, 16].unpack("H*")
puts ILEarguments[  32, 16].unpack("H*")
puts ILEarguments[  48, 16].unpack("H*")
puts ILEarguments[  64, 16].unpack("H*")
puts ILEarguments[  80, 16].unpack("H*")
puts ILEarguments[  96, 16].unpack("H*")
puts ILEarguments[ 112, 16].unpack("H*")
puts ILEarguments[ 128, 16].unpack("H*")
puts msglen[0, 2].unpack("H*")[0]

