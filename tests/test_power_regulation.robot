*** Settings ***
Resource    keywords/bhkw_keywords.robot
Suite Setup       Connect To BHKW
Suite Teardown    Disconnect From BHKW

*** Test Cases ***

TC07 Power output within nominal range
    [Documentation]    Verify power output stays within 40-60 kW during normal operation
    [Tags]    power    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    FOR    utf8{i}    IN RANGE    5
        Check Power Output    min_kw=40    max_kw=60
        Sleep    1
    END
    Log    TC07 PASSED: Power stable within nominal range

TC08 Power setpoint change
    [Documentation]    Verify BHKW responds to power setpoint change via Modbus
    [Tags]    power    regression
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    RUNNING
    Call Method    utf8{MODBUS_CLIENT}    write_register    2    300    slave=utf8{UNIT_ID}
    Sleep    5
    utf8{power}=    Read Power Output
    Should Be True    utf8{power} >= 25
    ...    msg=Power should respond to new setpoint
    Log    TC08 PASSED: Setpoint change accepted

TC09 Temperature within safe range during operation
    [Documentation]    Verify engine temperature stays within safe limits
    [Tags]    temperature    regression
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    RUNNING
    FOR    utf8{i}    IN RANGE    5
        Check Temperature    min_temp=75    max_temp=92
        Sleep    1
    END
    Log    TC09 PASSED: Temperature within safe range

TC10 Power drops to zero after stop
    [Documentation]    Verify power output is exactly 0 kW after STOP
    [Tags]    power    stop    regression
    Send Command    STOP
    Wait For State    IDLE    timeout=30
    utf8{power}=    Read Power Output
    Should Be Equal As Numbers    utf8{power}    0.0
    ...    msg=Power must be exactly 0 kW after stop
    Log    TC10 PASSED: Power correctly dropped to zero
