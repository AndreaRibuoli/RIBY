#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: playing_space_pointers.rb <size>" if ARGV.length != 1
size = ARGV[0].to_i
ILEpointer   = struct [ 'char b[16]' ]
ILEarglist   = struct [ 'char c[64]' ]
PASEpointer  = struct [ 'unsigned long p' ]
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
  ILEreturn    = ILEpointer.malloc
  ILEarguments = ILEarglist.malloc
  PASEreturn   = PASEpointer.malloc
  ILEarguments[0, 16]  = ['0'.rjust(32,'0')].pack("H*")
  ILEarguments[16, 16] = [ILEreturn.to_i.to_s(16).rjust(32,'0')].pack("H*")
  ILEarguments[32, 8]  = [size.to_s(16).rjust(16,'0')].pack("H*")
  ILEarguments[40, 0]  = ['0'.rjust(16,'0')].pack("H*")
  ILEarguments[48, 16] = [PASEreturn.to_i.to_s(16).rjust(32,'0')].pack("H*")
#  rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QP2USER', 1), 'Qp2malloc')
  fork do  
    rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QP2USER', 1), 'Qp2malloc')
    rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF8FFF50000'].pack("H*"), 16, 0)
    raise "ILE system failed with rc=#{rc}" if rc != 0
    puts "Child  #{Process.pid}: ILE system failed with rc=#{rc}" if rc != 0
    puts "Child  #{Process.pid}: PASE pointer #{PASEreturn[0, 8].unpack("H*")}"    
    puts "Child  #{Process.pid}: ILE SPP      #{ILEreturn[0, 16].unpack("H*")}"
    puts "Child  #{Process.pid}: _CVTSPP      [\"#{cvtspp.call(ILEreturn).to_s(16).rjust(16,'0')}\"]"
  end    
  rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QP2USER', 1), 'Qp2malloc')
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF8FFF50000'].pack("H*"), 16, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  puts "Parent #{Process.pid}: ILE system failed with rc=#{rc}" if rc != 0
  puts "Parent #{Process.pid}: PASE pointer #{PASEreturn[0, 8].unpack("H*")}"    
  puts "Parent #{Process.pid}: ILE SPP      #{ILEreturn[0, 16].unpack("H*")}"
  puts "Parent #{Process.pid}: _CVTSPP      [\"#{cvtspp.call(ILEreturn).to_s(16).rjust(16,'0')}\"]"
