*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    html_tables.py
Library    RPA.JavaAccessBridge
Library    RPA.PDF
Library    Collections
Library    RPA.FileSystem
Library    RPA.RobotLogListener
Library    OperatingSystem
Library    RPA.Images
Library    RPA.Desktop
Library    RPA.Archive
Library    RPA.Calendar

*** Variables ***
${Receipts}      ${CURDIR}${/}output${/}receipts
${Temp}    ${CURDIR}${/}output${/}temp
${output}    ${CURDIR}${/}output${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website and download the orders
    ${locator}    Set Variable    OK
    Click Button with Element    ${locator}
    ${locator}    Set Variable    Show model info
    Click Button with Element    ${locator}
    ${orders}=    Get orders    orders.csv
    For order loop    ${orders}
    Archive recepits

*** Keywords ***
Open the robot order website and download the orders
    
    Download    https://robotsparebinindustries.com/orders.csv   overwrite=True
    Open Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    ${dir}=    Does directory not exist    ${Receipts}
    IF    ${dir} == False
        Remove directory    ${Receipts}    recursive=${True}
        Remove directory    ${Temp}    recursive=${True}
    END
    
    Create Directory    ${Receipts}    parents=${True}
    Create Directory    ${Temp}    parents=${True}

Get orders
    [Arguments]    ${arg}
    ${orders}=    Read table from CSV   ${arg}
    RETURN    ${orders}

Click Button with element
    [Arguments]    ${arg}
    Click Button    ${arg}

Get HTML table to CSV
    ${html_table}=    Get Element Attribute    css:#model-info    outerHTML
    ${table}=    Read Table From Html    ${html_table}
    RETURN    ${table}

For order loop
    [Arguments]    ${table}
    FOR    ${order}    IN    @{table}
        Select From List By Value    head    ${order}[Head]
        ${str1}=	Catenate	SEPARATOR=-    id-body    ${order}[Body]
        RPA.Browser.Selenium.Click Element   ${str1}
        ${elem}=    Get WebElement    xpath=//*[contains(@id, '170')]
        Input Text    ${elem}    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Click Button with element    order

        ${bool}=    Is Element Visible    id=receipt     missing_ok: bool = False
        IF    ${bool}
            Store recepits    ${order}[Order number]
            Reload Page
            ${locator}    Set Variable    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
            Wait And Click Button    ${locator}
        ELSE
        ${bool}=    Is Element Visible    id=receipt     missing_ok: bool = False
            WHILE    ${bool} == False
                Click Button with element    order
                ${bool}=    Is Element Visible    id=receipt     missing_ok: bool = False
            END
            Store recepits    ${order}[Order number]
            Reload Page
            ${locator}    Set Variable    xpath=//*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
            Wait And Click Button    ${locator}
        END
    END

Store recepits
    [Arguments]    ${index}

    ${text}=    Get Element Attribute    id=receipt    outerHTML
    Html To Pdf    ${text}    ${Temp}/text${index}.pdf
    ${screenshot_file}=    Set Variable    ${Temp}/rPic-${index}.png
    ${element}=    Get WebElement    robot-preview
    Screenshot    ${element}    ${screenshot_file}
    Add Watermark Image To PDF
        ...    image_path=${screenshot_file}
        ...    source_path=${Temp}/text${index}.pdf
        ...    output_path=${Receipts}/receipt${index}.pdf
    Close All Pdfs

Archive recepits
    ${now}=     Time Now      Europe/Helsinki
    Archive Folder With Zip    ${Receipts}    ${output}receipts${now}.zip