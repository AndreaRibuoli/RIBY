#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_system.rb <cmd>" if ARGV.length != 1
cmd  = ARGV[0].ljust(64, ' ').encode('IBM037')
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[64]' ]
OperDesc    = struct [ 'char d[1024]' ]
Buffer      = struct [ 'char e[64]' ]
preload    = Fiddle.dlopen(nil)
ileloadx   = Fiddle::Function.new( preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
ilesymx    = Fiddle::Function.new( preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
ilecallx   = Fiddle::Function.new( preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )

ILEfunction  = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, ileloadx.call('RIBY/RIBY_SRV', 1), 'WDUMP2')
if rc == 1 then
  od = OperDesc.malloc
  inBuffer = Buffer.malloc
  inBuffer[0, 64] = cmd
  outBuffer = Buffer.malloc
  ILEarguments = ILEarglist.malloc
  setspp.call(ILEarguments.to_ptr, od)
  ILEarguments[16, 16] = ['0'.rjust(32,'0')].pack("H*")
  setspp.call(ILEarguments.to_ptr + 32, inBuffer)
  setspp.call(ILEarguments.to_ptr + 48, outBuffer)
  puts "Prepared ILEarguments struct"
  puts ILEarguments[0, 16].unpack("H*")
  puts ILEarguments[16, 16].unpack("H*")
  puts ILEarguments[32, 16].unpack("H*")
  puts ILEarguments[48, 16].unpack("H*")
  puts "Prepared inBuffer: #{inBuffer[0,64].unpack("H*")}"
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF4FFF40000'].pack("H*"), 0, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  puts "Returned ILEarguments struct"
  puts ILEarguments[0, 16].unpack("H*")
  puts ILEarguments[16, 16].unpack("H*")
  puts ILEarguments[32, 16].unpack("H*")
  puts ILEarguments[48, 16].unpack("H*")
  puts "Result: #{outBuffer[0,64].force_encoding('IBM037').encode('utf-8')}"
end
