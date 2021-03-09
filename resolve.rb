#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
raise "Usage: invoke_system.rb <lib> <obj> <type_subt_int>" if ARGV.length != 3
lib  = ARGV[0].upcase
obj  = ARGV[1].upcase
type = ARGV[2].to_i
ILEpointer  = struct [ 'char a[16]' ]
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'],
             [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
             Fiddle::TYPE_INT )
ILEobject = ILEpointer.malloc
rc = rslobj2.call(ILEobject, type, obj, lib)
if rc == 0 then
  puts "Object #{lib}/#{obj} of type 0x#{type.to_s(16).rjust(4,'0')} resolved to #{ILEobject[0, 16].unpack("H*")}"
else
  puts "Object #{lib}/#{obj} of type 0x#{type.to_s(16).rjust(4,'0')} not resolved!"
end
