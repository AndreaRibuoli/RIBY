#
#   Author: Andrea Ribuoli (andrea.ribuoli@yahoo.com)
#   Andrea Ribuoli (c) 2021
#
require 'yaml'
require 'fiddle'
require 'fiddle/import'

module RibyCli
  extend Fiddle::Importer

  private
  SQL_NULL_HANDLE  = [ 0, 0, 0, 0].pack("C*")
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
  SQLerror    = struct [ 'char e[4]' ]
  SQLstate    = struct [ 'char s[12]' ]
  SQLmsg      = struct [ 'char s[1026]' ]
  SQLmsglen   = struct [ 'char l[2]' ]

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
  SQLApiList = {            #----#----#----#----#----#----#----#----#----#----#----#----#----#----#
  'SQLAllocHandle'       => [ - 3, - 5, -11,                                                     0].pack("n*"),
  'SQLFreeHandle'        => [ - 3, - 5,                                                          0].pack("n*"),
  'SQLGetEnvAttr'        => [ - 5, - 5, -11, - 5, -11,                                           0].pack("n*"),
  'SQLGetConnectAttrW'   => [ - 5, - 5, -11, - 5, -11,                                           0].pack("n*"),
  'SQLGetStmtAttrW'      => [ - 5, - 5, -11, - 5, -11,                                           0].pack("n*"),
  'SQLSetEnvAttr'        => [ - 5, - 5, -11, - 5,                                                0].pack("n*"),
  'SQLSetConnectAttrW'   => [ - 5, - 5, -11, - 5,                                                0].pack("n*"),
  'SQLSetStmtAttrW'      => [ - 5, - 5, -11, - 5,                                                0].pack("n*"),
  'SQLConnectW'          => [ - 5, -11, - 3, -11, - 3, -11, - 3,                                 0].pack("n*"),
  'SQLDisconnect'        => [ - 5,                                                               0].pack("n*"),
  'SQLReleaseEnv'        => [ - 5,                                                               0].pack("n*"),
  'SQLGetInfoW'          => [ - 5, - 3, -11, - 3, -11,                                           0].pack("n*"),
  'SQLBindCol'           => [ - 5, - 5, - 5, -11, - 5, -11,                                      0].pack("n*"),
  'SQLBindFileToCol'     => [ - 5, - 3, -11, -11, -11, - 3, -11, -11,                            0].pack("n*"),
  'SQLBindFileToParam'   => [ - 5, - 3, - 3, -11, -11, -11, - 3, -11,                            0].pack("n*"),
  'SQLBindParam'         => [ - 5, - 3, - 3, - 3, - 5, - 3, -11, -11,                            0].pack("n*"),
  'SQLBindParameter'     => [ - 5, - 5, - 5, - 5, - 5, - 5, - 5, -11, - 5, -11,                  0].pack("n*"),
  'SQLCancel'            => [ - 5,                                                               0].pack("n*"),
  'SQLCloseCursor'       => [ - 5,                                                               0].pack("n*"),
  'SQLColumnsW'          => [ - 5, -11, - 3, -11, - 3, -11, - 3, -11, - 3,                       0].pack("n*"),
  'SQLColumnPrivilegesW' => [ - 5, -11, - 3, -11, - 3, -11, - 3, -11, - 3,                       0].pack("n*"),
  'SQLColAttributesW'    => [ - 5, - 3, - 3, -11, - 5, -11, -11,                                 0].pack("n*"),
  'SQLColAttributeW'     => [ - 5, - 3, - 3, -11, - 3, -11, -11,                                 0].pack("n*"),
  'SQLCopyDesc'          => [ - 5, - 5,                                                          0].pack("n*"),
  'SQLDataSourcesW'      => [ - 5, - 3, -11, - 3, -11, -11, - 3, -11,                            0].pack("n*"),
  'SQLDescribeColW'      => [ - 5, - 3, -11, - 3, -11, -11, -11, -11, -11,                       0].pack("n*"),
  'SQLDescribeParam'     => [ - 5, - 3, -11, -11, -11, -11,                                      0].pack("n*"),
  'SQLDriverConnectW'    => [ - 5, -11, -11, - 3, -11, - 3, -11, - 3,                            0].pack("n*"),
  'SQLEndTran'           => [ - 3, - 5, - 3,                                                     0].pack("n*"),
  'SQLErrorW'            => [ - 5, - 5, - 5, -11, -11, -11, - 3, -11,                            0].pack("n*"),
  'SQLExecute'           => [ - 5,                                                               0].pack("n*"),
  'SQLExecDirectW'       => [ - 5, -11, - 5,                                                     0].pack("n*"),
  'SQLExtendedFetch'     => [ - 5, - 3, - 5, -11, -11,                                           0].pack("n*"),
  'SQLFetch'             => [ - 5,                                                               0].pack("n*"),
  'SQLFetchScroll'       => [ - 5, - 3, - 5,                                                     0].pack("n*"),
  'SQLForeignKeysW'      => [ - 5, -11, - 3, -11, - 3, -11, - 3, -11, - 3, -11, - 3, -11, - 3,   0].pack("n*"),
  'SQLGetCol'            => [ - 5, - 3, - 3, -11, - 5, -11,                                      0].pack("n*"),
  'SQLGetConnectOptionW' => [ - 5, - 3, -11,                                                     0].pack("n*"),
  'SQLGetCursorNameW'    => [ - 5, -11, - 3, -11,                                                0].pack("n*"),
  'SQLGetData'           => [ - 5, - 3, - 3, -11, - 5, -11,                                      0].pack("n*"),
  'SQLGetDescFieldW'     => [ - 5, - 3, - 3, -11, - 5, -11,                                      0].pack("n*"),
  'SQLGetDescRecW'       => [ - 5, - 3, -11, - 3, -11, -11, -11, -11, -11, -11, -11,             0].pack("n*"),
  'SQLGetDiagFieldW'     => [ - 3, - 5, - 3, - 3, -11, - 3, -11,                                 0].pack("n*"),
  'SQLGetDiagRecW'       => [ - 3, - 5, - 3, -11, -11, -11, - 3, -11,                            0].pack("n*"),
  'SQLGetFunctions'      => [ - 5, - 3, -11,                                                     0].pack("n*"),
  'SQLGetLength'         => [ - 5, - 5, - 5, -11, -11,                                           0].pack("n*"),
  'SQLGetPositionW'      => [ - 5, - 3, - 5, - 5, -11, - 5, - 5, -11, -11,                       0].pack("n*"),
  'SQLGetStmtOptionW'    => [ - 5, - 3, -11,                                                     0].pack("n*"),
  'SQLGetSubStringW'     => [ - 5, - 5, - 5, - 5, - 5, - 5, -11, - 5, -11, -11,                  0].pack("n*"),
  'SQLGetTypeInfoW'      => [ - 5, - 3,                                                          0].pack("n*"),
  'SQLLanguages'         => [ - 5,                                                               0].pack("n*"),
  'SQLMoreResults'       => [ - 5,                                                               0].pack("n*"),
  'SQLNativeSQLW'        => [ - 5, -11, - 5, -11, - 5, -11,                                      0].pack("n*"),
  'SQLNextResult'        => [ - 5, - 5,                                                          0].pack("n*"),
  'SQLNumParams'         => [ - 5, -11,                                                          0].pack("n*"),
  'SQLNumResultCols'     => [ - 5, -11,                                                          0].pack("n*"),
  'SQLParamData'         => [ - 5, -11,                                                          0].pack("n*"),
  'SQLParamOptions'      => [ - 5, - 5, -11,                                                     0].pack("n*"),
  'SQLPrepareW'          => [ - 5, -11, - 5,                                                     0].pack("n*"),
  'SQLPrimaryKeysW'      => [ - 5, -11, - 3, -11, - 3, -11, - 3,                                 0].pack("n*"),
  'SQLProceduresW'       => [ - 5, -11, - 3, -11, - 3, -11, - 3,                                 0].pack("n*"),
  'SQLProcedureColumnsW' => [ - 5, -11, - 3, -11, - 3, -11, - 3, -11, - 3,                       0].pack("n*"),
  'SQLPutData'           => [ - 5, -11, - 5,                                                     0].pack("n*"),
  'SQLRowCount'          => [ - 5, -11,                                                          0].pack("n*"),
  'SQLSetConnectOptionW' => [ - 5, - 3, -11,                                                     0].pack("n*"),
  'SQLSetCursorNameW'    => [ - 5, -11, - 3,                                                     0].pack("n*"),
  'SQLSetDescFieldW'     => [ - 5, - 3, - 3, -11, - 5,                                           0].pack("n*"),
  'SQLSetDescRec'        => [ - 5, - 3, - 3, - 3, - 5, - 3, - 3, -11, -11, -11,                  0].pack("n*"),
  'SQLSetParam'          => [ - 5, - 3, - 3, - 3, - 5, - 3, -11, -11,                            0].pack("n*"),
  'SQLSetStmtOptionW'    => [ - 5, - 3, -11,                                                     0].pack("n*"),
  'SQLSpecialColumnsW'   => [ - 5, - 3, -11, - 3, -11, - 3, -11, - 3, - 3, - 3,                  0].pack("n*"),
  'SQLStartTran'         => [ - 3, - 5, - 5, - 5,                                                0].pack("n*"),
  'SQLStatisticsW'       => [ - 5, -11, - 3, -11, - 3, -11, - 3, - 3, - 3,                       0].pack("n*"),
  'SQLTablesW'           => [ - 5, -11, - 3, -11, - 3, -11, - 3, -11, - 3,                       0].pack("n*"),
  'SQLTablePrivilegesW'  => [ - 5, -11, - 3, -11, - 3, -11, - 3,                                 0].pack("n*"),
  'SQLTransact'          => [ - 5, - 5, - 3,                                                     0].pack("n*")
               }
  SQLApis = {}
  SQLApiList.each { |key, val| SQLApis[key] = ILEpointer.malloc }
  Qsqcli = Ileloadx.call('QSYS/QSQCLI', 1)
  SQLApis.each {|key, val| Ilesymx.call(val, Qsqcli, key) }
  
  def SQLAllocHandle(htype, ihandle, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,  2] = [htype.to_s(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,  2] = ['0000'].pack("H*")
    ileArguments[ 36,  4] = ihandle
    ileArguments[ 40,  8] = ['0'.rjust(16,'0')].pack("H*")
    ileArguments[ 48, 16] = [handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[ 64, 80] = ['0'.rjust(160,'0')].pack("H*")  # padding
    Ilecallx.call(SQLApis['SQLAllocHandle'], ileArguments, SQLApiList['SQLAllocHandle'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
  end
  def SQLErrorW(henv, hdbc=SQL_NULL_HANDLE, hstmt=SQL_NULL_HANDLE)
    state  = SQLstate.malloc
    error  = SQLerror.malloc
    msg    = SQLmsg.malloc
    msglen = SQLmsglen.malloc
    ileArguments = ILEarglist.malloc
    ileArguments[   0, 32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,  4] = henv
    ileArguments[  36,  4] = hdbc
    ileArguments[  40,  4] = hstmt
    ileArguments[  44,  4] = ['0'.rjust(8,'0')].pack("H*")  # padding
    ileArguments[  48, 16] = [state.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  64, 16] = [error.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  80, 16] = [msg.to_i.to_s(16).rjust(32,'0')].pack("H*")
    ileArguments[  96,  2] = ['0402'].pack("H*")             #
    ileArguments[  98, 14] = ['0'.rjust(28,'0')].pack("H*")  # padding
    ileArguments[ 112, 16] = [msglen.to_i.to_s(16).rjust(32,'0')].pack("H*")
    Ilecallx.call(SQLApis['SQLErrorW'], ileArguments, SQLApiList['SQLErrorW'], - 5, 0)
    l = msglen[0, 2].unpack("H*")[0].to_i(16) * 2
    return [ileArguments[ 16, 4].unpack('l')[0],
     state[0, 10].force_encoding('UTF-16BE').encode('utf-8'),
     error[0, 4].unpack("l")[0],
     msg[0, l].force_encoding('UTF-16BE').encode('utf-8')]
  end

  def self.SQLFreeHandle(htype, handle)
    ileArguments = ILEarglist.malloc
    ileArguments[  0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[ 32,   2] = [htype.to_s(16).rjust(4,'0')].pack("H*")
    ileArguments[ 34,   2] = ['0000'].pack("H*")
    ileArguments[ 36,   4] = handle
    ileArguments[ 40, 104] = ['0'.rjust(208,'0')].pack("H*")
    Ilecallx.call(SQLApis['SQLFreeHandle'], ileArguments, SQLApiList['SQLFreeHandle'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
  end
  
end

class Env
  include RibyCli
  def initialize
    @henv = SQLhandle.malloc
    @hdbcs = []  # array of handles to allow deallocation by GC
    rc = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, @henv)
    temp = @henv[0,4]
    puts "#{temp.unpack('H*')} #{'%10.7f' % Time.now.to_f} Alloc Env (#{rc})" if $-W >= 2
    SQLSetEnvAttr(ATTRS[:SQL_ATTR_INCLUDE_NULL_IN_LEN], 0)
    ObjectSpace.define_finalizer(self, Env.finalizer_proc(temp))
    return rc
  end
  def self.finalizer_proc(h)
    proc {
      rc = Env::SQLReleaseEnv(h)
      puts "#{h.unpack('H*')} #{'%10.7f' % Time.now.to_f} Release Env (#{rc})"  if $-W >= 2
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_ENV, h)
      puts "#{h.unpack('H*')} #{'%10.7f' % Time.now.to_f} Free Env (#{rc})" if $-W >= 2
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
  def error
    SQLErrorW(handle)
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
  def release
    puts "#{handle.unpack('H*')} #{'%10.7f' % Time.now.to_f} ## SYNCHRONOUS SQLReleaseEnv IGNORED!!! ##"  if $-W >= 2
    # SQLReleaseEnv()
  end
  def self.SQLReleaseEnv(henv)
    ileArguments = ILEarglist.malloc
    ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,   4] = henv
    ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
    Ilecallx.call(SQLApis['SQLReleaseEnv'], ileArguments, SQLApiList['SQLReleaseEnv'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
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
      Ilecallx.call(SQLApis['SQLGetEnvAttr'], ileArguments, SQLApiList['SQLGetEnvAttr'], - 5, 0)
      len = sizeint[0, 4].unpack("l")[0]
      len -= 1 if (key == ATTRS[:SQL_ATTR_DEFAULT_LIB] && len>1)
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
      Ilecallx.call(SQLApis['SQLSetEnvAttr'], ileArguments, SQLApiList['SQLSetEnvAttr'], - 5, 0)
      return ileArguments[ 16, 4].unpack('l')[0]
    end
#    def SQLReleaseEnv
#      ileArguments = ILEarglist.malloc
#      ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
#      ileArguments[  32,   4] = handle                          # henv
#      ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
#      Ilecallx.call(SQLApis['SQLReleaseEnv'], ileArguments, SQLApiList['SQLReleaseEnv'], - 5, 0)
#      rc = ileArguments[ 16, 4].unpack('l')[0]
#      puts " ReleaseEnv #{handle.unpack('l')[0]} (#{rc}) SYNCHRONOUS"  if $-W >= 2
#      return rc
#    end
end

class Connect
  include RibyCli
  def initialize(henv, dsn = '*LOCAL')
    @hdbc = SQLhandle.malloc
    @hstmts = []  # array of handles to allow deallocation by GC
    @henv = henv
    @dsn  = dsn
    rc = SQLAllocHandle(SQL_HANDLE_DBC, henv.handle, @hdbc)
    temp = @hdbc[0,4]
    henv.add(temp)
    puts "#{temp.unpack('H*')} #{'%10.7f' % Time.now.to_f} Alloc Connect (#{rc})" if $-W >= 2
    ObjectSpace.define_finalizer(self, Connect.finalizer_proc(temp,henv))
  end
  def self.finalizer_proc(h,henv)
    proc {
      rc = RibyCli::SQLDisconnect(h)
      puts "#{h.unpack('H*')} #{'%10.7f' % Time.now.to_f} Disconnect (#{rc})"  if $-W >= 2
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_DBC, h)
      puts "#{h.unpack('H*')} #{'%10.7f' % Time.now.to_f} Free Connect (#{rc})"  if $-W >= 2
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
  def error
    SQLErrorW(@henv.handle, handle)
  end
  def empower(user, pass)
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
    Ilecallx.call(SQLApis['SQLConnectW'], ileArguments, SQLApiList['SQLConnectW'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
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
    puts "#{handle.unpack('H*')} #{'%10.7f' % Time.now.to_f} ## SYNCHRONOUS SQLDisconnect IGNORED!!! ##"  if $-W >= 2
    # SQLDisconnect()
  end

  def self.SQLDisconnect(hdbc)
    ileArguments = ILEarglist.malloc
    ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,   4] = hdbc
    ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
    Ilecallx.call(SQLApis['SQLDisconnect'], ileArguments, SQLApiList['SQLDisconnect'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
  end

  private
  ATTRS = {
    SQL_ATTR_TXN_ISOLATION:                        0,
    SQL_ATTR_XML_DECLARATION:                   2552,
    SQL_ATTR_CURRENT_IMPLICIT_XMLPARSE_OPTION:  2553,
    SQL_ATTR_CONCURRENT_ACCESS_RESOLUTION:      2595,
    SQL_ATTR_AUTO_IPD:                         10001,
    SQL_ATTR_ACCESS_MODE:                      10002,
    SQL_ATTR_AUTOCOMMIT:                       10003,
    SQL_ATTR_DBC_SYS_NAMING:                   10004,
    SQL_ATTR_DBC_DEFAULT_LIB:                  10005,
    SQL_ATTR_ADOPT_OWNER_AUTH:                 10006,
    SQL_ATTR_SYSBAS_CMT:                       10007,
    SQL_ATTR_DATE_FMT:                         10020,
    SQL_ATTR_DATE_SEP:                         10021,
    SQL_ATTR_TIME_FMT:                         10022,
    SQL_ATTR_TIME_SEP:                         10023,
    SQL_ATTR_DECIMAL_SEP:                      10024,
    SQL_ATTR_TXN_EXTERNAL:                     10026,
    SQL_ATTR_SAVEPOINT_NAME:                   10028,
    SQL_ATTR_INCLUDE_NULL_IN_LEN:              10031,
    SQL_ATTR_UTF8:                             10032,
    SQL_ATTR_UCS2:                             10035,
    SQL_ATTR_MAX_PRECISION:                    10040,
    SQL_ATTR_MAX_SCALE:                        10041,
    SQL_ATTR_MIN_DIVIDE_SCALE:                 10042,
    SQL_ATTR_HEX_LITERALS:                     10043,
    SQL_ATTR_CORRELATOR:                       10044,
    SQL_ATTR_CONN_SORT_SEQUENCE:               10046,
    SQL_ATTR_INFO_USERID:                      10103,
    SQL_ATTR_INFO_WRKSTNNAME:                  10104,
    SQL_ATTR_INFO_APPLNAME:                    10105,
    SQL_ATTR_INFO_ACCTSTR:                     10106,
    SQL_ATTR_INFO_PROGRAMID:                   10107,
    SQL_ATTR_DECFLOAT_ROUNDING_MODE:           10112,
    SQL_ATTR_OLD_MTADTA_BEHAVIOR:              10113,
    SQL_ATTR_NULL_REQUIRED:                    10114,
    SQL_ATTR_FREE_LOCATORS:                    10115, # complex
    SQL_ATTR_EXTENDED_INDICATORS:              10116,
    SQL_ATTR_NULLT_ARRAY_RESULTS:              10117,
    SQL_ATTR_NULLT_OUTPUT_PARMS:               10118,
    SQL_ATTR_TIMESTAMP_PREC:                   10119,
    SQL_ATTR_SERVERMODE_SUBSYSTEM:             10204
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
    Ilecallx.call(SQLApis['SQLGetConnectAttrW'], ileArguments, SQLApiList['SQLGetConnectAttrW'], - 5, 0)
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
    Ilecallx.call(SQLApis['SQLSetConnectAttrW'], ileArguments, SQLApiList['SQLSetConnectAttrW'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
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
    Ilecallx.call(SQLApis['SQLGetInfoW'], ileArguments, SQLApiList['SQLGetInfoW'], - 5, 0)
    len = ('0000' + size[ 0, 2].unpack("H*")[0]).to_i(16)
    return buffer[ 0, len].force_encoding('UTF-16BE').encode('utf-8') if kind == SQLWCHAR
  end
  def SQLDisconnect
    ileArguments = ILEarglist.malloc
    ileArguments[   0,  32] = ['0'.rjust(64,'0')].pack("H*")
    ileArguments[  32,   4] = handle                          # hdbc
    ileArguments[  36, 108] = ['0'.rjust(216,'0')].pack("H*")
    Ilecallx.call(SQLApis['SQLDisconnect'], ileArguments, SQLApiList['SQLDisconnect'], - 5, 0)
    rc = ileArguments[ 16, 4].unpack('l')[0]
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
    puts "#{temp.unpack('H*')} #{'%10.7f' % Time.now.to_f} Alloc Stmt (#{rc})" if $-W >= 2
    ObjectSpace.define_finalizer(self, Stmt.finalizer_proc(temp,hdbc))
  end
  def self.finalizer_proc(h,hdbc)
    proc {
      rc = RibyCli::SQLFreeHandle(SQL_HANDLE_STMT, h)
      puts "#{h.unpack('H*')} #{'%10.7f' % Time.now.to_f} Free Stmt (#{rc})"  if $-W >= 2
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
    SQL_ATTR_PARAMSET_SIZE:      10058,
    SQL_ATTR_UNKNOWN_10062:      10062,
    SQL_ATTR_UNKNOWN_10063:      10063,
    SQL_ATTR_UNKNOWN_10064:      10064,
    SQL_ATTR_UNKNOWN_10065:      10065,
    SQL_ATTR_UNKNOWN_10066:      10066
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
    Ilecallx.call(SQLApis['SQLGetStmtAttrW'], ileArguments, SQLApiList['SQLGetStmtAttrW'], - 5, 0)
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
    Ilecallx.call(SQLApis['SQLSetStmtAttrW'], ileArguments, SQLApiList['SQLSetStmtAttrW'], - 5, 0)
    return ileArguments[ 16, 4].unpack('l')[0]
  end
end
