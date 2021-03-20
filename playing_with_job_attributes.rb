#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: playing_with_job_attributes.rb" if ARGV.length != 0


preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )
#
size = 512
ILEpointer  = struct [ 'char b[16]' ]
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[112]' ]
PASEbuffer  = struct [ "char d[#{size}]" ]

receiver_variable = PASEbuffer.malloc
argv   = ILEparms.malloc
#
              =
length_of_receiver_variable    = [size.to_s(16).rjust(8,'0')].pack("H*")
format_name                    = 'JOBI0100'.encode('IBM037')
qualified_job_name             = '*'.ljust(26, ' ').encode('IBM037')
internal_job_identifier        = ' '.ljust(16, ' ').encode('IBM037')
#
pQUSRJOBI  = ILEpointer.malloc
rc = rslobj2.call(pQUSRJOBI, 513, "QUSRJOBI", "QSYS")

argv[  0, 8] = [receiver_variable.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  8, 8] = [Fiddle::Pointer[length_of_receiver_variable].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 16, 8] = [Fiddle::Pointer[format_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 24, 8] = [Fiddle::Pointer[qualified_job_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 32, 8] = [Fiddle::Pointer[internal_job_identifier].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 40, 8] = ['0'.rjust(16,'0')].pack("H*")

rc = pgmcall.call(pQUSRJOBI, argv, 0)

puts receiver_variable[0, 512].unpack["H*"]
