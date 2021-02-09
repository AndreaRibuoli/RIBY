#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

SrvPgmNm = struct [ 'char a[21]' ]
preload  = Fiddle.dlopen(nil)
ileloadx = Fiddle::Function.new( preload['_ILELOADX'], 
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                           Fiddle::TYPE_LONG_LONG )
searched = SrvPgmNm.malloc
searched[0, 21] = ARGV[0] 
srvpgm = ileloadx.call(searched, 1)
check = 'not ' if srvpgm == -1 
puts "'#{ARGV[0]}' is #{check}loadable from PASE\n"                          
