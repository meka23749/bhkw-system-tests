*** Settings ***
Resource    keywords/bhkw_keywords.robot
Suite Setup       Connect To BHKW
Suite Teardown    Disconnect From BHKW

*** Test Cases ***

TC01 BHKW starts from IDLE state
    [Documentation]    Verify BHKW transitions from IDLE to RUNNING after START command
    [Tags]    start    smoke
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    IDLE    msg=BHKW must be in IDLE before start
    Send Command    START
    Wait For State    RUNNING    timeout=30
    Check Power Output    min_kw=40    max_kw=60
    Check Temperature    min_temp=75    max_temp=90
    Check No Fault
    Log    TC01 PASSED: BHKW started successfully

TC02 BHKW stops from RUNNING state
    [Documentation]    Verify BHKW transitions from RUNNING to IDLE after STOP command
    [Tags]    stop    smoke
    utf8{state}=    Read State
    Should Be Equal    utf8{state}    RUNNING    msg=BHKW must be RUNNING before stop
    Send Command    STOP
    Wait For State    IDLE    timeout=30
    utf8{power}=    Read Power Output
    Should Be Equal As Numbers    utf8{power}    0    msg=Power must be 0 after stop
    Log    TC02 PASSED: BHKW stopped successfully

TC03 Complete start-stop cycle
    [Documentation]    Verify full START -> RUNNING -> STOP -> IDLE cycle
    [Tags]    cycle    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    Check Power Output    min_kw=40
    Check No Fault
    Sleep    3
    Send Command    STOP
    Wait For State    IDLE    timeout=30
    utf8{power}=    Read Power Output
    Should Be Equal As Numbers    utf8{power}    0
    Log    TC03 PASSED: Full cycle completed
