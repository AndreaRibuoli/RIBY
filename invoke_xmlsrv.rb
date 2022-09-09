#! /QOpenSys/pkgs/bin/ruby
require 'fiddle'
require 'fiddle/import'
extend Fiddle::Importer                                                                                               
raise "Usage: invoke_xmlsrv.rb <xmlfile>" if ARGV.length != 1
ibmilib = 'XMLSERVICE' # 'XMLSERVICE', 'XMLSERVILE'
ebcdic =  'IBM037'     # 'IBM037', 'IBM280'
myIPC  = '*NA'.encode(ebcdic)
myCTL  = '*here'.encode(ebcdic)
script = File.read(ARGV[0])
xmlIN = script.encode(ebcdic)
ILEpointer  = struct [ 'char b[16]' ]
ILEarglist  = struct [ 'char c[96]' ]
XMLresult_t = struct [ 'unsigned char d[4096]' ]
preload    = Fiddle.dlopen(nil)
ileloadx   = Fiddle::Function.new( preload['_ILELOADX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_LONG_LONG )
ilesymx    = Fiddle::Function.new( preload['_ILESYMX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT )
ilecallx   = Fiddle::Function.new( preload['_ILECALLX'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SHORT, Fiddle::TYPE_INT], Fiddle::TYPE_INT )
setspp     = Fiddle::Function.new( preload['_SETSPP'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID )
ILEfunction  = ILEpointer.malloc
rc = ilesymx.call(ILEfunction, ileloadx.call("#{ibmilib}/XMLSTOREDP", 1), 'iPLUG4K')
if rc == 1 then
  xmlOUT = XMLresult_t.malloc
  ILEarguments = ILEarglist.malloc
  ILEarguments[0, 32] = ['0'.rjust(64,'0')].pack("H*")
  setspp.call(ILEarguments.to_ptr + 32, Fiddle::Pointer[myIPC])
  setspp.call(ILEarguments.to_ptr + 48, Fiddle::Pointer[myCTL])
  setspp.call(ILEarguments.to_ptr + 64, Fiddle::Pointer[xmlIN])
  setspp.call(ILEarguments.to_ptr + 80, Fiddle::Pointer[xmlOUT])
  rc = ilecallx.call(ILEfunction, ILEarguments, ['FFF4FFF4FFF4FFF40000'].pack("H*"), 0, 0)
  raise "ILE system failed with rc=#{rc}" if rc != 0
  size = xmlOUT.d[1]*256*256 + xmlOUT.d[2]*256 + xmlOUT.d[3] + 4 
  result = xmlOUT.d[4..size].pack('c*').force_encoding(ebcdic).encode('UTF-8')
  require 'nokogiri'
  doc = Nokogiri::XML(result)
  puts "doc.xpath('//xmlservice/pgm/parm/ds/data').map{|e| puts \"\#{e.attr('var')} = \#{e.content}\"}\n"
  doc.xpath('//xmlservice/pgm/parm/ds/data').map{|e| puts "#{e.attr('var')} = #{e.content}"}
  puts "\ndoc.xpath('//xmlservice/pgm/success').text\n"
  puts doc.xpath('//xmlservice/pgm/success').text
  puts "\ndoc.xpath('//xmlservice/pgm/return/data').text\n"
  puts doc.xpath('//xmlservice/pgm/return/data').text
end
