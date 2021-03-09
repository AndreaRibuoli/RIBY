#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer
                                                                                                
# raise "Usage: playing_with_user_spaces.rb <cmd>" if ARGV.length != 1
# cmd  = ARGV[0]
name = 'MYSPACE'
lib  = 'RIBY'
Qualified_user_space_name = "#{name.rjust(10, ' ')}#{lib.rjust(10, ' ')}"
Extended_attribute        = 'USRSPC'.rjust(10, ' ')
Initial_size              = 2048
Initial value             = ' '
Public_authority          = '*ALL'.rjust(10, ' ')
Text_description          = 'My user space'.rjust(50, ' ')

cmd = "CALL PGM(QUSCRTUS) PARM('#{Qualified_user_space_name}' '#{Extended_attribute}' #{Initial_size} '#{Initial value}' '#{Public_authority}' '#{Text_description}')".encode('IBM037')

ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[48]' ]
preload    = Fiddle.dlopen(nil)
ileloadx   = Fiddle::Function.new( preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
ilesymx    = Fiddle::Function.new( preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
ilecallx   = Fiddle::Function.new( preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )

ILEfunction  = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, ileloadx.call('QSYS/QC2SYS', 1), 'system')
if rc == 1 then
  ILEarguments = ILEarglist.malloc
  ILEarguments[0, 32] = ['0'.rjust(64,'0')].pack("H*")
  setspp.call(ILEarguments.to_ptr + 32, Fiddle::Pointer[cmd])
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF40000'].pack("H*"), 0, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
end
