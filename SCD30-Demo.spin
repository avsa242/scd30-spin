{
    --------------------------------------------
    Filename: SCD30-Demo.spin
    Author: Jesse Burt
    Description: Demo of the SCD30 driver
    Copyright (c) 2021
    Started Jul 10, 2021
    Updated Jul 10, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 100_000                       ' max is 100_000
                                                ' (Sensirion recommends 50_000)

' --

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    co2     : "sensor.co2.scd30.i2c"
    math    : "tiny.math.float"
    fs[3]   : "string.float"

PUB Main{} | coo, temp, rh

    setup{}

    co2.reset{}
    co2.opmode(co2#CONT)
    co2.measinterval(2)
    repeat
        repeat until co2.dataready{} == true
        co2.measure{}
        coo := fs[0].floattostring(co2.co2data)
        temp := fs[1].floattostring(co2.tempdata)
        rh := fs[2].floattostring(co2.humiditydata)

        ser.position(0, 3)
        ser.printf1(string("CO2: %sppm     \n"), coo)
        ser.printf1(string("Temp: %sC      \n"), temp)
        ser.printf1(string("RH: %s%%      \n"), rh)
        time.msleep(100)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if co2.startx(I2C_SCL, I2C_SDA, I2C_HZ)
        ser.strln(string("SCD30 driver started"))
    else
        ser.strln(string("SCD30 driver failed to start - halting"))
        repeat

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
