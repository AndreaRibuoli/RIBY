#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: inspecting_command.rb <lib> <cmd>" if ARGV.length != 2
#
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[56]' ]
ILEpointer  = struct [ 'char b[16]' ]
CmdContent  = struct [ 'char d[8000]' ]

cmdlib      = ARGV[0].upcase
cmdname     = ARGV[1].upcase
Qualified_command_name  = "#{cmdname.ljust(10, ' ')}#{cmdlib.ljust(10, ' ')}".encode('IBM037')
Destination_information = [8000.to_s(16).rjust(8,'0')].pack("H*")
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
require 'rexml/document'
include REXML
puts Error_code[0, 12].unpack("H*")
puts size = Receiver_variable[0, 4].unpack("H*")[0].to_i(16)
xmldoc = Document.new( Receiver_variable[8, size] )
puts xmldoc.to_s
