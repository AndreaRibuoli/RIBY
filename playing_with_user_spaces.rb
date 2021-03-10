#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
name = 'MYSPACE'
lib  = 'QTEMP'
Qualified_user_space_name = "#{name.ljust(10, ' ')}#{lib.ljust(10, ' ')}".encode('IBM037')
Extended_attribute        = 'USRSPC'.ljust(10, ' ').encode('IBM037')
Initial_size              = ['00001000'].pack("H*")
Initial_value             = ' '.encode('IBM037')
Public_authority          = '*ALL'.ljust(10, ' ').encode('IBM037')
Text_description          = 'My user space'.ljust(50, ' ').encode('IBM037')

ILEparms    = struct [ 'char a[56]' ]
ILEpointer  = struct [ 'char b[16]' ]
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )

pQUSCRTUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSCRTUS, 513, "QUSCRTUS", "QSYS")
pQUSPTRUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSPTRUS, 513, "QUSPTRUS", "QSYS")

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
