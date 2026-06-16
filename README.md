# BHKW System Tests — Robot Framework & Modbus TCP

Automated system tests for a BHKW (Blockheizkraftwerk / Combined Heat and Power) controller
using Robot Framework and Modbus TCP — with a Software-in-the-Loop (SiL) simulator.

## Architecture

Robot Framework Tests

|

| Modbus TCP

v

BHKW Simulator (Python)

|

| State Machine

v

IDLE -> STARTING -> RUNNING -> STOPPING -> IDLE

|

FAULT -> RESET -> IDLE

## Test Suites

| Suite | Tests | Description |
|-------|-------|-------------|
| test_start_stop.robot | TC01-TC03 | Start/Stop sequences and full cycle |
| test_fault_handling.robot | TC04-TC06 | Fault injection and recovery |
| test_power_regulation.robot | TC07-TC10 | Power output and temperature validation |

## Modbus Register Map

| Register | Type | Address | Description |
|----------|------|---------|-------------|
| Command | Holding | 0x0001 | 0=IDLE 1=START 2=STOP 3=RESET |
| Power Setpoint | Holding | 0x0002 | kW * 10 |
| State | Input | 0x0001 | 0=IDLE 1=STARTING 2=RUNNING 3=STOPPING 4=FAULT |
| Power Output | Input | 0x0002 | kW * 10 |
| Temperature | Input | 0x0003 | Celsius * 10 |
| Fault Code | Input | 0x0004 | 0=None 1=Overtemp 2=LowOil 3=GridFault |
| Runtime | Input | 0x0005 | minutes |

## Quick Start

pip install -r requirements.txt

Start simulator:
python simulator/bhkw_simulator.py

Run all tests:
robot --outputdir results tests/

Run specific suite:
robot --outputdir results tests/test_start_stop.robot

Run by tag:
robot --include smoke --outputdir results tests/

## Tech Stack
- Python 3.11
- Robot Framework 7.x
- pymodbus 3.x
- GitHub Actions CI

## Author
Steve Meka
