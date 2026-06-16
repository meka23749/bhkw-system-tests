*** Settings ***
Resource    keywords/bhkw_keywords.robot
Suite Setup       Connect To BHKW
Suite Teardown    Disconnect From BHKW

*** Test Cases ***

TC04 Fault detected during RUNNING state
    [Documentation]    Verify BHKW transitions to FAULT state when fault is injected
    [Tags]    fault    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    Check No Fault
    Inject Fault Via Modbus    fault_code=1
    Wait For State    FAULT    timeout=10
    utf8{fault}=    Read Fault Code
    Should Not Be Equal As Integers    utf8{fault}    0
    ...    msg=Fault code must be set when in FAULT state
    Log    TC04 PASSED: Fault correctly detected

TC05 BHKW recovers from fault via RESET
    [Documentation]    Verify BHKW returns to IDLE after RESET command in FAULT state
    [Tags]    fault    reset    regression
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    FAULT
    ...    msg=BHKW must be in FAULT state before RESET
    Send Command    RESET
    Wait For State    IDLE    timeout=10
    utf8{fault}=    Read Fault Code
    Should Be Equal As Integers    utf8{fault}    0
    ...    msg=Fault code must be cleared after RESET
    utf8{power}=    Read Power Output
    Should Be Equal As Numbers    utf8{power}    0
    ...    msg=Power must be 0 after RESET
    Log    TC05 PASSED: BHKW recovered from fault

TC06 START command ignored in FAULT state
    [Documentation]    Verify BHKW ignores START command when in FAULT state
    [Tags]    fault    negative
    Inject Fault Via Modbus    fault_code=2
    Wait For State    FAULT    timeout=10
    Send Command    START
    Sleep    3
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    FAULT
    ...    msg=BHKW must stay in FAULT state - START must be ignored
    Log    TC06 PASSED: START correctly ignored in FAULT state
    Send Command    RESET
    Wait For State    IDLE    timeout=10

*** Keywords ***

Inject Fault Via Modbus
    [Documentation]    Inject fault by writing directly to holding register
    [Arguments]    utf8{fault_code}=1
    Call Method    utf8{MODBUS_CLIENT}    write_register    3    utf8{fault_code}    slave=utf8{UNIT_ID}
    Log    Fault injected via Modbus: code=utf8{fault_code}
