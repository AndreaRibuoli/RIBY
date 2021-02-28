#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: playing_space_pointers.rb <size>" if ARGV.length != 1
size = ARGV[0].to_i
ILEpointer   = struct [ 'char b[16]' ]
ILEarglist   = struct [ 'char c[36]' ]
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
cvtspp     = Fiddle::Function.new( preload['_CVTSPP'],
                           [Fiddle::TYPE_VOIDP],
                           Fiddle::TYPE_LONG_LONG )
ILEfunction  = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QC2UTIL1', 1), 'malloc')
if rc == 1 then
  ILEreturn    = ILEpointer.malloc
  ILEarguments = ILEarglist.malloc
  ILEarguments[0, 16]  = ['0'.rjust(32,'0')].pack("H*")
  ILEarguments[16, 16] = [ILEreturn.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[32, 4]  = [size.to_s(16).rjust(8,'0')].pack("H*")
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFFA0000'].pack("H*"), 16, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  puts "ILE SPP      #{ILEreturn[0, 16].unpack("H*")}"
  puts "PASE pointer from _CVTSPP    [\"#{cvtspp.call(ILEreturn).to_s(16).rjust(16,'0')}\"]"
end
