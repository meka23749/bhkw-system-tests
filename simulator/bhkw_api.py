"""
BHKW REST API
Exposes BHKW controller state via FastAPI REST interface
Runs alongside the Modbus TCP simulator
Author: Steve Meka
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import uvicorn

app = FastAPI(
    title='BHKW REST API',
    description='REST interface for BHKW controller - parallel to Modbus TCP',
    version='1.0.0'
)

_simulator = None


def set_simulator(sim):
    global _simulator
    _simulator = sim


class StatusResponse(BaseModel):
    state: str
    power_output: float
    temperature: float
    fault_code: int
    runtime_minutes: int


class CommandResponse(BaseModel):
    success: bool
    message: str
    state: str


class FaultRequest(BaseModel):
    fault_code: int = 1


@app.get('/api/status', response_model=StatusResponse, tags=['Status'])
def get_status():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    return StatusResponse(
        state=_simulator.state.name,
        power_output=_simulator.power_output,
        temperature=_simulator.temperature,
        fault_code=_simulator.fault_code,
        runtime_minutes=_simulator.runtime_minutes
    )


@app.get('/api/power', tags=['Measurements'])
def get_power():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    return {'power_output': _simulator.power_output, 'unit': 'kW'}


@app.get('/api/temperature', tags=['Measurements'])
def get_temperature():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    return {'temperature': _simulator.temperature, 'unit': 'C'}


@app.post('/api/command/start', response_model=CommandResponse, tags=['Commands'])
def command_start():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    from simulator.bhkw_simulator import BHKWState
    if _simulator.state != BHKWState.IDLE:
        raise HTTPException(
            status_code=409,
            detail=f'Cannot START from state {_simulator.state.name}'
        )
    _simulator._write_holding(1, 1)
    return CommandResponse(success=True, message='START command sent', state=_simulator.state.name)


@app.post('/api/command/stop', response_model=CommandResponse, tags=['Commands'])
def command_stop():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    from simulator.bhkw_simulator import BHKWState
    if _simulator.state != BHKWState.RUNNING:
        raise HTTPException(
            status_code=409,
            detail=f'Cannot STOP from state {_simulator.state.name}'
        )
    _simulator._write_holding(1, 2)
    return CommandResponse(success=True, message='STOP command sent', state=_simulator.state.name)


@app.post('/api/command/reset', response_model=CommandResponse, tags=['Commands'])
def command_reset():
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    from simulator.bhkw_simulator import BHKWState
    if _simulator.state != BHKWState.FAULT:
        raise HTTPException(
            status_code=409,
            detail=f'Cannot RESET from state {_simulator.state.name}'
        )
    _simulator._write_holding(1, 3)
    return CommandResponse(success=True, message='RESET command sent', state=_simulator.state.name)


@app.post('/api/fault/inject', tags=['Testing'])
def inject_fault(request: FaultRequest):
    if _simulator is None:
        raise HTTPException(status_code=503, detail='Simulator not available')
    _simulator.inject_fault(fault_code=request.fault_code)
    return {'success': True, 'fault_code': request.fault_code, 'state': _simulator.state.name}


@app.get('/health', tags=['Health'])
def health():
    return {'status': 'ok', 'simulator': _simulator is not None}


def start_api(simulator, host='localhost', port=8080):
    set_simulator(simulator)
    uvicorn.run(app, host=host, port=port, log_level='warning')