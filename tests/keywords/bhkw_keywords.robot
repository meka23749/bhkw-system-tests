*** Settings ***
Library    pymodbus.client    WITH NAME    Modbus
Library    Collections
Library    OperatingSystem

*** Variables ***
feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_HOST}    localhost
feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_PORT}    5020
feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}        1

*** Keywords ***

Connect To BHKW
    [Documentation]    Establish Modbus TCP connection to BHKW controller
    feat: add BHKW controller simulator with Modbus TCP and state machine{client}=    pymodbus.client.ModbusTcpClient    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_HOST}    port=feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_PORT}
    feat: add BHKW controller simulator with Modbus TCP and state machine{result}=    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{client}    connect
    Should Be True    feat: add BHKW controller simulator with Modbus TCP and state machine{result}    msg=Failed to connect to BHKW Modbus server
    Set Suite Variable    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    feat: add BHKW controller simulator with Modbus TCP and state machine{client}
    Log    Connected to BHKW at feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_HOST}:feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_PORT}

Disconnect From BHKW
    [Documentation]    Close Modbus TCP connection
    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    close
    Log    Disconnected from BHKW

Send Command
    [Documentation]    Write command to BHKW holding register
    [Arguments]    feat: add BHKW controller simulator with Modbus TCP and state machine{command}
    ...    feat: add BHKW controller simulator with Modbus TCP and state machine{START}=1    feat: add BHKW controller simulator with Modbus TCP and state machine{STOP}=2    feat: add BHKW controller simulator with Modbus TCP and state machine{RESET}=3    feat: add BHKW controller simulator with Modbus TCP and state machine{IDLE}=0
    feat: add BHKW controller simulator with Modbus TCP and state machine{cmd_map}=    Create Dictionary    START=1    STOP=2    RESET=3    IDLE=0
    feat: add BHKW controller simulator with Modbus TCP and state machine{cmd_value}=    Get From Dictionary    feat: add BHKW controller simulator with Modbus TCP and state machine{cmd_map}    feat: add BHKW controller simulator with Modbus TCP and state machine{command}
    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    write_register    1    feat: add BHKW controller simulator with Modbus TCP and state machine{cmd_value}    slave=feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}
    Log    Command sent: feat: add BHKW controller simulator with Modbus TCP and state machine{command} (feat: add BHKW controller simulator with Modbus TCP and state machine{cmd_value})

Read State
    [Documentation]    Read current BHKW state from input register
    feat: add BHKW controller simulator with Modbus TCP and state machine{result}=    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    read_input_registers    1    5    slave=feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}
    feat: add BHKW controller simulator with Modbus TCP and state machine{state}=     Get From List    feat: add BHKW controller simulator with Modbus TCP and state machine{result.registers}    0
    feat: add BHKW controller simulator with Modbus TCP and state machine{state_map}=    Create Dictionary    0=IDLE    1=STARTING    2=RUNNING    3=STOPPING    4=FAULT
    feat: add BHKW controller simulator with Modbus TCP and state machine{state_name}=    Get From Dictionary    feat: add BHKW controller simulator with Modbus TCP and state machine{state_map}    feat: add BHKW controller simulator with Modbus TCP and state machine{state}
    [Return]    feat: add BHKW controller simulator with Modbus TCP and state machine{state_name}

Read Power Output
    [Documentation]    Read current power output in kW
    feat: add BHKW controller simulator with Modbus TCP and state machine{result}=    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    read_input_registers    1    5    slave=feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}
    feat: add BHKW controller simulator with Modbus TCP and state machine{raw}=       Get From List    feat: add BHKW controller simulator with Modbus TCP and state machine{result.registers}    1
    feat: add BHKW controller simulator with Modbus TCP and state machine{power}=     Evaluate    feat: add BHKW controller simulator with Modbus TCP and state machine{raw} / 10.0
    [Return]    feat: add BHKW controller simulator with Modbus TCP and state machine{power}

Read Temperature
    [Documentation]    Read engine temperature in Celsius
    feat: add BHKW controller simulator with Modbus TCP and state machine{result}=    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    read_input_registers    1    5    slave=feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}
    feat: add BHKW controller simulator with Modbus TCP and state machine{raw}=       Get From List    feat: add BHKW controller simulator with Modbus TCP and state machine{result.registers}    2
    feat: add BHKW controller simulator with Modbus TCP and state machine{temp}=      Evaluate    feat: add BHKW controller simulator with Modbus TCP and state machine{raw} / 10.0
    [Return]    feat: add BHKW controller simulator with Modbus TCP and state machine{temp}

Read Fault Code
    [Documentation]    Read fault code from input register
    feat: add BHKW controller simulator with Modbus TCP and state machine{result}=    Call Method    feat: add BHKW controller simulator with Modbus TCP and state machine{MODBUS_CLIENT}    read_input_registers    1    5    slave=feat: add BHKW controller simulator with Modbus TCP and state machine{UNIT_ID}
    feat: add BHKW controller simulator with Modbus TCP and state machine{fault}=     Get From List    feat: add BHKW controller simulator with Modbus TCP and state machine{result.registers}    3
    [Return]    feat: add BHKW controller simulator with Modbus TCP and state machine{fault}

Wait For State
    [Documentation]    Wait until BHKW reaches expected state within timeout
    [Arguments]    feat: add BHKW controller simulator with Modbus TCP and state machine{expected_state}    feat: add BHKW controller simulator with Modbus TCP and state machine{timeout}=30    feat: add BHKW controller simulator with Modbus TCP and state machine{interval}=1
    feat: add BHKW controller simulator with Modbus TCP and state machine{end_time}=    Evaluate    time.time() + feat: add BHKW controller simulator with Modbus TCP and state machine{timeout}    modules=time
    WHILE    True
        feat: add BHKW controller simulator with Modbus TCP and state machine{current}=    Read State
        Run Keyword If    'feat: add BHKW controller simulator with Modbus TCP and state machine{current}' == 'feat: add BHKW controller simulator with Modbus TCP and state machine{expected_state}'    Return From Keyword
        feat: add BHKW controller simulator with Modbus TCP and state machine{now}=    Evaluate    time.time()    modules=time
        Run Keyword If    feat: add BHKW controller simulator with Modbus TCP and state machine{now} > feat: add BHKW controller simulator with Modbus TCP and state machine{end_time}
        ...    Fail    Timeout: Expected feat: add BHKW controller simulator with Modbus TCP and state machine{expected_state} but got feat: add BHKW controller simulator with Modbus TCP and state machine{current}
        Sleep    feat: add BHKW controller simulator with Modbus TCP and state machine{interval}

Check Power Output
    [Documentation]    Verify power output is within expected range
    [Arguments]    feat: add BHKW controller simulator with Modbus TCP and state machine{min_kw}=0    feat: add BHKW controller simulator with Modbus TCP and state machine{max_kw}=100
    feat: add BHKW controller simulator with Modbus TCP and state machine{power}=    Read Power Output
    Should Be True    feat: add BHKW controller simulator with Modbus TCP and state machine{power} >= feat: add BHKW controller simulator with Modbus TCP and state machine{min_kw}
    ...    msg=Power feat: add BHKW controller simulator with Modbus TCP and state machine{power}kW below minimum feat: add BHKW controller simulator with Modbus TCP and state machine{min_kw}kW
    Should Be True    feat: add BHKW controller simulator with Modbus TCP and state machine{power} <= feat: add BHKW controller simulator with Modbus TCP and state machine{max_kw}
    ...    msg=Power feat: add BHKW controller simulator with Modbus TCP and state machine{power}kW above maximum feat: add BHKW controller simulator with Modbus TCP and state machine{max_kw}kW
    Log    Power output OK: feat: add BHKW controller simulator with Modbus TCP and state machine{power}kW

Check Temperature
    [Documentation]    Verify temperature is within safe operating range
    [Arguments]    feat: add BHKW controller simulator with Modbus TCP and state machine{min_temp}=0    feat: add BHKW controller simulator with Modbus TCP and state machine{max_temp}=90
    feat: add BHKW controller simulator with Modbus TCP and state machine{temp}=    Read Temperature
    Should Be True    feat: add BHKW controller simulator with Modbus TCP and state machine{temp} >= feat: add BHKW controller simulator with Modbus TCP and state machine{min_temp}
    ...    msg=Temperature feat: add BHKW controller simulator with Modbus TCP and state machine{temp}C below minimum feat: add BHKW controller simulator with Modbus TCP and state machine{min_temp}C
    Should Be True    feat: add BHKW controller simulator with Modbus TCP and state machine{temp} <= feat: add BHKW controller simulator with Modbus TCP and state machine{max_temp}
    ...    msg=Temperature feat: add BHKW controller simulator with Modbus TCP and state machine{temp}C above maximum feat: add BHKW controller simulator with Modbus TCP and state machine{max_temp}C
    Log    Temperature OK: feat: add BHKW controller simulator with Modbus TCP and state machine{temp}C

Check No Fault
    [Documentation]    Verify no active fault
    feat: add BHKW controller simulator with Modbus TCP and state machine{fault}=    Read Fault Code
    Should Be Equal As Integers    feat: add BHKW controller simulator with Modbus TCP and state machine{fault}    0
    ...    msg=Unexpected fault code: feat: add BHKW controller simulator with Modbus TCP and state machine{fault}
