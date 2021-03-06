{
    --------------------------------------------
    Filename: sensor.co2.scd30.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Sensirion SCD30 CO2 sensor
    Copyright (c) 2022
    Started Jul 10, 2021
    Updated Jul 9, 2022
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

' Operating modes
    STANDBY         = 0
    CONT            = 1

' Error codes
    EBADCRC         = $E000_0C0C

' Temperature scales
    C               = 0
    F               = 1

VAR

    long _co2
    long _temp
    long _rh
    word _presscomp
    byte _opmode
    byte _temp_scale

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef SCD30_I2C_BC
    i2c : "com.i2c.nocog"                       ' BC I2C engine
#else
    i2c : "com.i2c"                             ' PASM I2C engine
#endif
    core: "core.con.scd30"                      ' hw-specific low-level const's
    time: "time"                                ' basic timing functions
    crc : "math.crc"                            ' CRC routines
    fm  : "math.float.nocog"                    ' IEEE-754 float functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            if present{}
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

PUB Present{}: ack
' Test device bus presence
    ack := 0
    i2c.start{}
    ack := i2c.write(SLAVE_WR)
    i2c.stop{}                                  ' P: SCD30 doesn't support Sr
    return (ack == i2c#ACK)                     ' return TRUE if present

PUB AltComp(alt): curr_alt
' Compensate CO2 measurements based on altitude, in meters
'   Valid values: 0..65535
'   Any other value polls the chip and returns the current setting
'   NOTE: This setting is disregarded when ambient pressure is set
'   NOTE: This setting is stored in the sensor in non-volatile memory,
'       i.e., it will save even if power is lost
    curr_alt := 0
    readreg(core#ALTITUDECOMP, 3, @curr_alt)
    case alt
        0..65535:
            writereg(core#ALTITUDECOMP, 3, @alt)
        other:
            return curr_alt

PUB AmbPressure(press): curr_press
' Set ambient pressure, in millibars, for use in on-sensor compensation
'   Valid values:
'       0: disable compensation
'       700..1400
'   Any other value returns the current setting
'   NOTE: To effect settings, OpMode(CONT) must be called
    case press
        0, 700..1400:
            _presscomp := press
        other:
            return _presscomp

PUB AutoCal(state): curr_state
' Enable automatic self-calibration
'   Valid values: TRUE (-1 or 1), *FALSE (0)
'   Any other value polls the chip and returns the current setting
'   NOTE: This process requires the following in order to be successful:
'       1) The sensor must be powered continuously for a minimum of 7 days
'           (if power is removed, the process will abort and must be restarted)
'       2) The sensor should be exposed to fresh air for approx 1 hr every day
'       3) The sensor must be set to continuous measurement mode
'   NOTE: The calibration result is saved in non-volatile memory,
'       i.e., it will save even if power is lost (after completion)
    curr_state := 0
    readreg(core#AUTOSELFCAL, 3, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state)
            writereg(core#AUTOSELFCAL, 3, @state)
        other:
            return (curr_state == 1)

PUB CO2Bias(ppm): curr_ppm
' Manually set calibration/reference level of CO2 sensor
'   Valid values: 400..2000
'   Any other value polls the chip and returns the current setting
'   NOTE: The calibration value is saved in volatile memory,
'       i.e., it will not save if power is lost
    curr_ppm := 0
    readreg(core#SETRECALVAL, 3, @curr_ppm)
    case ppm
        400..2000:
            writereg(core#SETRECALVAL, 3, @ppm)
        other:
            return curr_ppm

PUB CO2Data{}: f_co2
' CO2 data
'   Returns: IEEE-754 float
    return _co2

PUB CO2PPM{}: ppm
' CO2 concentration, in tenths of a part-per-million
'   Returns: Integer
    return fm.ftrunc(fm.fmul(co2data{}, 10.0))

PUB DataReady{}: flag
' Flag indicating data ready
    flag := 0
    readreg(core#GETDRDY, 3, @flag)

    return ((flag & 1) == 1)

PUB DeviceID{}: id
' Read device identification

PUB Humidity{}: rh
' Relative humidity, as a percentage
'   Returns: Integer
    return fm.ftrunc(fm.fmul(humiditydata{}, 100.0))

PUB HumidityData{}: rh_adc
' Relative humidity data
'   Returns: IEEE-754 float
    return _rh

PUB MeasInterval(t_int): curr_t
' Set measurement interval, in seconds
'   Valid values: 2..1800
'   Any other value returns the current setting
    curr_t := 0
    readreg(core#SETMEASINTERV, 3, @curr_t)
    case t_int
        2..1800:
            writereg(core#SETMEASINTERV, 3, @t_int)
        other:
            return curr_t

PUB Measure{} | meas_tmp[5], crc_tmp
' Read measurement data
    readreg(core#READMEAS, 18, @meas_tmp)
    _co2.byte[3] := meas_tmp.byte[17]
    _co2.byte[2] := meas_tmp.byte[16]
    crc_tmp.byte[1] := meas_tmp.byte[15]
    _co2.byte[1] := meas_tmp.byte[14]
    _co2.byte[0] := meas_tmp.byte[13]
    crc_tmp.byte[0] := meas_tmp.byte[12]

    ifnot crc.sensirioncrc8(@_co2.byte[2], 2) == crc_tmp.byte[1] and {
}   crc.sensirioncrc8(@_co2, 2) == crc_tmp.byte[0]
        return EBADCRC

    _temp.byte[3] := meas_tmp.byte[11]
    _temp.byte[2] := meas_tmp.byte[10]
    crc_tmp.byte[1] := meas_tmp.byte[9]
    _temp.byte[1] := meas_tmp.byte[8]
    _temp.byte[0] := meas_tmp.byte[7]
    crc_tmp.byte[0] := meas_tmp.byte[6]

    ifnot crc.sensirioncrc8(@_temp.byte[2], 2) == crc_tmp.byte[1] and {
}   crc.sensirioncrc8(@_temp, 2) == crc_tmp.byte[0]
        return EBADCRC

    _rh.byte[3] := meas_tmp.byte[5]
    _rh.byte[2] := meas_tmp.byte[4]
    crc_tmp.byte[1] := meas_tmp.byte[3]
    _rh.byte[1] := meas_tmp.byte[2]
    _rh.byte[0] := meas_tmp.byte[1]
    crc_tmp.byte[0] := meas_tmp.byte[0]

    ifnot crc.sensirioncrc8(@_rh.byte[2], 2) == crc_tmp.byte[1] and {
}   crc.sensirioncrc8(@_rh, 2) == crc_tmp.byte[0]
        return EBADCRC

PUB OpMode(mode): curr_mode
' Set operating mode
'   Valid values:
'      *STANDBY (0): stop measuring
'       CONT (1): continuous measurement
'   Any other value returns the current setting
    curr_mode := _opmode
    case mode
        CONT:
            writereg(core#CONTMEAS, 2, @_presscomp)
        STANDBY:
            writereg(core#STOPMEAS, 0, 0)
        other:
            return curr_mode
    _opmode := mode

PUB Reset{}
' Reset the device
    writereg(core#SOFTRESET, 0, 0)
    time.usleep(core#T_RES)

PUB TempData{}: temp_adc
' Temperature data
'   Returns: IEEE-754 float
    return _temp

PUB TempScale(scale): curr_scale
' Set temperature scale used by Temperature method
'   Valid values:
'       C (0): Celsius
'       F (1): Fahrenheit
'   Any other value returns the current setting
    case scale
        C, F:
            _temp_scale := scale
        other:
            return _temp_scale

PUB Temperature{}: deg
' Current Temperature, in hundredths of a degree
'   Returns: Integer
'   (e.g., 2105 is equivalent to 21.05 deg C)
    return calctemp(tempdata{})

PUB Version{}: ver
' Firmware version
'   Returns: word [MSB:major..LSB:minor]
'   Known values: $03_42
    ver := 0
    readreg(core#FWVER, 3, @ver)

    return ver

PRI calcTemp(temp_adc): temp
' Calculate temperature, given raw temperature data
    temp := fm.ftrunc(fm.fmul(temp_adc, 100.0)) ' * 100 and convert to integer
    case _temp_scale
        C:
        F:
            return ((temp * 9_00) / 5_00) + 32_00
        other:
            return FALSE

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp_buff, crc_tmp
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        core#GETDRDY, core#FWVER, core#SETMEASINTERV, {
}       core#AUTOSELFCAL, core#SETRECALVAL, core#SETTEMPOFFS, {
}       core#ALTITUDECOMP:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}                          ' P: SCD30 doesn't support Sr

            time.usleep(core#T_WRRD)            ' wait between write and read

            i2c.start{}
            i2c.wr_byte(SLAVE_RD)

            ' read MSByte to LSByte
            i2c.rdblock_msbf(@tmp_buff, nr_bytes, i2c#NAK)
            i2c.stop{}

            crc_tmp := tmp_buff.byte[0]
            tmp_buff >>= 8
            if crc.sensirioncrc8(@tmp_buff, 2) == crc_tmp
                bytemove(ptr_buff, @tmp_buff, 2)
                return
            else
                return
        core#READMEAS:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr.byte[1]
            cmd_pkt.byte[2] := reg_nr.byte[0]
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}                          ' P: SCD30 doesn't support Sr

            time.usleep(core#T_WRRD)            ' wait between write and read

            i2c.start{}
            i2c.wr_byte(SLAVE_RD)

            ' read MSByte to LSByte
            i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:                                  ' invalid reg_nr
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, dat_tmp
' Write nr_bytes to the device from ptr_buff
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr.byte[1]
    cmd_pkt.byte[2] := reg_nr.byte[0]
    case reg_nr
        core#CONTMEAS, core#STOPMEAS, core#SETMEASINTERV, core#ALTITUDECOMP, {
}       core#SETRECALVAL, core#AUTOSELFCAL, core#SETTEMPOFFS:
            dat_tmp := long[ptr_buff]
            dat_tmp <<= 8
            dat_tmp.byte[0] := crc.sensirioncrc8(@dat_tmp.byte[1], 2)
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)

            ' write MSByte to LSByte
            i2c.wrblock_msbf(@dat_tmp, nr_bytes)
            i2c.stop{}
        core#STOPMEAS, core#SOFTRESET:
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 3)
            i2c.stop{}
        other:
            return

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

