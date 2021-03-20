#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: playing_with_qtemp.rb <num>" if ARGV.length != 1

tot = ARGV[0].to_i

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
pQPRCRTPG  = ILEpointer.malloc
rc = rslobj2.call(pQPRCRTPG, 513, "QPRCRTPG", "QSYS")
ILEparms2 = []
#
tot.times {|n|
#
pgm =<<ENDPGM
  DCL DD NBR-PARMS BIN(2);
  DCL SPCPTR .SUM PARM;
  DCL DD SUM BIN(4) BAS(.SUM);
  #{s = ''; n.times{|t| s = s + ' DCL SPCPTR .ARG' + t.to_s + ' PARM; DCL DD ARG' + t.to_s + ' BIN(4) BAS(.ARG' + t.to_s + ');'}; s}
DCL OL SUM4ME (.SUM#{s = ''; n.times{|t| s = s + ', .ARG' + t.to_s}; s}) PARM EXT MIN(1);
  ENTRY * (SUM4ME) EXT;
  STPLLEN NBR-PARMS;
  CPYNV SUM, 0;
  #{s = ''; n.times{|t| s = s + ' ADDN(S) SUM, ARG' + t.to_s + ';'}; s}
RETURN:
  RTX *;
  PEND;
ENDPGM

pgm.gsub!("\n", ' ')

len   = pgm.length
ILEparms2[n] = struct [ "char d[#{n*8}]" ]

pgmname     = 'SUM4ME'
pgmlib      = "QTEMP"
pgmtext     = 'Three addenda'
srcname     = '*NONE'
srclib      = ''
srcmbr      = ''
srcdatetime = ''
prtname     = 'QPRINT'
prtlib      = 'QGPL'
opt01       = '*REPLACE'   ; opt02 = '*LIST'; opt03   = ''; opt04   = ''; opt05   = ''; opt06   = ''; opt07   = ''; opt08   = ''
    opt09   = ''; opt10   = ''; opt11   = ''; opt12   = ''; opt13   = ''; opt14   = ''; opt15   = ''; opt16   = ''; opt17   = ''
numopt      = 2
intermediate_representation_of_the_program         = pgm.encode('IBM037')
length_of_intermediate_representation_of_program   = [len.to_s(16).rjust(8,'0')].pack("H*")
qualified_program_name                             = "#{pgmname.ljust(10, ' ')}#{pgmlib.ljust(10, ' ')}".encode('IBM037')
program_text                                       = pgmtext.ljust(50, ' ').encode('IBM037')
qualified_source_file_name                         = "#{srcname.ljust(10, ' ')}#{srclib.ljust(10, ' ')}".encode('IBM037')
source_file_member_information                     = srcmbr.ljust(10, ' ').encode('IBM037')
source_file_last_changed_date_and_time_information = srcdatetime.ljust(13, ' ').encode('IBM037')
qualified_printer_file_name                        = "#{prtname.ljust(10, ' ')}#{prtlib.ljust(10, ' ')}".encode('IBM037')
starting_page_number                               = ['00000001'].pack("H*")
public_authority                                   = '*ALL'.ljust(10, ' ').encode('IBM037')
option_template                                    = ( opt01.ljust(11, ' ') + opt02.ljust(11, ' ') + opt03.ljust(11, ' ') +
                                                       opt04.ljust(11, ' ') + opt05.ljust(11, ' ') + opt06.ljust(11, ' ') +
                                                       opt07.ljust(11, ' ') + opt08.ljust(11, ' ') + opt09.ljust(11, ' ') +
                                                       opt10.ljust(11, ' ') + opt11.ljust(11, ' ') + opt12.ljust(11, ' ') +
                                                       opt13.ljust(11, ' ') + opt14.ljust(11, ' ') + opt15.ljust(11, ' ') +
                                                       opt16.ljust(11, ' ') + opt17.ljust(11, ' ') ).encode('IBM037')
number_of_option_template_entries                  = [numopt.to_s(16).rjust(8,'0')].pack("H*")
pError      = ILEerror.malloc
#

argv[   0, 8] = [Fiddle::Pointer[intermediate_representation_of_the_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[   8, 8] = [Fiddle::Pointer[length_of_intermediate_representation_of_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  16, 8] = [Fiddle::Pointer[qualified_program_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  24, 8] = [Fiddle::Pointer[program_text].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  32, 8] = [Fiddle::Pointer[qualified_source_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  40, 8] = [Fiddle::Pointer[source_file_member_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  48, 8] = [Fiddle::Pointer[source_file_last_changed_date_and_time_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  56, 8] = [Fiddle::Pointer[qualified_printer_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  64, 8] = [Fiddle::Pointer[starting_page_number].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  72, 8] = [Fiddle::Pointer[public_authority].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  80, 8] = [Fiddle::Pointer[option_template].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  88, 8] = [Fiddle::Pointer[number_of_option_template_entries].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  96, 8] = [pError.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 104, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQPRCRTPG, argv, 0)
#
#
pSUM4ME  = ILEpointer.malloc
rc = rslobj2.call(pSUM4ME, 513, pgmname, pgmlib)

puts pSUM4ME[0, 16].unpack("H*")
argv2 = ILEparms2[n].malloc
summa  = ['00000000'].pack("H*")
argv2[  0, 8] = [Fiddle::Pointer[summa].to_i.to_s(16).rjust(16,'0')].pack("H*")
arg = []

n.times {|j|
  j = j+1;
  arg[j] = [j.to_s(16).rjust(8,'0')].pack("H*")
  argv2[  8*j, 8] = [Fiddle::Pointer[arg[j]].to_i.to_s(16).rjust(16,'0')].pack("H*")
}
argv2[  8*(n+1), 8] = ['0'.rjust(16,'0')].pack("H*")

rc = pgmcall.call(pSUM4ME, argv2, 0)

def get_i(a)
    a[0, 4].unpack("H*")[0].to_i(16)
end

puts "somma = #{get_i(summa)}"
}
