#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLAllocHandle.rb <sql> <user> <pass>" if ARGV.length != 3
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[144]' ]
SQLhandle   = struct [ 'char a[4]' ]
SQLerror    = struct [ 'char e[4]' ]
SQLstate    = struct [ 'char s[12]' ]
SQLmsg      = struct [ 'char s[1026]' ]
SQLmsglen   = struct [ 'char l[2]' ]
SQLintsize  = struct [ 'char s[4]' ]

stm = ARGV[0].encode('UTF-16BE')
len = stm.length
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
pSQLConnectW = ILEpointer.malloc
rc = ilesymx.call(pSQLConnectW, qsqcli, 'SQLConnectW')
raise "Loading SQLConnectW failed" if rc != 1
pSQLExecDirectW = ILEpointer.malloc
rc = ilesymx.call(pSQLExecDirectW, qsqcli, 'SQLExecDirectW')
raise "Loading SQLExecDirectW failed" if rc != 1
pSQLErrorW = ILEpointer.malloc
rc = ilesymx.call(pSQLErrorW, qsqcli, 'SQLErrorW')
raise "Loading SQLErrorW failed" if rc != 1
pSQLEndTran = ILEpointer.malloc
rc = ilesymx.call(pSQLEndTran, qsqcli, 'SQLEndTran')
raise "Loading SQLEndTran failed" if rc != 1
pSQLTransact = ILEpointer.malloc
rc = ilesymx.call(pSQLTransact, qsqcli, 'SQLTransact')
raise "Loading SQLTransact failed" if rc != 1
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
dbc_handle = SQLhandle.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0002'].pack("H*")             # htype (SQL_HANDLE_DBC)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = env_handle[ 0, 4]               # ihandle
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [dbc_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
dsn  = '*LOCAL'.encode('UTF-16BE')
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
stm_handle = SQLhandle.malloc
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  2] = ['0003'].pack("H*")             # htype (SQL_HANDLE_STM)
ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
ILEarguments[ 36,  4] = dbc_handle[ 0, 4]               # ihandle
ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
ILEarguments[ 48, 16] = [stm_handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLAllocHandle, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[ 32,  4] = stm_handle[ 0, 4]               # hstmt
ILEarguments[ 36, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
ILEarguments[ 48, 16] = [Fiddle::Pointer[stm].to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[ 64,  4] = [len.to_s(16).rjust(8,'0')].pack("H*")
ILEarguments[ 68, 84] = ['0'.rjust(168,'0')].pack("H*")  # padding
rc = ilecallx.call(pSQLExecDirectW, ILEarguments, ['FFFBFFF5FFFB0000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
exec_rc = ILEarguments[16, 8].unpack("l")[0]
state  = SQLstate.malloc
error  = SQLerror.malloc
msg    = SQLmsg.malloc
msglen = SQLmsg.malloc
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = env_handle[ 0, 4]               # henv
ILEarguments[  36,  4] = dbc_handle[ 0, 4]               # hdbc
ILEarguments[  40,  8] = stm_handle[ 0, 4]               # hstmt
ILEarguments[  48, 16] = [state.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  64, 16] = [error.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  80, 16] = [msg.to_i.to_s(16).rjust(32,'0')].pack("H*")
ILEarguments[  96,  2] = ['0402'].pack("H*")             # SQL_NTS
ILEarguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
ILEarguments[ 112, 16] = [msglen.to_i.to_s(16).rjust(32,'0')].pack("H*")
rc = ilecallx.call(pSQLErrorW, ILEarguments, ['FFFBFFFBFFFBFFF5FFF5FFF5FFFDFFF50000'].pack("H*"), -5, 0)
raise "ILE system failed with rc=#{rc}" if rc != 0
l = msglen[0, 2].unpack("H*")[0].to_i(16) * 2
final =<<END_HERE
RC=#{exec_rc};
SQLSTATE=#{state[0, 12].force_encoding('UTF-16BE').encode('utf-8')}
ERROR=#{error[0, 4].unpack("l")[0]}
MSG=#{msg[0, l].force_encoding('UTF-16BE').encode('utf-8')}
END_HERE
puts final if (exec_rc != 0) || (l>0)
ILEarguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
ILEarguments[  32,  4] = ['0002'].pack("H*")              # SQL_HANDLE_DBC
ILEarguments[  34,  2] = ['0'.rjust(12,'0')].pack("H*")   # padding
ILEarguments[  36,  4] = dbc_handle[ 0, 4]                # hdbc
ILEarguments[  40, 104] = ['0'.rjust(208,'0')].pack("H*") # padding
rc = ilecallx.call(pSQLEndTran, ILEarguments, ['FFFDFFFBFFFD0000'].pack("H*"), -5, 0)
