# scd30-spin 
------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Sensirion SCD30 CO2 sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) ~~or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P)~~. Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 100kHz (*max recommended according to Sensirion is 50kHz*)
* Read CO2, Temperature, RH data (IEEE-754 float)
* Set measurement interval in seconds
* Sensor data-ready status
* Read sensor firmware version
* Soft-reset

## Requirements

P1/SPIN1:
* spin-standard-library

~~P2/SPIN2:~~
* ~~p2-spin-standard-library~~

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* ~~P2/SPIN2: FlexSpin (tested with 5.1.0-beta)~~ _(not yet implemented)_
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Sensor data only available in IEEE-754 floating point format

## TODO

- [x] add support for setting temperature scale
- [x] add support for integer sensor data return values, as in other drivers
- [ ] add support for pure-spin I2C engine
- [ ] port to P2/SPIN2
