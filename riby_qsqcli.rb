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
  ILEarglist  = struct [ 'char c[64]' ]
  Preload     = Fiddle.dlopen(nil)
  Ileloadx    = Fiddle::Function.new( Preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
  Ilesymx     = Fiddle::Function.new( Preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],  Fiddle::TYPE_INT )
  Ilecallx    = Fiddle::Function.new( Preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
  
  P_SQLAllocHandle  = ILEpointer.malloc
  RC = ilesymx.call(P_SQLAllocHandle, ileloadx.call('QSYS/QSQCLI', 1), 'SQLAllocHandle')
  def SQLAllocHandle(htype, ihandle, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,  2] = [htype.to_i(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,  2] = ['0000'].pack("H*")
    ileArguments[ 36,  4] = [ihandle.to_i(16).rjust(8,'0')].pack("H*")
    ileArguments[ 40, 24] = [handle.to_i.to_s(16).rjust(48,'0')].pack("H*")
    rc = ilecallx.call(P_SQLAllocHandle, ileArguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
  end
end

class Env
  include RibyCli
  def initialize
    @henv = SQLhandle.malloc
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, @henv)
  end
  def handle
    @henv.unpack("n")
  end
  private
  def loadCliApi
    rc = ilesymx.call(pfSQLAllocHandle, ileloadx.call('QSYS/QSQCLI', 1), 'SQLAllocHandle')
  end
end

class Connect
  include RibyCli
  def initialize(henv)
    @hdbc = SQLhandle.malloc
    @henv = henv
    rc = SQLAllocHandle(SQL_HANDLE_DBC, @henv.handle, @hdbc)
  end
  def handle
    @hdbc.unpack("n")
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
    @hstmt.unpack("n")
  end
end
