#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

name = 'QLEAWI'
lib  = 'QSYS'

us_name = 'MYSPACE'
us_lib  = 'QTEMP'
Qualified_user_space_name      = "#{us_name.ljust(10, ' ')}#{us_lib.ljust(10, ' ')}".encode('IBM037')
Extended_attribute             = 'USRSPC'.ljust(10, ' ').encode('IBM037')
Initial_size                   = ['00001000'].pack("H*")
Initial_value                  = '1'.encode('IBM037')
Public_authority               = '*ALL'.ljust(10, ' ').encode('IBM037')
Text_description               = 'My user space'.ljust(50, ' ').encode('IBM037')
Starting_position              = ['00000001'].pack("H*")
Length_of_data                 = ['00000400'].pack("H*")
Format_name                    = 'SPGL0610'.encode('IBM037')
Qualified_service_program_name = "#{name.ljust(10, ' ')}#{lib.ljust(10, ' ')}".encode('IBM037')

ILEparms    = struct [ 'char a[56]' ]
ILEpointer  = struct [ 'char b[16]' ]
ILEerror    = struct [ 'char e[12]' ]
ILEbuffer   = struct [ 'char b[1024]' ]
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )

pQUSCRTUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSCRTUS, 513, "QUSCRTUS", "QSYS")
pQUSPTRUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSPTRUS, 513, "QUSPTRUS", "QSYS")
pQUSRTVUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSRTVUS, 513, "QUSRTVUS", "QSYS")
pQBNLSPGM  = ILEpointer.malloc
rc = rslobj2.call(pQBNLSPGM, 513, "QBNLSPGM", "QSYS")
puts pQBNLSPGM[0, 16].unpack("H*")

argv = ILEparms.malloc
argv[ 0, 8] = [Fiddle::Pointer[Qualified_user_space_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 8, 8] = [Fiddle::Pointer[Extended_attribute].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[16, 8] = [Fiddle::Pointer[Initial_size].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[24, 8] = [Fiddle::Pointer[Initial_value].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[32, 8] = [Fiddle::Pointer[Public_authority].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[40, 8] = [Fiddle::Pointer[Text_description].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[48, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQUSCRTUS, argv, 0)
#
pMySpace   = ILEpointer.malloc
argv[ 8, 8] = [pMySpace.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[16, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQUSPTRUS, argv, 0)
puts pMySpace[0,16].unpack("H*") if rc == 0
#
pSysPointer  = ILEpointer.malloc
rc = rslobj2.call(pSysPointer, 6452, name, lib)
puts pSysPointer[0,16].unpack("H*") if rc == 0
#
pError = ILEerror.malloc
argv[ 0, 8] = [Fiddle::Pointer[Qualified_user_space_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 8, 8] = [Fiddle::Pointer[Format_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[16, 8] = [Fiddle::Pointer[Qualified_service_program_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[24, 8] = [pError.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[32, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQBNLSPGM, argv, 0)
puts pMySpace[0,16].unpack("H*") if rc == 0

#
buffer = ILEbuffer.malloc
argv[ 8, 8] = [Fiddle::Pointer[Starting_position].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[16, 8] = [Fiddle::Pointer[Length_of_data].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[24, 8] = [buffer.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[32, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQUSRTVUS, argv, 0)
off = buffer[124,4].unpack("H*")[0].to_i(16)
puts buffer[off,56].unpack("H*")[0]
puts buffer[off+56,56].unpack("H*")[0]


