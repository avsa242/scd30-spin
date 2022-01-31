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
* 1 extra core/cog if using the PASM-based I2C engine (N/A for SPIN-based engine)

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1 OpenSpin (bytecode): Untested (deprecated)
* P1/SPIN1 FlexSpin (bytecode): OK, tested with 5.9.7-beta
* P1/SPIN1 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~P2/SPIN2 FlexSpin (nu-code): FTBFS, tested with 5.9.7-beta~~
* P2/SPIN2 FlexSpin (native): OK, tested with 5.9.7-beta
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build

