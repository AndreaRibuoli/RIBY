require 'fiddle'
require 'fiddle/import'

module RibyCli
  extend Fiddle::Importer

  SQL_NULL_HANDLE  = 0
  SQL_HANDLE_ENV   = 1
  SQL_HANDLE_DBC   = 2
  SQL_HANDLE_STMT  = 3
  SQL_HANDLE_DESC  = 4

                                                                                                
  ILEpointer  = struct [ 'char b[16]' ]
  SQLhandle   = struct [ 'char a[4]' ]
  ILEarglist  = struct [ 'char c[144]' ]
  Preload     = Fiddle.dlopen(nil)
  Ileloadx    = Fiddle::Function.new( Preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
  Ilesymx     = Fiddle::Function.new( Preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],  Fiddle::TYPE_INT )
  Ilecallx    = Fiddle::Function.new( Preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
  
  P_SQLAllocHandle  = ILEpointer.malloc
  RC_SQLAllocHandle = Ilesymx.call(P_SQLAllocHandle, Ileloadx.call('QSYS/QSQCLI', 1), 'SQLAllocHandle')
  P_SQLConnectW  = ILEpointer.malloc
  RC_SQLConnectW = Ilesymx.call(P_SQLConnectW, Ileloadx.call('QSYS/QSQCLI', 1), 'SQLConnectW')

  def SQLAllocHandle(htype, ihandle, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,  2] = [htype.to_s(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,  2] = ['0000'].pack("H*")
    ileArguments[ 36,  4] = ihandle
    ileArguments[ 40,  8] = ['0'.rjust(16,'0')].pack("H*")
    ileArguments[ 48, 16] = [handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[ 64, 80] = ['0'.rjust(160,'0')].pack("H*")  # padding
    rc = Ilecallx.call(P_SQLAllocHandle, ileArguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
  end
    
end

class Env
  include RibyCli
  def initialize
    @henv = SQLhandle.malloc
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, @henv)
  end
  def handle
    @henv[0,4]
  end
  private
end

class Connect
  include RibyCli
  def initialize(henv)
    @hdbc = SQLhandle.malloc
    @henv = henv
    rc = SQLAllocHandle(SQL_HANDLE_DBC, @henv.handle, @hdbc)
  end
  def handle
    @hdbc[0,4]
  end
  def SQLConnectW(dsn, user, pass)
    dsnW  =  dsn.encode('UTF-16BE')
    userW = user.encode('UTF-16BE')
    passW = pass.encode('UTF-16BE')
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle                            # hdbc
    ileArguments[  36, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
    ileArguments[  48, 16] = [Fiddle::Pointer[dsnW].to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  64,  2] = ['FFFD'].pack("H*")             # SQL_NTS
    ileArguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
    ileArguments[  80, 16] = [Fiddle::Pointer[userW].to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  96,  2] = ['FFFD'].pack("H*")             # SQL_NTS
    ileArguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
    ileArguments[ 112, 16] = [Fiddle::Pointer[passW].to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[ 128,  2] = ['FFFD'].pack("H*")             # SQL_NTS
    ileArguments[ 130, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
    rc = Ilecallx.call(P_SQLConnectW, ileArguments, ['FFFBFFF5FFFDFFF5FFFDFFF5FFFD0000'].pack("H*"), -5, 0)
  end
end

class Stmt
  include RibyCli
  def initialize(hdbc)
    @hstmt = SQLhandle.malloc
    @hdbc = hdbc
    rc = SQLAllocHandle(SQL_HANDLE_STMT, @hdbc.handle, @hstmt)
  end
  def handle
    @hstmt[0,4]
  end
end
