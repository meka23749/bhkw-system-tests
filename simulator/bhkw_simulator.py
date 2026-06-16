import time
import threading
import logging
from enum import IntEnum
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusSlaveContext
from pymodbus.datastore import ModbusServerContext

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


class BHKWState(IntEnum):
    IDLE     = 0
    STARTING = 1
    RUNNING  = 2
    STOPPING = 3
    FAULT    = 4


class BHKWSimulator:
    def __init__(self):
        self.state           = BHKWState.IDLE
        self.power_output    = 0.0
        self.temperature     = 20.0
        self.fault_code      = 0
        self.runtime_minutes = 0
        self.power_setpoint  = 50.0
        self._lock           = threading.Lock()

        hr = ModbusSequentialDataBlock(1, [0] * 10)
        ir = ModbusSequentialDataBlock(1, [0] * 10)
        store = ModbusSlaveContext(hr=hr, ir=ir)
        self.context = ModbusServerContext(slaves=store, single=True)

    def _write_holding(self, address, value):
        self.context[0x00].setValues(3, address, [value])

    def _read_holding(self, address):
        return self.context[0x00].getValues(3, address, 1)[0]

    def _write_input(self, address, values):
        self.context[0x00].setValues(4, address, values)

    def _update_input_registers(self):
        self._write_input(1, [
            int(self.state),
            int(self.power_output * 10),
            int(self.temperature * 10),
            self.fault_code,
            self.runtime_minutes
        ])

    def _process_command(self):
        command = self._read_holding(1)
        sp_raw  = self._read_holding(2)
        self.power_setpoint = sp_raw / 10.0 if sp_raw > 0 else 50.0
        fault_inject = self._read_holding(3)

        with self._lock:
            if fault_inject > 0:
                logger.warning('Fault injection: code=%d', fault_inject)
                self.fault_code = fault_inject
                self.power_output = 0.0
                self.state = BHKWState.FAULT
                self._write_holding(3, 0)
            elif command == 1 and self.state == BHKWState.IDLE:
                logger.info('CMD: START')
                self.state = BHKWState.STARTING
                self._write_holding(1, 0)
            elif command == 2 and self.state == BHKWState.RUNNING:
                logger.info('CMD: STOP')
                self.state = BHKWState.STOPPING
                self._write_holding(1, 0)
            elif command == 3 and self.state == BHKWState.FAULT:
                logger.info('CMD: RESET')
                self.fault_code   = 0
                self.power_output = 0.0
                self.temperature  = 20.0
                self.state        = BHKWState.IDLE
                self._write_holding(1, 0)

    def _simulate_state(self):
        with self._lock:
            if self.state == BHKWState.STARTING:
                self.temperature  += 2.0
                self.power_output += 5.0
                if self.power_output >= self.power_setpoint:
                    self.power_output = self.power_setpoint
                    self.temperature  = 85.0
                    self.state        = BHKWState.RUNNING
                    logger.info('STATE -> RUNNING')
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
                    logger.info('STATE -> IDLE')
            elif self.state == BHKWState.FAULT:
                self.power_output = 0.0

        self._update_input_registers()
        logger.info(
            'State=%s Power=%.1fkW Temp=%.1fC Fault=%d',
            self.state.name, self.power_output, self.temperature, self.fault_code
        )

    def inject_fault(self, fault_code=1):
        with self._lock:
            logger.warning('Fault injected: code=%d', fault_code)
            self.fault_code   = fault_code
            self.power_output = 0.0
            self.state        = BHKWState.FAULT
        self._update_input_registers()

    def run_simulation_loop(self):
        logger.info('BHKW Simulator loop started')
        while True:
            self._process_command()
            self._simulate_state()
            time.sleep(1.0)

    def start_modbus(self, host='localhost', port=5020):
        logger.info('Modbus TCP Server on %s:%d', host, port)
        StartTcpServer(context=self.context, address=(host, port))


if __name__ == '__main__':
    import sys
    sys.path.insert(0, '.')
    from simulator.bhkw_api import start_api

    simulator = BHKWSimulator()

    sim_thread = threading.Thread(target=simulator.run_simulation_loop, daemon=True)
    sim_thread.start()

    modbus_thread = threading.Thread(
        target=simulator.start_modbus,
        kwargs={'host': 'localhost', 'port': 5020},
        daemon=True
    )
    modbus_thread.start()

    time.sleep(1)
    print('Modbus TCP on localhost:5020')
    print('REST API  on localhost:8080')

    start_api(simulator, host='localhost', port=8080)