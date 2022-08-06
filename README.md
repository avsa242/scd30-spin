# scd30-spin 
------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Sensirion SCD30 CO2 sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 100kHz (P2, or P1 with PASM engine), or ~30kHz (P1, SPIN engine)
    (*max recommended according to Sensirion is 50kHz*)
* Read CO2, Temperature, RH data (IEEE-754 float, or hundredths of unit integer)
* Set measurement interval in seconds
* Sensor data-ready status
* Read sensor firmware version
* Soft-reset
* Set altitude or ambient pressure used to compensate CO2 readings
* Automatic or manual calibration

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM I2C engine (none if the SPIN I2C engine is used)
* sensor.temp.common.spinh (source: spin-standard-library)
* sensor.rh.common.spinh (source: spin-standard-library)
* sensor.co2.common.spinh (source: spin-standard-library)

P2/SPIN2:
* p2-spin-standard-library
* sensor.temp.common.spin2h (source: p2-spin-standard-library)
* sensor.rh.common.spin2h (source: p2-spin-standard-library)
* sensor.co2.common.spin2h (source: p2-spin-standard-library)

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | NuCode      | FTBFS                 |
| P2        | SPIN2    | FlexSpin (5.9.14-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Requires a build-time change of behavior to the I2C engine; ensure the QUIRK_SCD30 preprocessor flag is added to the build command line

