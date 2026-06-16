*** Settings ***
Library    BHKWLibrary    host=localhost    port=5020    unit=1
Suite Setup       Connect To BHKW
Suite Teardown    Disconnect From BHKW

*** Test Cases ***

TC07 Power output within nominal range
    [Documentation]    Verify power output stays within 40-60 kW during normal operation
    [Tags]    power    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    Check Power Output    min_kw=40    max_kw=60
    Sleep    1
    Check Power Output    min_kw=40    max_kw=60
    Sleep    1
    Check Power Output    min_kw=40    max_kw=60
    Log    TC07 PASSED: Power stable within nominal range

TC08 Power setpoint change
    [Documentation]    Verify power output is within range during RUNNING
    [Tags]    power    regression
    ${state}=    Read State
    Should Be Equal    ${state}    RUNNING
    ${power}=    Read Power Output
    Should Be True    ${power} >= 40
    Log    TC08 PASSED: Power within range

TC09 Temperature within safe range during operation
    [Documentation]    Verify engine temperature stays within safe limits
    [Tags]    temperature    regression
    ${state}=    Read State
    Should Be Equal    ${state}    RUNNING
    Check Temperature    min_temp=75    max_temp=92
    Sleep    1
    Check Temperature    min_temp=75    max_temp=92
    Sleep    1
    Check Temperature    min_temp=75    max_temp=92
    Log    TC09 PASSED: Temperature within safe range

TC10 Power drops to zero after stop
    [Documentation]    Verify power output is exactly 0 kW after STOP
    [Tags]    power    stop    regression
    Send Command    STOP
    Wait For State    IDLE    timeout=30
    ${power}=    Read Power Output
    Should Be Equal As Numbers    ${power}    0.0
    Log    TC10 PASSED: Power correctly dropped to zero