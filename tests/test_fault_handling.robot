*** Settings ***
Library    BHKWLibrary    host=localhost    port=5020    unit=1
Suite Setup       Connect To BHKW
Suite Teardown    Disconnect From BHKW

*** Test Cases ***

TC04 Fault detected during RUNNING state
    [Documentation]    Verify BHKW transitions to FAULT state when fault is injected
    [Tags]    fault    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    Check No Fault
    Inject Fault    fault_code=1
    Wait For State    FAULT    timeout=10
    ${fault}=    Read Fault Code
    Should Not Be Equal As Integers    ${fault}    0
    Log    TC04 PASSED: Fault correctly detected

TC05 BHKW recovers from fault via RESET
    [Documentation]    Verify BHKW returns to IDLE after RESET command in FAULT state
    [Tags]    fault    reset    regression
    ${state}=    Read State
    Should Be Equal    ${state}    FAULT
    Send Command    RESET
    Wait For State    IDLE    timeout=10
    ${fault}=    Read Fault Code
    Should Be Equal As Integers    ${fault}    0
    ${power}=    Read Power Output
    Should Be Equal As Numbers    ${power}    0
    Log    TC05 PASSED: BHKW recovered from fault

TC06 START command ignored in FAULT state
    [Documentation]    Verify BHKW ignores START command when in FAULT state
    [Tags]    fault    negative
    Inject Fault    fault_code=2
    Wait For State    FAULT    timeout=10
    Send Command    START
    Sleep    3
    ${state}=    Read State
    Should Be Equal    ${state}    FAULT
    Log    TC06 PASSED: START correctly ignored in FAULT state
    Send Command    RESET
    Wait For State    IDLE    timeout=10