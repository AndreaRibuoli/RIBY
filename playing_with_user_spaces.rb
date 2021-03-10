#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
# raise "Usage: playing_with_user_spaces.rb <cmd>" if ARGV.length != 1
# cmd  = ARGV[0]
name = 'MYSPACE'
lib  = 'RIBY'
Qualified_user_space_name = "#{name.ljust(10, ' ')}#{lib.ljust(10, ' ')}"
Extended_attribute        = 'USRSPC'.ljust(10, ' ')
Initial_size              = 2048
Initial_value             = ' '
Public_authority          = '*ALL'.ljust(10, ' ')
Text_description          = 'My user space'.ljust(50, ' ')


ILEpointer  = struct [ 'char b[16]' ]
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )

pQUSCRTUS  = ILEpointer.malloc
rc = rslobj2.call(pQUSCRTUS, 513, "QUSCRTUS", "QSYS")
puts rc
