#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer

raise "Usage: reliving_old_glories.rb" if ARGV.length != 0
#
pgm   = "DCL DD POINTERS CHAR(32) BDRY(16);\nDCL SYSPTR .SYSPTR DEF(POINTERS) POS(1);\nDCL SPCPTR .SPCPTR DEF(POINTERS) POS(17);\nSETSPPFP .SPCPTR, .SYSPTR;\n"
len   = pgm.length
ILEerror    = struct [ 'char e[12]' ]
ILEparms    = struct [ 'char a[112]' ]
ILEpointer  = struct [ 'char b[16]' ]

pgmname     = 'MISTPTR1'
pgmlib      = "RIBY"
pgmtext     = ''
srcname     = '*NONE'
srclib      = ''
srcmbr      = ''
srcdatetime = ''
prtname     = 'QPRINT'
prtlib      = 'QGPL'
opt01       = '*LIST';          opt02   = ''; opt03   = ''; opt04   = ''; opt05   = ''; opt06   = ''; opt07   = ''; opt08   = ''
    opt09   = ''; opt10   = ''; opt11   = ''; opt12   = ''; opt13   = ''; opt14   = ''; opt15   = ''; opt16   = ''; opt17   = ''
numopt      = 1
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
#
pQPRCRTPG  = ILEpointer.malloc
rc = rslobj2.call(pQPRCRTPG, 513, "QPRCRTPG", "QSYS")
puts rc
#
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
puts rc
puts pError[0, 12].unpack("H*")
