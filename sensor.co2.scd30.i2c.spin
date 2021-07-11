{
    --------------------------------------------
    Filename: sensor.co2.scd30.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Sensirion SCD30 CO2 sensor
    Copyright (c) 2021
    Started Jul 10, 2021
    Updated Jul 11, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Error codes
    EBADCRC         = $E000_0C0C

VAR


OBJ

'    i2c : "com.i2c"                             ' PASM I2C engine (up to ~800kHz)
    i2c : "tiny.com.i2c"                        ' SPIN I2C engine (~40kHz)
    core: "core.con.scd30"                      ' hw-specific low-level const's
    time: "time"                                ' basic timing functions
    crc : "math.crc"                            ' CRC routines

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN))', I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if i2c.present(SLAVE_WR)            ' test device bus presence
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Set factory defaults
    reset{}

PUB DataReady{}: flag | crc_tmp
' Flag indicating data ready
    flag := 0
    readreg(core#GETDRDY, 3, @flag)
    crc_tmp := flag.byte[0]
    flag >>= 8

    if crc.sensirioncrc8(@flag, 2) == crc_tmp
        return ((flag & 1) == 1)
    else
        return EBADCRC

PUB DeviceID{}: id
' Read device identification

PUB Reset{}
' Reset the device
    writereg(core#SOFTRESET, 0, 0)

PUB Version{}: ver | crc_tmp
' Firmware version
'   Returns: word [MSB:major..LSB:minor]
'   Known values: $03_42
    ver := 0
    readreg(core#FWVER, 3, @ver)
    crc_tmp := ver.byte[0]
    ver >>= 8

    if crc.sensirioncrc8(@ver, 2) == crc_tmp
        return ver
    else
        return EBADCRC

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#GETDRDY, core#READMEAS, core#FWVER, core#SETMEASINTERV, {
}       core#AUTOSELFCAL, core#SETRECALVAL, core#SETTEMPOFFS, {
}       core#ALTITUDECOMP:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}

            time.msleep(3)                      ' wait between write and read

            i2c.start{}
            i2c.wr_byte(SLAVE_RD)

            ' read MSByte to LSByte
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr.byte[1]
    cmd_pkt.byte[2] := reg_nr.byte[0]
    case reg_nr
        core#CONTMEAS, core#STOPMEAS, core#SETMEASINTERV, core#ALTITUDECOMP, {
}       core#SETRECALVAL, core#AUTOSELFCAL, core#SETTEMPOFFS, core#SOFTRESET:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)

            ' write MSByte to LSByte
            i2c.wrblock_msbf(ptr_buff, nr_bytes)
            i2c.stop{}
        core#STOPMEAS, core#SOFTRESET:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}
        other:
            return


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
