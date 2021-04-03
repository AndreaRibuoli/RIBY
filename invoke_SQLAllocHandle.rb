#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_SQLAllocHandle.rb" if ARGV.length != 0
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[64]' ]
SQLhandle   = struct [ 'char a[4]' ]
preload    = Fiddle.dlopen(nil)
ileloadx   = Fiddle::Function.new( preload['_ILELOADX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                           Fiddle::TYPE_LONG_LONG )
ilesymx    = Fiddle::Function.new( preload['_ILESYMX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
                           Fiddle::TYPE_INT )
ilecallx   = Fiddle::Function.new( preload['_ILECALLX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT],
                           Fiddle::TYPE_INT )
ILEfunction  = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QSQCLI', 1), 'SQLAllocHandle')
if rc == 1 then
  handle = SQLhandle.malloc
  ILEarguments = ILEarglist.malloc
  ILEarguments[  0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[ 32,  2] = ['0001'].pack("H*")             # htype
  ILEarguments[ 34,  2] = ['0000'].pack("H*")             # padding
  ILEarguments[ 36,  4] = ['00000000'].pack("H*")         # ihandle
  ILEarguments[ 40,  8] = ['0000000000000000'].pack("H*") # padding
  ILEarguments[ 48, 16] = [handle.to_i.to_s(16).rjust(32,'0')].pack("H*")
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFFDFFFBFFF50000'].pack("H*"), -5, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
end
puts ' 0 1 2 3 4 5 6 7 8 9 A B C D E F'
puts ILEarguments[  0, 16].unpack("H*")
puts ILEarguments[ 16, 16].unpack("H*")
puts ILEarguments[ 32, 16].unpack("H*")
puts ILEarguments[ 48, 16].unpack("H*")
puts ' 0 1 2 3'
puts handle[ 0, 4].unpack("H*")
