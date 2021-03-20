#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: playing_with_job_attributes.rb" if ARGV.length != 0


preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )
#
ILEpointer  = struct [ 'char b[16]' ]
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[112]' ]
argv = ILEparms.malloc
#
pQCLRTVJA  = ILEpointer.malloc
rc = rslobj2.call(pQCLRTVJA, 513, "QCLRTVJA", "QSYS")
puts 'rslobj2.call(pQCLRTVJA, 513, "QCLRTVJA", "QSYS") = ' + rc.to_s

rc = pgmcall.call(pQCLRTVJA, argv, 0)
puts 'pgmcall.call(pQCLRTVJA, argv, 0) = ' + rc.to_s
