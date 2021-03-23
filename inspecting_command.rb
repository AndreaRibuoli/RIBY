#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: inspecting_command.rb <lib> <cmd>" if ARGV.length != 2
#
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[56]' ]
ILEpointer  = struct [ 'char b[16]' ]
CmdContent  = struct [ 'char d[4096]' ]

cmdlib      = ARGV[0].upcase
cmdname     = ARGV[1].upcase
Qualified_command_name  = "#{cmdname.ljust(10, ' ')}#{cmdlib.ljust(10, ' ')}".encode('IBM037')
Destination_information = [4094.to_s(16).rjust(8,'0')].pack("H*")
Destination_format_name = "DEST0100".encode('IBM037')
Receiver_variable       = CmdContent.malloc
Receiver_format_name    = "CMDD0100".encode('IBM037')
Error_code              = ILEerror.malloc
#
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
#
pQCDRCMDD  = ILEpointer.malloc
rc = rslobj2.call(pQCDRCMDD, 513, "QCDRCMDD", "QSYS")

argv = ILEparms.malloc
argv[  0, 8] = [Fiddle::Pointer[Qualified_command_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  8, 8] = [Fiddle::Pointer[Destination_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 16, 8] = [Fiddle::Pointer[Destination_format_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 24, 8] = [Receiver_variable.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 32, 8] = [Fiddle::Pointer[Receiver_format_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 40, 8] = [Error_code.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 48, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQCDRCMDD, argv, 0)
#
puts Receiver_variable[0, 64].unpack("H*")
