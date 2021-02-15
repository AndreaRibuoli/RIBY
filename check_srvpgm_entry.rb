#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: check_srvpgm_entry.rb <lib>/<srvpgm> <entry_name>" if ARGV.length != 2 
SrvPgmNm = struct [ 'char a[21]' ]
ILEpointer = struct [ 'char b[16]' ]
preload  = Fiddle.dlopen(nil)
ileloadx = Fiddle::Function.new( preload['_ILELOADX'], 
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],
                           Fiddle::TYPE_LONG_LONG )
ilesymx = Fiddle::Function.new( preload['_ILESYMX'],
                           [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP],
                           Fiddle::TYPE_INT )

searched = SrvPgmNm.malloc
searched[0, 21] = ARGV[0] 
srvpgm = ileloadx.call(searched, 1)
raise "Loading of service program #{ARGV[0]} failed" if srvpgm == -1
ILEfunction = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, srvpgm, ARGV[1])
raise "Searching for function entry '#{ARGV[1]}' in service program #{ARGV[0]} failed" if rc != 1

           
