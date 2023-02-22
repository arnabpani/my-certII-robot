*** Settings ***
Documentation       Order your robot

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Collections
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           OperatingSystem
Library           RPA.Desktop
Library           RPA.RobotLogListener



*** Variables ***

${url}    https://robotsparebinindustries.com/#/robot-order

${csv_url}    https://robotsparebinindustries.com/orders.csv
${orders_file}    ${CURDIR}${/}orders.csv

${output}    ${CURDIR}${/}output
${pdf_files}    ${CURDIR}${/}pdf_files
${image_files}    ${CURDIR}${/}image_files

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get Developer Details from vault

    Open the robot order website
    
    Empty Directory    ${CURDIR}${/}pdf_files
    Empty Directory    ${CURDIR}${/}image_files

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}    ${screenshot}=    Take a screenshot of the robot
        ${pdf}=    Store the receipt as a PDF file    ${orderid}

        Go to order another robot
    END

*** Keywords ***

Open the robot order website
    Open Available Browser    ${url}    

Get orders
    Download    url=${csv_url}         target_file=${orders_file}    overwrite=True
    ${table}=   Read table from CSV    path=${orders_file}
    [Return]    ${table}

Close the annoying modal
    Wait And Click Button    xpath://html/body/div/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${orders_detail}

    Wait Until Element Is Visible   //*[@id="head"]
    Wait Until Element Is Enabled   //*[@id="head"]
    Select From List By Value    //*[@id="head"]    ${orders_detail}[Head]
    
    Wait Until Element Is Enabled    body
    Select Radio Button    body    ${orders_detail}[Body]
    
    Wait Until Element Is Enabled    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders_detail}[Legs]
    
    Wait Until Element Is Enabled    //*[@id="address"]
    Input Text    //*[@id="address"]    ${orders_detail}[Address]

Preview the robot
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible   //*[@id="robot-preview-image"]
    
Submit the order
    Mute Run On Failure    Page Should Contain Element
    Click Button    //*[@id="order"]
    Page Should Contain Element    //*[@id="receipt"]

Go to order another robot
    Wait Until Element Is Enabled    //*[@id="order-another"]
    Click Button    //*[@id="order-another"]

Take a screenshot of the robot
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    Wait Until Element Is Visible    //*[@id="receipt"]
    
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    
    Sleep    2sec
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${image_files}${/}${orderid}.png  
    
    Log    OrderID:${orderid}
    Log    Path:${image_files}${/}${orderid}.png

    [Return]    ${orderid}    ${image_files}${/}${orderid}.png

Store the receipt as a PDF file
    [Arguments]    ${orderid}
    ${receipt_html}=    Get Element Attribute   //*[@id="receipt"]  outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_files}${/}${orderid}.pdf
    
    #Combining screenshot to pdf
    Open Pdf    ${pdf_files}${/}${orderid}.pdf
    ${file_List}=    Create List    ${image_files}${/}${orderid}.png:x=10,y=10
    Add Files To Pdf    ${file_List}    ${pdf_files}${/}${orderid}.pdf    ${True}
    Close Pdf    ${pdf_files}${/}${orderid}.pdf

Get Developer Details from vault
    ${secret}=    Get Secret    Developer_Details
    Log    ${secret}
