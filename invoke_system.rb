#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_system.rb <cmd>" if ARGV.length != 1
cmd  = ARGV[0]
size = cmd.length
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[48]' ]
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
rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QC2SYS', 1), 'system')
if rc == 1 then
  ILEarguments = ILEarglist.malloc
  ILEarguments[0, 32] = ['0'.rjust(64,'0')].pack("H*")
  ILEarguments[32, 16] = [Fiddle::Pointer[cmd.encode('IBM037')].to_i.to_s(16).rjust(32,'0')].pack("H*")
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF50000'].pack("H*"), 0, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
end
