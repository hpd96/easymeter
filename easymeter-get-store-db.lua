#!/usr/bin/env lua

-- require 'dbg'

local SER_DEV = '/dev/ttyUSB0'
local MSG_LEN_HEX = 460
local MSG_LEN_BIN = 288

local SML_START_SEQUENCE = '1B1B1B1B0101010176'
                 
                                        
function StringBytesToNumber(str)
 local hextxt = ''
 local len = #str
 for i = 1,len do
   ttt = string.byte(str,i)
   hextxt = hextxt .. string.format("%02X",ttt) 
 end
 return hextxt
end
 
--

myYear = tonumber(os.date("%Y"))
if ( myYear > 2032 or myYear < 2014 ) then
	print("date not set")
	print(".")                                                         
	os.execute( '/usr/sbin/ntpdate ptbtime1.ptb.de' )
	print(".")       
end

	
myYear = tonumber(os.date("%Y"))
if ( myYear > 2032 or myYear < 2014 ) then
	print("date not set")
	os.exit(1)
end
 

--
     
assert(os.execute('stty -F '..SER_DEV..' raw 9600'))

wdh=0

repeat

  rserial=io.open(SER_DEV,"r")

  print('read easymeter')

  rserial:flush()
  local t = ''

  msg = rserial:read(MSG_LEN_BIN,10)
  if msg then 
    txt = StringBytesToNumber(msg)
    print(txt)
    t = txt:sub(0,#SML_START_SEQUENCE)
--   print(SML_START_SEQUENCE)
--   print(t)
  end
  wdh=wdh+1
  
  if wdh > 6 then
  	os.exit(1)
  end

  rserial:flush()
  rserial:close()
  
until t == SML_START_SEQUENCE

 
PP=181
L=34
A=txt:sub(PP,PP+L-1)
-- print( "hersteller " ..  A:sub(26,26+8-1) )
print( "hersteller " ..  msg:sub(89+13,89+13+4) )

PP=PP+L
L=48
A=txt:sub(PP,PP+L-1)
-- print ( 'dd ' .. A )
-- print( A:sub(31,31+16-1) )
local M180 = tonumber(A:sub(31,31+16-1), 16)
M180 = M180 / 10000000
-- print(M180)
print( '180 wirkarbeit zaehler sum: ' .. string.format( "%.3f", M180 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( 'cc ' ..  A )
local M181 = tonumber(A:sub(31,31+8-1), 16)
-- print(M181)
print( '181 zaehler t1 ' .. string.format( "%.3f", M181 / 10000 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
local M182 = tonumber(A:sub(31,31+8-1), 16)
-- print(M182)
print( '182 zaehler t2 ' .. string.format( "%.3f", M182 / 10000 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
local M170 = tonumber(A:sub(31,31+8-1), 16)
-- print(M170)
print( '170 wirkleistung 3ph ' .. string.format( "%.3f", M170 / 100 ) .. " W" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
local M2170 = tonumber(A:sub(31,31+8-1), 16)
-- print(M2170)
print( '2170 wirkleistung L1 ' .. string.format( "%.3f", M2170 / 100 ) .. " W" )



PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
local M4170 = tonumber(A:sub(31,31+8-1), 16)
-- print(M4170)
print( '4170 wirkleistung L2 ' .. string.format( "%.3f", M4170 / 100 ) .. " W" )


PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
local M6170 = tonumber(A:sub(31,31+8-1), 16)
-- print(M6170)
print( '6170 wirkleistung L3 ' .. string.format( "%.3f", M6170 / 100 ) .. " W" )




-- datum
myDatum = os.date("%Y-%m-%d")


if ( M180 > 99999 or M180 < 5000 ) then
	echo "M180 not plausible"
	os.exit(1)
end

-- store tageswert
print( myDatum )
local cmd = "wget http://conil/strom/eingabe.php?datum=" .. myDatum .. "\\&licht=" .. string.format( "%.3f", M180 ) .. "\\&heiz= -q -O /tmp/wget-easymeter-summe.txt"
print(' speicher tageswert ' .. cmd)

assert(os.execute( cmd ))

local cmd = "wget http://conil/strom/eingabe-easymeter.php?datum=" .. myDatum .. "\\&w180=" .. string.format( "%.3f", M180 ) .. "\\&w170=" ..  string.format( "%.3f", M170 / 100 )  .. " -q -O /tmp/wget-easymeter-akt.txt"
print(' speicher easymeter aktuelle wirkleistung ' .. cmd)

assert(os.execute( cmd ))

-- mqtt

local mqtt_msg = "{\"w180\":\"" .. string.format( "%.3f", M180 ) .. "\",\"w170\":\"" ..  string.format( "%.3f", M170 / 100 )  .. "\"}"
local mqtt_pub = "mosquitto_pub -h localhost -m '" .. mqtt_msg .. "' -t hw/easymeter"
assert(os.execute( mqtt_pub ))

-- hw/easymeter {"w180":"12500.535","w170":"278.670"}

print("fini.")
                
