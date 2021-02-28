#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: playing_space_pointers.rb <msg>" if ARGV.length != 1
cmd  = "SNDPGMMSG MSG('#{ARGV[0]}') TOMSGQ(*SYSOPR)"
size = cmd.length
ILEpointer   = struct [ 'char b[16]' ]
ILEarglist   = struct [ 'char c[64]' ]
PASEpointer  = struct [ 'char d[8]' ]
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
rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QP2USER', 1), 'Qp2malloc')
if rc == 1 then
  ILEreturn    = ILEpointer.malloc
  ILEarguments = ILEarglist.malloc
  PASEreturn   = PASEpointer.malloc
  ILEarguments[0, 16] = ['0'.rjust(32,'0')].pack("H*")
  ILEarguments[16, 16] = [ILEreturn.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[32, 8]  = [size.to_s(16).rjust(16,'0')].pack("H*")
  ILEarguments[40, 0] = ['0'.rjust(16,'0')].pack("H*")
  ILEarguments[48, 16] = [PASEpointer.to_i.to_s(16).rjust(32,'0')].pack("H*")
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF8FFF50000'].pack("H*"), 16, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  puts "PASE pointer                 #{PASEreturn[0, 8].unpack("H*")}"
  puts "ILE SPP      #{ILEreturn[0, 16].unpack("H*")}"
end
