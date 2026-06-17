*** Settings ***
Library    BHKWLibrary    host=127.0.0.1    port=63791    unit=1
Library    RequestsLibrary
Library    Collections
Suite Setup       Setup Test Environment
Suite Teardown    Disconnect From BHKW

*** Variables ***
${API_URL}    http://127.0.0.1:63792

*** Keywords ***

Setup Test Environment
    Connect To BHKW
    Create Session    bhkw    ${API_URL}

*** Test Cases ***

TC18 Kubernetes deployment health check via REST
    [Documentation]    Verify BHKW simulator deployed on Kubernetes responds via REST API
    [Tags]    k8s    smoke
    ${resp}=    GET On Session    bhkw    /health
    Should Be Equal As Integers    ${resp.status_code}    200
    Log    TC18 PASSED: Kubernetes-deployed simulator REST API reachable

TC19 Kubernetes deployment Modbus connectivity
    [Documentation]    Verify BHKW simulator deployed on Kubernetes responds via Modbus TCP
    [Tags]    k8s    smoke
    ${state}=    Read State
    Should Not Be Equal    ${state}    ${None}
    Log    TC19 PASSED: Kubernetes-deployed simulator Modbus reachable, state=${state}

TC20 Kubernetes deployment full start-stop cycle
    [Documentation]    Verify full BHKW start-stop cycle works against Kubernetes-deployed pod
    [Tags]    k8s    regression
    Send Command    START
    Wait For State    RUNNING    timeout=30
    ${power}=    Read Power Output
    Should Be True    ${power} >= 40
    Send Command    STOP
    Wait For State    IDLE    timeout=30
    Log    TC20 PASSED: Full cycle works against Kubernetes deployment