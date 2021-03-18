#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: playing_with_qtemp.rb" if ARGV.length != 0
#
pgm =<<ENDPGM
  DCL SPCPTR .ARG001 PARM;
  DCL DD ARG001 BIN(4) BAS(.ARG001);
  DCL SPCPTR .ARG002 PARM;
  DCL DD ARG002 BIN(4) BAS(.ARG002);
  DCL SPCPTR .ARG003 PARM;
  DCL DD ARG003 BIN(4) BAS(.ARG003);
  DCL SPCPTR .SUM    PARM;
  DCL DD SUM BIN(4) BAS(.SUM);
  DCL OL SUM4ME (.ARG001, .ARG002, .ARG003, .SUM) PARM EXT MIN(4);
  DCL DD NBR-PARMS BIN(2);
  ENTRY * (SUM4ME) EXT;
  STPLLEN NBR-PARMS;
  CPYNV   SUM, 0;
  ADDN(S) SUM, ARG001;
  ADDN(S) SUM, ARG002;
  ADDN(S) SUM, ARG003;
RETURN:
  RTX *;
  PEND;
ENDPGM

pgm.gsub!("\n", ' ')

len   = pgm.length
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[112]' ]
ILEpointer  = struct [ 'char b[16]' ]
ILEparms2   = struct [ 'char d[40]' ]

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
Intermediate_representation_of_the_program         = pgm.encode('IBM037')
Length_of_intermediate_representation_of_program   = [len.to_s(16).rjust(8,'0')].pack("H*")
Qualified_program_name                             = "#{pgmname.ljust(10, ' ')}#{pgmlib.ljust(10, ' ')}".encode('IBM037')
Program_text                                       = pgmtext.ljust(50, ' ').encode('IBM037')
Qualified_source_file_name                         = "#{srcname.ljust(10, ' ')}#{srclib.ljust(10, ' ')}".encode('IBM037')
Source_file_member_information                     = srcmbr.ljust(10, ' ').encode('IBM037')
Source_file_last_changed_date_and_time_information = srcdatetime.ljust(13, ' ').encode('IBM037')
Qualified_printer_file_name                        = "#{prtname.ljust(10, ' ')}#{prtlib.ljust(10, ' ')}".encode('IBM037')
Starting_page_number                               = ['00000001'].pack("H*")
Public_authority                                   = '*ALL'.ljust(10, ' ').encode('IBM037')
Option_template                                    = ( opt01.ljust(11, ' ') + opt02.ljust(11, ' ') + opt03.ljust(11, ' ') +
                                                       opt04.ljust(11, ' ') + opt05.ljust(11, ' ') + opt06.ljust(11, ' ') +
                                                       opt07.ljust(11, ' ') + opt08.ljust(11, ' ') + opt09.ljust(11, ' ') +
                                                       opt10.ljust(11, ' ') + opt11.ljust(11, ' ') + opt12.ljust(11, ' ') +
                                                       opt13.ljust(11, ' ') + opt14.ljust(11, ' ') + opt15.ljust(11, ' ') +
                                                       opt16.ljust(11, ' ') + opt17.ljust(11, ' ') ).encode('IBM037')
Number_of_option_template_entries                  = [numopt.to_s(16).rjust(8,'0')].pack("H*")
pError      = ILEerror.malloc
#
preload    = Fiddle.dlopen(nil)
rslobj2    = Fiddle::Function.new( preload['_RSLOBJ2'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
pgmcall    = Fiddle::Function.new( preload['_PGMCALL'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )
#
pQPRCRTPG  = ILEpointer.malloc
rc = rslobj2.call(pQPRCRTPG, 513, "QPRCRTPG", "QSYS")

argv = ILEparms.malloc
argv[   0, 8] = [Fiddle::Pointer[Intermediate_representation_of_the_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[   8, 8] = [Fiddle::Pointer[Length_of_intermediate_representation_of_program].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  16, 8] = [Fiddle::Pointer[Qualified_program_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  24, 8] = [Fiddle::Pointer[Program_text].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  32, 8] = [Fiddle::Pointer[Qualified_source_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  40, 8] = [Fiddle::Pointer[Source_file_member_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  48, 8] = [Fiddle::Pointer[Source_file_last_changed_date_and_time_information].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  56, 8] = [Fiddle::Pointer[Qualified_printer_file_name].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  64, 8] = [Fiddle::Pointer[Starting_page_number].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  72, 8] = [Fiddle::Pointer[Public_authority].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  80, 8] = [Fiddle::Pointer[Option_template].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  88, 8] = [Fiddle::Pointer[Number_of_option_template_entries].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[  96, 8] = [pError.to_i.to_s(16).rjust(16,'0')].pack("H*")
argv[ 104, 8] = ['0'.rjust(16,'0')].pack("H*")
rc = pgmcall.call(pQPRCRTPG, argv, 0)
#
puts pError[0, 12].unpack("H*")
#
pSUM4ME  = ILEpointer.malloc
rc = rslobj2.call(pSUM4ME, 513, pgmname, pgmlib)
puts pSUM4ME[0, 16].unpack("H*")

argv2 = ILEparms2.malloc
arg001 = ['00000001'].pack("H*")
arg002 = ['00000002'].pack("H*")
arg003 = ['00000003'].pack("H*")
summa  = ['00000000'].pack("H*")
argv2[  0, 8] = [Fiddle::Pointer[arg001].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv2[  8, 8] = [Fiddle::Pointer[arg002].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv2[ 16, 8] = [Fiddle::Pointer[arg003].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv2[ 24, 8] = [Fiddle::Pointer[summa].to_i.to_s(16).rjust(16,'0')].pack("H*")
argv2[ 32, 8] = ['0'.rjust(16,'0')].pack("H*")

rc = pgmcall.call(pSUM4ME, argv2, 0)
puts rc

puts summa[0, 4].unpack("H*")[0].to_i(16)

