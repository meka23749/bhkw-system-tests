*** Settings ***
Library    BHKWLibrary    host=localhost    port=5020    unit=1
Library    RequestsLibrary
Library    Collections
Suite Setup       Setup Test Environment
Suite Teardown    Disconnect From BHKW

*** Variables ***
${API_URL}    http://localhost:8080

*** Keywords ***

Setup Test Environment
    Connect To BHKW
    Create Session    bhkw    ${API_URL}

*** Test Cases ***

TC11 Health endpoint returns OK
    [Documentation]    Verify REST API health endpoint
    [Tags]    rest    smoke
    ${resp}=    GET On Session    bhkw    /health
    Should Be Equal As Integers    ${resp.status_code}    200
    ${json}=    Set Variable    ${resp.json()}
    ${status}=    Get From Dictionary    ${json}    status
    Should Be Equal    ${status}    ok
    Log    TC11 PASSED: REST API health OK

TC12 Status endpoint returns BHKW state
    [Documentation]    Verify status endpoint reflects simulator state
    [Tags]    rest    smoke
    ${resp}=    GET On Session    bhkw    /api/status
    Should Be Equal As Integers    ${resp.status_code}    200
    ${json}=    Set Variable    ${resp.json()}
    ${state}=    Get From Dictionary    ${json}    state
    Should Be Equal    ${state}    IDLE
    Log    TC12 PASSED: Status endpoint works

TC13 Start BHKW via REST API
    [Documentation]    Verify BHKW can be started via REST POST command
    [Tags]    rest    regression
    ${resp}=    POST On Session    bhkw    /api/command/start
    Should Be Equal As Integers    ${resp.status_code}    200
    ${json}=    Set Variable    ${resp.json()}
    ${success}=    Get From Dictionary    ${json}    success
    Should Be True    ${success}
    Wait For State    RUNNING    timeout=30
    Log    TC13 PASSED: BHKW started via REST

TC14 Status reflects RUNNING state
    [Documentation]    Verify REST status matches Modbus state during RUNNING
    [Tags]    rest    regression
    ${modbus_state}=    Read State
    ${resp}=    GET On Session    bhkw    /api/status
    ${json}=    Set Variable    ${resp.json()}
    ${rest_state}=    Get From Dictionary    ${json}    state
    Should Be Equal    ${modbus_state}    ${rest_state}
    ${power}=    Get From Dictionary    ${json}    power_output
    Should Be True    ${power} >= 40
    Log    TC14 PASSED: REST and Modbus states match

TC15 Power endpoint returns valid value
    [Documentation]    Verify power measurement endpoint
    [Tags]    rest    regression
    ${resp}=    GET On Session    bhkw    /api/power
    Should Be Equal As Integers    ${resp.status_code}    200
    ${json}=    Set Variable    ${resp.json()}
    ${power}=    Get From Dictionary    ${json}    power_output
    Should Be True    ${power} >= 40
    Log    TC15 PASSED: Power endpoint OK

TC16 Stop BHKW via REST API
    [Documentation]    Verify BHKW can be stopped via REST POST command
    [Tags]    rest    regression
    ${resp}=    POST On Session    bhkw    /api/command/stop
    Should Be Equal As Integers    ${resp.status_code}    200
    Wait For State    IDLE    timeout=30
    Log    TC16 PASSED: BHKW stopped via REST

TC17 START rejected when not in IDLE state
    [Documentation]    Verify REST API returns 409 when START is called twice
    [Tags]    rest    negative
    ${resp1}=    POST On Session    bhkw    /api/command/start
    Should Be Equal As Integers    ${resp1.status_code}    200
    Wait For State    RUNNING    timeout=30
    ${resp2}=    POST On Session    bhkw    /api/command/start    expected_status=409
    Should Be Equal As Integers    ${resp2.status_code}    409
    Log    TC17 PASSED: Duplicate START correctly rejected with 409
    POST On Session    bhkw    /api/command/stop    expected_status=any
    Wait For State    IDLE    timeout=30