{
----------------------------------------------------------------------------------------------------
    Filename:       SCD30-Demo.spin
    Description:    SCD30 driver demo
        * CO2 data output
    Author:         Jesse Burt
    Started:        Jul 10, 2021
    Updated:        May 23, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the bytecode-based I2C engine in the driver:
'#define SCD30_I2C_BC
'#pragma exportdef(SCD30_I2C_BC)


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    sensor: "sensor.co2.scd30" | SCL=28, SDA=29, I2C_FREQ=100_000
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"


PUB main() | co2

    setup()

    repeat
        ser.pos_xy(0, 3)
        sensor.measure()
        co2 := sensor.co2ppm()
        ser.printf(@"CO2 (ppm): %5.5d.%0d\n\r", (co2 / 10), (co2 // 10) )


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"SCD30 driver started")
    else
        ser.strln(@"SCD30 driver failed to start - halting")
        repeat

    sensor.preset_active()


DAT
{
Copyright 2025 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

