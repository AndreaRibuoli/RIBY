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
size = 86
ILEpointer  = struct [ 'char b[16]' ]
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[112]' ]
PASEbuffer  = struct [ "char d[#{size}]" ]

argv   = ILEparms.malloc
#
receiver_variable              = PASEbuffer.malloc
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

puts <<ENDOUT
Number of bytes returned  = #{receiver_variable[  0,  4].unpack("H*")[0].to_i(16)}
Number of bytes available = #{receiver_variable[  4,  4].unpack("H*")[0].to_i(16)}
Job name                  = #{receiver_variable[  8, 10].force_encoding('IBM037'). encode('utf-8')}
User name                 = #{receiver_variable[ 18, 10].force_encoding('IBM037'). encode('utf-8')}
Job number                = #{receiver_variable[ 28,  6].force_encoding('IBM037'). encode('utf-8')}
Internal job identifier   = 0x#{receiver_variable[ 34, 16].unpack("H*")}
Job status                = #{receiver_variable[ 50, 10].force_encoding('IBM037'). encode('utf-8')}
Job type                  = #{receiver_variable[ 60,  1].force_encoding('IBM037'). encode('utf-8')}
Job subtype               = #{receiver_variable[ 61,  1].force_encoding('IBM037'). encode('utf-8')}
Reserved                  = #{receiver_variable[ 62,  2].force_encoding('IBM037'). encode('utf-8')}
Run priority (job)        = 0x#{receiver_variable[ 64,  4].unpack("H*")}
Time slice                = 0x#{receiver_variable[ 68,  4].unpack("H*")}
Default wait              = 0x#{receiver_variable[ 72,  4].unpack("H*")}
Purge                     = #{receiver_variable[ 76, 10].force_encoding('IBM037'). encode('utf-8')}
ENDOUT
