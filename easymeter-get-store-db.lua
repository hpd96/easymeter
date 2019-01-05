#!/usr/bin/env lua5.3

-- 5.3 to support native 64bit hex to int conversion "tonumber"

-- install: lua5.3 ntpdate mosquitto-util wget

-- require 'dbg'

local SER_DEV = '/dev/ttyUSB0'
local MSG_LEN_HEX = 460
local MSG_LEN_BIN = 288

local SML_START_SEQUENCE = '1B1B1B1B0101010176'

--                 
                                        
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

print('easymeter SML')
     
assert(os.execute('stty -F ' .. SER_DEV .. ' raw 9600'))

wdh=0

repeat

  rserial=io.open(SER_DEV,"r")

  print('read serial...')

  rserial:flush()
  local t = ''

  msg = rserial:read(MSG_LEN_BIN,10)
  if msg then 
    txt = StringBytesToNumber(msg)
    -- print(txt)
    t = txt:sub(0,#SML_START_SEQUENCE)
--   print(SML_START_SEQUENCE)
--   print(t)
  end
  wdh=wdh+1
  
  if wdh > 6 then
        print('read serial 6 wdh failed!')
  	os.exit(1)
  end

  rserial:flush()
  rserial:close()
  
until t == SML_START_SEQUENCE


-- decode

lenMsg=string.byte(msg,28)-1
modell = msg:sub(28+1,28+1+lenMsg-1)
print( "modell " .. modell )

lenMsg=string.byte(msg,103)
hersteller = msg:sub(103+1,103+1+lenMsg-1)
print( "hersteller " .. hersteller )


PP=215
L=48
A=txt:sub(PP,PP+L-1)
-- print (A)
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M180 = tonumber(A:sub(31,31+16-1), 16) / 10000000
print( meas_key .. ' wirkarbeit zaehler sum: ' .. string.format( "%.3f", M180 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M181 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' zaehler t1 ' .. string.format( "%.3f", M181 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M182 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' zaehler t2 ' .. string.format( "%.3f", M182 ) .. " kWh" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M170 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' wirkleistung 3phasig ' .. string.format( "%.3f", M170 ) .. " W" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M2170 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' wirkleistung L1 ' .. string.format( "%.3f", M2170 ) .. " W" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M4170 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' wirkleistung L2 ' .. string.format( "%.3f", M4170 ) .. " W" )

PP=PP+L
L=40
A=txt:sub(PP,PP+L-1)
-- print ( A )
meas_key = 'M' .. string.format( "%d", tonumber( A:sub(9,10) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(11,12) ,16) ) .. '.' .. string.format( "%d", tonumber( A:sub(13,14) ,16) )
local M6170 = tonumber(A:sub(31,31+8-1), 16) / 100
print( meas_key .. ' wirkleistung L3 ' .. string.format( "%.3f", M6170 ) .. " W" )


-- plausibel?

if ( M180 > 999999 or M180 < 1000 ) then
	print( "M180 wirkarbeit zaehler sum: not plausible" )
	os.exit(1)
end
if ( M170 > 99999 or M170 < 0 ) then
	print( "M170 wirkleistung 3phasig: not plausible" )
	os.exit(1)
end



-- datum

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
 
myDatum = os.date("%Y-%m-%d")

--	os.exit(1)

-- store tageswert extern on database
--print( myDatum )

local cmd = "wget http://conil/strom/eingabe.php?datum=" .. myDatum .. "\\&licht=" .. string.format( "%.3f", M180 ) .. "\\&heiz= -q -O /tmp/wget-easymeter-summe.txt"
print(' speicher tageswert ' .. cmd)

assert(os.execute( cmd ))
assert(os.execute( "chmod a+rw /tmp/wget-easymeter-summe.txt" ))

local cmd = "wget http://conil/strom/eingabe-easymeter.php?datum=" .. myDatum .. "\\&w180=" .. string.format( "%.3f", M180 ) .. "\\&w170=" ..  string.format( "%.3f", M170 )  .. " -q -O /tmp/wget-easymeter-akt.txt"
print(' speicher easymeter aktuelle wirkleistung ' .. cmd)

assert(os.execute( cmd ))
assert(os.execute( "chmod a+rw /tmp/wget-easymeter-akt.txt" ))

-- send values via mqtt to openhab

local mqtt_topic = "hw/easymeter"
local mqtt_host = "localhost"
local mqtt_msg = "{\"w180\":\"" .. string.format( "%.3f", M180 ) .. "\",\"w170\":\"" ..  string.format( "%.3f", M170 )  .. "\"" 
  .. ",\"model\":\"" .. modell  .. "\"" .. "}"
local mqtt_pub = "mosquitto_pub -h " .. mqtt_host .. " -m '" .. mqtt_msg .. "' -t " .. mqtt_topic
print(" mqtt pub")
assert(os.execute( mqtt_pub ))

-- hw/easymeter {"w180":"12500.535","w170":"278.670"}

print("fini.")
                
