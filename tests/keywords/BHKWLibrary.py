"""
BHKW Robot Framework Library
Provides keywords for BHKW controller testing via Modbus TCP
Author: Steve Meka
"""
from pymodbus.client.tcp import ModbusTcpClient


class BHKWLibrary:

    ROBOT_LIBRARY_SCOPE = 'SUITE'

    STATE_MAP = {0: 'IDLE', 1: 'STARTING', 2: 'RUNNING', 3: 'STOPPING', 4: 'FAULT'}
    CMD_MAP   = {'IDLE': 0, 'START': 1, 'STOP': 2, 'RESET': 3}

    def __init__(self, host='localhost', port=5020, unit=1):
        self.host   = host
        self.port   = int(port)
        self.unit   = int(unit)
        self.client = None

    def connect_to_bhkw(self):
        self.client = ModbusTcpClient(self.host, port=self.port)
        result = self.client.connect()
        assert result, f'Failed to connect to BHKW at {self.host}:{self.port}'
        print(f'Connected to BHKW at {self.host}:{self.port}')

    def disconnect_from_bhkw(self):
        if self.client:
            self.client.close()
            print('Disconnected from BHKW')

    def send_command(self, command):
        cmd_value = self.CMD_MAP.get(command.upper())
        assert cmd_value is not None, f'Unknown command: {command}'
        self.client.write_register(1, cmd_value, slave=self.unit)
        print(f'Command sent: {command} ({cmd_value})')

    def read_state(self):
        result = self.client.read_input_registers(1, 5, slave=self.unit)
        state  = result.registers[0]
        return self.STATE_MAP.get(state, 'UNKNOWN')

    def read_power_output(self):
        result = self.client.read_input_registers(1, 5, slave=self.unit)
        return result.registers[1] / 10.0

    def read_temperature(self):
        result = self.client.read_input_registers(1, 5, slave=self.unit)
        return result.registers[2] / 10.0

    def read_fault_code(self):
        result = self.client.read_input_registers(1, 5, slave=self.unit)
        return result.registers[3]

    def wait_for_state(self, expected_state, timeout=30, interval=1):
        import time
        end_time = time.time() + float(timeout)
        while True:
            current = self.read_state()
            if current == expected_state:
                print(f'State reached: {expected_state}')
                return
            if time.time() > end_time:
                raise AssertionError(f'Timeout: Expected {expected_state} but got {current}')
            time.sleep(float(interval))

    def check_power_output(self, min_kw=0, max_kw=100):
        power = self.read_power_output()
        assert power >= float(min_kw), f'Power {power}kW below minimum {min_kw}kW'
        assert power <= float(max_kw), f'Power {power}kW above maximum {max_kw}kW'
        print(f'Power OK: {power}kW')

    def check_temperature(self, min_temp=0, max_temp=90):
        temp = self.read_temperature()
        assert temp >= float(min_temp), f'Temp {temp}C below minimum {min_temp}C'
        assert temp <= float(max_temp), f'Temp {temp}C above maximum {max_temp}C'
        print(f'Temperature OK: {temp}C')

    def check_no_fault(self):
        fault = self.read_fault_code()
        assert fault == 0, f'Unexpected fault code: {fault}'

    def inject_fault(self, fault_code=1):
        self.client.write_register(3, int(fault_code), slave=self.unit)
        print(f'Fault injected: code={fault_code}')