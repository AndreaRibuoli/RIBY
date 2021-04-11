module RibyCli

  SQL_NULL_HANDLE  = 0
  SQL_HANDLE_ENV   = 1
  SQL_HANDLE_DBC   = 2
  SQL_HANDLE_STMT  = 3
  SQL_HANDLE_DESC  = 4

  
  class Env
    def initialize
##      RibyCli::loadCliApi
      @henv = SQLhandle.malloc
      rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, @henv)
    end
    def handle
      @henv.unpack("n")
    end
  end

  class Connect
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
    def initialize(hdbc)
      @hstmt = SQLhandle.malloc
      @hdbc = hdbc
      rc = SQLAllocHandle(SQL_HANDLE_STMT, @hdbc.handle, @hstmt)
    end
    def handle
      @hstmt.unpack("n")
    end
  end

  private

  require 'fiddle'
  require 'fiddle/import'
  extend Fiddle::Importer
                                                                                                
  ILEpointer  = struct [ 'char b[16]' ]
  SQLhandle   = struct [ 'char a[4]' ]
  ILEarglist  = struct [ 'char c[64]' ]
  preload    = Fiddle.dlopen(nil)
  ileloadx   = Fiddle::Function.new( preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
  ilesymx    = Fiddle::Function.new( preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],  Fiddle::TYPE_INT )
  ilecallx   = Fiddle::Function.new( preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
  
  pfSQLAllocHandle  = ILEpointer.malloc
  
##  def loadCliApi
    rc = ilesymx.call(pfSQLAllocHandle, ileloadx.call('QSYS/QSQCLI', 1), 'SQLAllocHandle')
##  end
  
  def SQLAllocHandle(htype, ihandle, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,  2] = [htype.to_i(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,  2] = ['0000'].pack("H*")
    ileArguments[ 36,  4] = [ihandle.to_i(16).rjust(8,'0')].pack("H*")
    ileArguments[ 40, 24] = [handle.to_i.to_s(16).rjust(48,'0')].pack("H*")
    rc = ilecallx.call(pfSQLAllocHandle, ileArguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
  end

end
