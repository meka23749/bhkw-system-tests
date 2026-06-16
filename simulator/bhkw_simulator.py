"""
BHKW Controller Simulator
Simulates a CHP (Combined Heat and Power) controller via Modbus TCP
Acts as a Software-in-the-Loop (SiL) environment for system tests

Modbus Register Map:
  Holding Registers (Read/Write):
    0x0001 - Command Register: 0=IDLE, 1=START, 2=STOP, 3=RESET
    0x0002 - Power Setpoint (kW * 10)

  Input Registers (Read Only):
    0x0001 - State: 0=IDLE, 1=STARTING, 2=RUNNING, 3=STOPPING, 4=FAULT
    0x0002 - Current Power Output (kW * 10)
    0x0003 - Engine Temperature (C * 10)
    0x0004 - Fault Code: 0=None, 1=Overtemp, 2=LowOil, 3=GridFault
    0x0005 - Runtime (minutes)

Author: Steve Meka
"""

import time
import threading
import logging
from enum import IntEnum
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


class BHKWState(IntEnum):
    IDLE     = 0
    STARTING = 1
    RUNNING  = 2
    STOPPING = 3
    FAULT    = 4


class BHKWCommand(IntEnum):
    IDLE  = 0
    START = 1
    STOP  = 2
    RESET = 3


class BHKWSimulator:
    def __init__(self):
        self.state           = BHKWState.IDLE
        self.power_output    = 0.0
        self.temperature     = 20.0
        self.fault_code      = 0
        self.runtime_minutes = 0
        self.power_setpoint  = 50.0
        self._running        = True
        self._lock           = threading.Lock()

        self.holding = ModbusSequentialDataBlock(0, [0] * 20)
        self.input   = ModbusSequentialDataBlock(0, [0] * 20)

        store = ModbusSlaveContext(hr=self.holding, ir=self.input)
        self.context = ModbusServerContext(slaves=store, single=True)

    def _update_input_registers(self):
        self.input.setValues(1, [
            int(self.state),
            int(self.power_output * 10),
            int(self.temperature * 10),
            self.fault_code,
            self.runtime_minutes
        ])

    def _process_command(self):
        values  = self.holding.getValues(1, 2)
        command = values[0]
        self.power_setpoint = values[1] / 10.0 if values[1] > 0 else 50.0

        with self._lock:
            if command == BHKWCommand.START and self.state == BHKWState.IDLE:
                logger.info("CMD: START received")
                self.state = BHKWState.STARTING
            elif command == BHKWCommand.STOP and self.state == BHKWState.RUNNING:
                logger.info("CMD: STOP received")
                self.state = BHKWState.STOPPING
            elif command == BHKWCommand.RESET and self.state == BHKWState.FAULT:
                logger.info("CMD: RESET received")
                self.fault_code   = 0
                self.power_output = 0.0
                self.temperature  = 20.0
                self.state        = BHKWState.IDLE

    def _simulate_state(self):
        with self._lock:
            if self.state == BHKWState.STARTING:
                self.temperature  += 2.0
                self.power_output += 5.0
                if self.power_output >= self.power_setpoint:
                    self.power_output = self.power_setpoint
                    self.temperature  = 85.0
                    self.state        = BHKWState.RUNNING
                    logger.info("STATE -> RUNNING")
            elif self.state == BHKWState.RUNNING:
                self.runtime_minutes += 1
                self.power_output = self.power_setpoint + (self.runtime_minutes % 3 - 1)
                self.temperature  = 85.0 + (self.runtime_minutes % 5 - 2)
            elif self.state == BHKWState.STOPPING:
                self.power_output -= 5.0
                self.temperature  -= 3.0
                if self.power_output <= 0:
                    self.power_output = 0.0
                    self.temperature  = 25.0
                    self.state        = BHKWState.IDLE
                    logger.info("STATE -> IDLE")
            elif self.state == BHKWState.FAULT:
                self.power_output = 0.0

        self._update_input_registers()
        logger.info(
            f"State={self.state.name} Power={self.power_output:.1f}kW "
            f"Temp={self.temperature:.1f}C Fault={self.fault_code}"
        )

    def inject_fault(self, fault_code=1):
        with self._lock:
            logger.warning(f"Fault injected: code={fault_code}")
            self.fault_code   = fault_code
            self.power_output = 0.0
            self.state        = BHKWState.FAULT
        self._update_input_registers()

    def run_simulation_loop(self):
        logger.info("BHKW Simulator started")
        while self._running:
            self._process_command()
            self._simulate_state()
            time.sleep(1.0)

    def start(self, host="localhost", port=5020):
        sim_thread = threading.Thread(target=self.run_simulation_loop, daemon=True)
        sim_thread.start()
        logger.info(f"Modbus TCP Server listening on {host}:{port}")
        StartTcpServer(context=self.context, address=(host, port))


if __name__ == "__main__":
    simulator = BHKWSimulator()
    simulator.start(host="localhost", port=5020)
