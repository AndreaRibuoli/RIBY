#
#   Author: Andrea Ribuoli (andrea.ribuoli@yahoo.com)
#   Andrea Ribuoli (c) 2021
#
require 'yaml'
require 'fiddle'
require 'fiddle/import'

module RibyCli
  extend Fiddle::Importer

  SQL_NULL_HANDLE  = 0
  SQL_HANDLE_ENV   = 1
  SQL_HANDLE_DBC   = 2
  SQL_HANDLE_STMT  = 3
  SQL_HANDLE_DESC  = 4
  SQLINTEGER       = 1
  SQLCHAR          = 2
  SQLWCHAR         = 3
  
  SQLAttrVals = YAML.load_file('sqlattrvals.yaml')
  ILEpointer  = struct [ 'char b[16]' ]
  SQLhandle   = struct [ 'char a[4]' ]
  ILEarglist  = struct [ 'char c[144]' ]
  INFObuffer  = struct [ 'char i[4096]' ]
  SQLintsize  = struct [ 'char s[4]' ]
  SQLretsize  = struct [ 'char s[2]' ]
  Preload     = Fiddle.dlopen(nil)
  Ileloadx    = Fiddle::Function.new(
                  Preload['_ILELOADX'],
                  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                  Fiddle::TYPE_LONG_LONG )
  Ilesymx     = Fiddle::Function.new(
                  Preload['_ILESYMX'],
                  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
                  Fiddle::TYPE_INT )
  Ilecallx    = Fiddle::Function.new(
                  Preload['_ILECALLX'],
                  [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT],
                  Fiddle::TYPE_INT )
  Qsqcli = Ileloadx.call('QSYS/QSQCLI', 1)
  P_AllocHandle      = ILEpointer.malloc; Ilesymx.call(P_AllocHandle,    Qsqcli, 'SQLAllocHandle')
  P_FreeHandle       = ILEpointer.malloc; Ilesymx.call(P_FreeHandle,     Qsqcli, 'SQLFreeHandle')
  P_GetEnvAttr       = ILEpointer.malloc; Ilesymx.call(P_GetEnvAttr,     Qsqcli, 'SQLGetEnvAttr')
  P_SetEnvAttr       = ILEpointer.malloc; Ilesymx.call(P_SetEnvAttr,     Qsqcli, 'SQLSetEnvAttr')
  P_GetConnectAttrW  = ILEpointer.malloc; Ilesymx.call(P_GetConnectAttrW,Qsqcli, 'SQLGetConnectAttrW')
  P_SetConnectAttrW  = ILEpointer.malloc; Ilesymx.call(P_SetConnectAttrW,Qsqcli, 'SQLSetConnectAttrW')
  P_GetStmtAttrW     = ILEpointer.malloc; Ilesymx.call(P_GetStmtAttrW,   Qsqcli, 'SQLGetStmtAttrW')
  P_SetStmtAttrW     = ILEpointer.malloc; Ilesymx.call(P_SetStmtAttrW,   Qsqcli, 'SQLSetStmtAttrW')
  P_ConnectW         = ILEpointer.malloc; Ilesymx.call(P_ConnectW,       Qsqcli, 'SQLConnectW')
  P_Disconnect       = ILEpointer.malloc; Ilesymx.call(P_Disconnect,     Qsqcli, 'SQLDisconnect')
  P_GetInfoW         = ILEpointer.malloc; Ilesymx.call(P_GetInfoW,       Qsqcli, 'SQLGetInfoW')

  def SQLAllocHandle(htype, ihandle, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,  2] = [htype.to_s(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,  2] = ['0000'].pack("H*")
    ileArguments[ 36,  4] = ihandle
    ileArguments[ 40,  8] = ['0'.rjust(16,'0')].pack("H*")
    ileArguments[ 48, 16] = [handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[ 64, 80] = ['0'.rjust(160,'0')].pack("H*")  # padding
    Ilecallx.call(P_AllocHandle, ileArguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
    return ileArguments[ 0, 4].unpack('l')[0]
  end
  def self.SQLFreeHandle(htype, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,   2] = [htype.to_s(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,   2] = ['0000'].pack("H*")
    ileArguments[ 36,   4] = handle
    ileArguments[ 40, 104] = ['0'.rjust(208,'0')].pack("H*")
    Ilecallx.call(P_FreeHandle, ileArguments, ['FFFDFFFB0000'].pack("H*"), -5, 0)
    return ileArguments[ 0, 4].unpack('l')[0]
  end
  def self.SQLDisconnect(handle)
    ileArguments = ILEarglist.malloc
    ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,   4] = handle                          # hdbc
    ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
    Ilecallx.call(P_Disconnect, ileArguments, ['FFFB0000'].pack("H*"), -5, 0)
    return ileArguments[ 0, 4].unpack('l')[0]
  end
end

class Env
  include RibyCli
  def initialize
    @henv = SQLhandle.malloc
    @hdbcs = []  # array of handles to allow deallocation by GC
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, @henv)
    temp = @henv[0,4]
    puts "Alloc Env #{temp.unpack('l')[0]} (#{rc})" if $-W >= 2
    SQLSetEnvAttr(ATTRS[:SQL_ATTR_INCLUDE_NULL_IN_LEN], 0)
    ObjectSpace.define_finalizer(self, Env.finalizer_proc(temp))
    return rc
  end
  def self.finalizer_proc(h)
    proc {
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_ENV, h)
      puts "Free Env #{h.unpack('l')[0]} (#{rc})" if $-W >= 2
    }
  end
  def add(handle)
    @hdbcs << handle
  end
  def delete(handle)
    @hdbcs.delete(handle)
  end
  def handle
    @henv[0,4]
  end
  def attrs= hattrs
    hattrs.each { |k,v|
      next if (k == :SQL_ATTR_INCLUDE_NULL_IN_LEN)
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        SQLSetEnvAttr(ATTRS[k], lis[v])
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          tmp = 0
          v.each {|k1|
            tmp |= lis[k1]
          }
          SQLSetEnvAttr(ATTRS[k], tmp)
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            SQLSetEnvAttr(ATTRS[k], v)
          else
            lis = SQLAttrVals[:VALATTR_CHAR][k]
            if lis != nil then
              SQLSetEnvAttr(ATTRS[k], v, SQLCHAR)
            end
          end
        end
      end
    }
  end

  def attrs
    attrs_setting = Hash.new
    ATTRS.each { |k,v|
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        attrs_setting[k] = lis.key(SQLGetEnvAttr(v))
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          z = SQLGetEnvAttr(v)
          tmp = []
          lis.each {|k1,v1|
            tmp << k1 if (z & v1)
          }
          attrs_setting[k] = tmp
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            attrs_setting[k] = SQLGetEnvAttr(v)
          else
            lis = SQLAttrVals[:VALATTR_CHAR][k]
            if lis != nil then
              attrs_setting[k] = SQLGetEnvAttr(v, SQLCHAR)
            end
          end
        end
      end
    }
    attrs_setting
  end
  private
    ATTRS = {
      SQL_ATTR_OUTPUT_NTS: 10001,
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
    }
    def SQLGetEnvAttr(key, kind = SQLINTEGER)
      buffer  = INFObuffer.malloc
      sizeint = SQLintsize.malloc
      ileArguments = ILEarglist.malloc
      ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
      ileArguments[  32,  4] = handle                          # henv
      ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
      ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
      ileArguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
      ileArguments[  64,  4] = ['00001000'].pack("H*")         # 4096
      ileArguments[  68, 12] = ['0'.rjust(24,'0')].pack("H*")  # padding
      ileArguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
      ileArguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")  # padding
      Ilecallx.call(P_GetEnvAttr, ileArguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
      len = sizeint[0, 4].unpack("l")[0]
      len -= 1 if key == ATTRS[:SQL_ATTR_DEFAULT_LIB]
      return buffer[0, 4].unpack("l")[0] if kind == SQLINTEGER
      return buffer[0, len].force_encoding('IBM037').encode('utf-8')  if kind == SQLCHAR
    end
    def SQLSetEnvAttr(key, value, kind = SQLINTEGER)
      ileArguments = ILEarglist.malloc
      if kind == SQLINTEGER then
        sizeint = SQLintsize.malloc
        sizeint[0, 4] = [value.to_s(16).rjust(8,'0')].pack("H*")
        ileArguments[  48, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
      end
      if kind == SQLCHAR then
        len = value.length
        len += 1 if key == ATTRS[:SQL_ATTR_DEFAULT_LIB]
        ileArguments[  48, 16] = [Fiddle::Pointer[value.encode('IBM037')].to_i.to_s(16).rjust(32,'0')].pack("H*")
        ileArguments[  64,  4] = [len.to_s(16).rjust(8,'0')].pack("H*")
      end
      ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
      ileArguments[  32,  4] = handle
      ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
      ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")   # padding
      ileArguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
      Ilecallx.call(P_SetEnvAttr, ileArguments, ['FFFBFFFBFFF5FFFB0000'].pack("H*"), -5, 0)
    end
end

class Connect
  include RibyCli
  def initialize(henv, dsn)
    @hdbc = SQLhandle.malloc
    @hstmts = []  # array of handles to allow deallocation by GC
    @henv = henv
    @dsn  = dsn
    rc = SQLAllocHandle(SQL_HANDLE_DBC, henv.handle, @hdbc)
    temp = @hdbc[0,4]
    henv.add(temp)
    puts "#{temp.unpack('H*')} #{Time.now} Alloc Connect (#{rc})" if $-W >= 2
    ObjectSpace.define_finalizer(self, Connect.finalizer_proc(temp,henv))
  end
  def self.finalizer_proc(h,henv)
    proc {
      rc = RibyCli::SQLDisconnect(h)
      puts "#{h.unpack('H*')} #{Time.now} Disconnect (#{rc})"  if $-W >= 2
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_DBC, h)
      puts "#{h.unpack('H*')} #{Time.now} Free Connect (#{rc})"  if $-W >= 2
      henv.delete(h)
    }
  end
  def add(handle)
    @hstmts << handle
  end
  def delete(handle)
    @hstmts.delete(handle)
  end
  def handle
    @hdbc[0,4]
  end
  def Empower(user, pass)
    dsnW  = @dsn.encode('UTF-16BE')
    userW = user.encode('UTF-16BE')
    passW = pass.encode('UTF-16BE')
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle                          # hdbc
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
    return Ilecallx.call(P_ConnectW, ileArguments, ['FFFBFFF5FFFDFFF5FFFDFFF5FFFD0000'].pack("H*"), -5, 0)
  end
  def attrs= hattrs
    hattrs.each { |k,v|
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        SQLSetConnectAttrW(ATTRS[k], lis[v])
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          tmp = 0
          v.each {|k1|
            tmp |= lis[k1]
          }
          SQLSetConnectAttrW(ATTRS[k], tmp)
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            SQLSetConnectAttrW(ATTRS[k], v)
          else
            lis = SQLAttrVals[:VALATTR_WCHAR][k]
            if lis != nil then
              SQLSetConnectAttrW(ATTRS[k], v, SQLWCHAR)
            end
          end
        end
      end
    }
  end
  def attrs
    attrs_setting = Hash.new
    ATTRS.each { |k,v|
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        attrs_setting[k] = lis.key(SQLGetConnectAttrW(v))
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          z = SQLGetConnectAttrW(v)
          tmp = []
          lis.each {|k1,v1|
            tmp << k1 if (z & v1)
          }
          attrs_setting[k] = tmp
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            attrs_setting[k] = SQLGetConnectAttrW(v)
          else
            lis = SQLAttrVals[:VALATTR_WCHAR][k]
            if lis != nil then
              attrs_setting[k] = SQLGetConnectAttrW(v, SQLWCHAR)
            end
          end
        end
      end
    }
    attrs_setting
  end
  def jobname
    SQLGetInfoW(INFO[:SQL_CONNECTION_JOB_NAME], SQLWCHAR)
  end
  def disconnect
    puts " Disconnect #{handle.unpack('l')[0]} ##SYNCHRONOUS DISCONNECT IGNORED##"  if $-W >= 2
    # SQLDisconnect()
  end
  private
  ATTRS = {
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
  }
  INFO = {
    SQL_CONNECTION_JOB_NAME: 202
  }
  def SQLGetConnectAttrW(key, kind = SQLINTEGER)
    buffer  = INFObuffer.malloc
    sizeint = SQLintsize.malloc
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle                          # hdbc
    ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
    ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
    ileArguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  64,  4] = ['00001000'].pack("H*")         # 4096
    ileArguments[  68, 12] = ['0'.rjust(152,'0')].pack("H*")  # padding
    ileArguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")  # padding
    Ilecallx.call(P_GetConnectAttrW, ileArguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
    len = sizeint[0, 4].unpack("l")[0]  # remove null
    return buffer[0, 4].unpack("l")[0] if kind == SQLINTEGER
    return buffer[0, len].force_encoding('UTF-16BE').encode('utf-8')  if kind == SQLWCHAR
  end
  def SQLSetConnectAttrW(key, value, kind = SQLINTEGER)
    ileArguments = ILEarglist.malloc
    if kind == SQLINTEGER then
      sizeint = SQLintsize.malloc
      sizeint[0, 4] = [value.to_s(16).rjust(8,'0')].pack("H*")
      ileArguments[  48, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
    end
    if kind == SQLWCHAR then
      len = value.length * 2
      ileArguments[  48, 16] = [Fiddle::Pointer[value.encode('UTF-16BE')].to_i.to_s(16).rjust(32,'0')].pack("H*")
      ileArguments[  64,  4] = [len.to_s(16).rjust(8,'0')].pack("H*")
    end
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle
    ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
    ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")   # padding
    ileArguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
    return Ilecallx.call(P_SetConnectAttrW, ileArguments, ['FFFBFFFBFFF5FFFB0000'].pack("H*"), -5, 0)
  end
  def SQLGetInfoW(key, kind = SQLINTEGER)
    size   = SQLretsize.malloc
    buffer = INFObuffer.malloc
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle                          # hdbc
    ileArguments[  36,  2] = [key.to_s(16).rjust(4,'0')].pack("H*")    #
    ileArguments[  38, 10] = ['0'.rjust(20,'0')].pack("H*")  # padding
    ileArguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  64,  2] = ['1000'].pack("H*")             # 4096
    ileArguments[  66, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
    ileArguments[  80, 16] = [size.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")
    rc = Ilecallx.call(P_GetInfoW, ileArguments, ['FFFBFFFDFFF5FFFDFFF50000'].pack("H*"), -5, 0)
    len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
    return buffer[ 0, len].force_encoding('UTF-16BE').encode('utf-8') if kind == SQLWCHAR
  end
  def SQLDisconnect
    ileArguments = ILEarglist.malloc
    ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,   4] = handle                          # hdbc
    ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
    Ilecallx.call(P_Disconnect, ileArguments, ['FFFB0000'].pack("H*"), -5, 0)
    rc = ileArguments[ 0, 4].unpack('l')[0]
    puts " Disconnect #{handle.unpack('l')[0]} (#{rc}) SYNCHRONOUS"  if $-W >= 2
    return rc 
  end
end

class Stmt
  include RibyCli
  def initialize(hdbc)
    @hstmt = SQLhandle.malloc
    @hdbc = hdbc
    rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc.handle, @hstmt)
    temp = @hstmt[0,4]
    hdbc.add(temp)
    puts "  Alloc Stmt #{temp.unpack('l')[0]} (#{rc})" if $-W >= 2
    ObjectSpace.define_finalizer(self, Stmt.finalizer_proc(temp,hdbc))
  end
  def self.finalizer_proc(h,hdbc)
    proc {
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_STMT, h)
      puts "  Free Stmt #{h.unpack('l')[0]} (#{rc})"  if $-W >= 2
      hdbc.delete(h)
    }
  end
  def handle
    @hstmt[0,4]
  end
  def attrs= hattrs
    hattrs.each { |k,v|
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        SQLSetStmtAttrW(ATTRS[k], lis[v])
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          tmp = 0
          v.each {|k1|  
            tmp |= lis[k1]
          }
          SQLSetStmtAttrW(ATTRS[k], tmp)
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            SQLSetStmtAttrW(ATTRS[k], v)
          else
            lis = SQLAttrVals[:VALATTR_WCHAR][k]
            if lis != nil then
              SQLSetStmtAttrW(ATTRS[k], v, SQLWCHAR)
            end
          end
        end
      end
    }
  end
  def attrs
    attrs_setting = Hash.new
    ATTRS.each { |k,v|
      lis = SQLAttrVals[:VALATTR_DECO][k]
      if lis != nil then
        attrs_setting[k] = lis.key(SQLGetStmtAttrW(v))
      else
        lis = SQLAttrVals[:VALATTR_ORED][k]
        if lis != nil then
          z = SQLGetStmttAttrW(v)
          tmp = []
          lis.each {|k1,v1|
            tmp << k1 if (z & v1)
          }
          attrs_setting[k] = tmp
        else
          lis = SQLAttrVals[:VALATTR_NUM][k]
          if lis != nil then
            attrs_setting[k] = SQLGetStmtAttrW(v)
          else
            lis = SQLAttrVals[:VALATTR_WCHAR][k]
            if lis != nil then
              attrs_setting[k] = SQLGetStmtAttrW(v, SQLWCHAR)
            end
          end
        end
      end
    }
    attrs_setting
  end
  private
  ATTRS = {
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
  }
  def SQLGetStmtAttrW(key, kind = SQLINTEGER)
    buffer  = INFObuffer.malloc
    sizeint = SQLintsize.malloc
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle                          # hdbc
    ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
    ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")  # padding
    ileArguments[  48, 16] = [buffer.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  64,  4] = ['00001000'].pack("H*")         # 4096
    ileArguments[  68, 12] = ['0'.rjust(152,'0')].pack("H*")  # padding
    ileArguments[  80, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  96, 48] = ['0'.rjust(96,'0')].pack("H*")  # padding
    Ilecallx.call(P_GetStmtAttrW, ileArguments, ['FFFBFFFBFFF5FFFBFFF50000'].pack("H*"), -5, 0)
    len = sizeint[0, 4].unpack("l")[0]
    return buffer[0, 4].unpack("l")[0] if kind == SQLINTEGER
    return buffer[0, len].force_encoding('UTF-16BE').encode('utf-8')  if kind == SQLWCHAR
  end
  def SQLSetStmtAttrW(key, value, kind = SQLINTEGER)
    ileArguments = ILEarglist.malloc
    if kind == SQLINTEGER then
      sizeint = SQLintsize.malloc
      sizeint[0, 4] = [value.to_s(16).rjust(8,'0')].pack("H*")
      ileArguments[  48, 16] = [sizeint.to_i.to_s(16).rjust(32,'0')].pack("H*")
    end
    if kind == SQLWCHAR then
      len = value.length * 2
      ileArguments[  48, 16] = [Fiddle::Pointer[value.encode('UTF-16BE')].to_i.to_s(16).rjust(32,'0')].pack("H*")
      ileArguments[  64,  4] = [len.to_s(16).rjust(8,'0')].pack("H*")
    end
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = handle
    ileArguments[  36,  4] = [key.to_s(16).rjust(8,'0')].pack("H*")
    ileArguments[  40,  8] = ['0'.rjust(16,'0')].pack("H*")   # padding
    ileArguments[  68, 76] = ['0'.rjust(152,'0')].pack("H*")  # padding
    Ilecallx.call(P_SetStmtAttrW, ileArguments, ['FFFBFFFBFFF5FFFB0000'].pack("H*"), -5, 0)
    return ileArguments[ 0, 4].unpack('l')[0]
  end
end
