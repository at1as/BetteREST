
/*Toggle Modal display on page*/
function modalToggle(modal_id) {
    bgrnd = document.getElementById("dialog-background-blur");
    bgrnd.style.visibility = (bgrnd.style.visibility == "visible") ? "hidden" : "visible";
    el = document.getElementById(modal_id);
    el.style.visibility = (el.style.visibility == "visible") ? "hidden" : "visible";
}

function modalHideAll() {
    document.getElementById("dialog-background-blur").style.visibility = "hidden";
    document.getElementById("load-dialog-modal").style.visibility = "hidden";
    document.getElementById("file-upload-modal").style.visibility = "hidden";
}

/*Re-serve minimised sections minimised on page reload. Note data from fields is always submitted*/
if (document.getElementById("serveURLDiv").value == "hidden") {
    toggleRequestVisibility("arg1");
}
if (document.getElementById("serveAuthDiv").value == "hidden") {
    toggleAuthVisibility("arg1");
}
if (document.getElementById("serveHeaderDiv").value == "hidden") {
    toggleHeaderVisibility("arg1");
}
if (document.getElementById("servePayloadDiv").value == "hidden") {
    toggleDataVisibility("arg1");
}
if (document.getElementById("serveResultsDiv") && document.getElementById("serveResultsDiv").value == "hidden") {
    toggleResultsVisibility("arg1");
}

/*Change page layout to reflect minimizing/maximising divs*/
function toggleRequestVisibility(){
    document.getElementById("path").style.display = (document.getElementById("path").style.display != 'none' ? 'none' : '');
    document.getElementById("headingReq").innerHTML = (document.getElementById("path").style.display != 'none' ? "[&ndash;] Request" : "[+] Request");
    document.getElementById("headingReq").style.color = (document.getElementById("path").style.display != 'none' ? "red" : "#BBBBBB");
    document.getElementById("headingReq").style.margin = (document.getElementById("path").style.display != 'none' ? "0px 0px 0px" : "0px 0px -20px");
    //So we can block this from being executed on page reload, which would undo the minimise
    if (arguments.length == 0) {
        document.getElementById("serveURLDiv").value = (document.getElementById("serveURLDiv").value != 'hidden' ? 'hidden' : 'displayed');
    }
}

function toggleAuthVisibility(){
    document.getElementById("auth").style.display = (document.getElementById("auth").style.display != 'none' ? 'none' : '');
    document.getElementById("headingAuth").innerHTML = (document.getElementById("auth").style.display != 'none' ? "[&ndash;] Authentication" : "[+] Authentication");
    document.getElementById("headingAuth").style.color = (document.getElementById("auth").style.display != 'none' ? "red" : "#BBBBBB");
    document.getElementById("headingAuth").style.margin = (document.getElementById("auth").style.display != 'none' ? "0px 0px 0px" : "0px 0px -20px");
     if (arguments.length == 0 ) {
        document.getElementById("serveAuthDiv").value = (document.getElementById("serveAuthDiv").value != 'hidden' ? 'hidden' : 'displayed');
    }
}

function toggleHeaderVisibility(){
    document.getElementById("headers").style.display = (document.getElementById("headers").style.display != 'none' ? 'none' : '');
    document.getElementById("headingHead").innerHTML = (document.getElementById("headers").style.display != 'none' ? "[&ndash;] Headers" : "[+] Headers");
    document.getElementById("headingHead").style.color = (document.getElementById("headers").style.display != 'none' ? "red" : "#BBBBBB");
    document.getElementById("headingHead").style.margin = (document.getElementById("headers").style.display != 'none' ? "0px 0px 0px" : "0px 0px -20px");
    if (arguments.length == 0 ) {
        document.getElementById("serveHeaderDiv").value = (document.getElementById("serveHeaderDiv").value != 'hidden' ? 'hidden' : 'displayed');
    }
}

function toggleDataVisibility(){
    document.getElementById("data").style.display = (document.getElementById("data").style.display != 'none' ? 'none' : '');
    document.getElementById("headingData").innerHTML = (document.getElementById("data").style.display != 'none' ? "[&ndash;] Payload" : "[+] Payload");
    document.getElementById("headingData").style.color = (document.getElementById("data").style.display != 'none' ? "red" : "#BBBBBB");
    document.getElementById("headingData").style.margin = (document.getElementById("data").style.display != 'none' ? "0px 0px 0px" : "0px 0px -20px");
    if (arguments.length == 0) {
        document.getElementById("servePayloadDiv").value = (document.getElementById("servePayloadDiv").value != 'hidden' ? 'hidden' : 'displayed');
    }
}

function toggleResultsVisibility() {
    document.getElementById("results").style.display = (document.getElementById("results").style.display != 'none' ? 'none' : '');
    document.getElementById("headingResults").innerHTML = (document.getElementById("results").style.display != 'none' ? "[&ndash;] Results" : "[+] Results");
    document.getElementById("headingResults").style.color = (document.getElementById("results").style.display != 'none' ? "red" : "#BBBBBB");
    document.getElementById("headingResults").style.margin = (document.getElementById("results").style.display != 'none' ? "10px 0px 0px" : "10px 0px -20px");
    if (arguments.length == 0) {
        document.getElementById("serveResultsDiv").value = (document.getElementById("serveResultsDiv").value != 'hidden' ? 'hidden' : 'displayed');
    }
}

/*clear all form fields. Delete additional header fields*/
function clearAllFields() {
    document.getElementById("requestType").value = "GET";
    document.getElementById("url").value = "";
    document.getElementById("usr").value = "";
    document.getElementById("pwd").value = "";
    document.getElementById("payload").value = "";
    if (document.getElementById("resultsBox")){
        document.getElementById("resultsBox").value = "";
    }
    if (document.getElementById("resultsBoxHead")) {
        document.getElementById("resultsBoxHead").value = "";
    }
    if (document.getElementById("resultsBoxcURL")) {
        document.getElementById("resultsBoxcURL").value = "";
    }
    while (headerfieldsAll.firstChild) {
        headerfieldsAll.removeChild(headerfieldsAll.firstChild);
    }
}

var clickCount = document.getElementById('headerfieldsAll').children.length - 1;
document.getElementById("headerCount").value = clickCount + 1;

function addNewHeader() {
    clickCount += 1;
    document.getElementById("headerCount").value = clickCount + 1;

    var input0 = document.createElement('div');
    var input = document.createElement('input');
    var input2 = document.createElement('input');
    var input3 = document.createElement('div');
    input0.type = "div";
    input0.style = "margin-bottom:2px;"
    input.type = "text";
    input2.type = "text";
    input3.type = "close";
    input3.className = "close";
    input.placeholder = " Name";
    input2.placeholder = " Value";
    input.id = "key" + clickCount;
    input.className = "key";
    input2.className = "value";
    input.autocomplete = "off";
    input3.id = "close" + clickCount;
    input.style.margin = "0px 4px 0px 0px";
    input3.style.margin = "0px 0px 0px 9px";
    input2.id = "value" + clickCount;
    input0.id = "headerfields" + clickCount;
    input.name = "key" + clickCount;
    input2.name = "value" + clickCount;
    input.value = '<%=h(params[:key])%>';
    input.value = input.value.replace('key', 'key' + clickCount);

    input2.value = '<%=h(params[:value])%>';
    input2.value = input2.value.replace('value', 'value' + clickCount);
    input3.innerHTML = "X";
    input3.setAttribute("onclick", "removeRow(this)");

    document.getElementById('headerfieldsAll').appendChild(input0);
    input0.appendChild(input);
    input0.appendChild(input2);
    input0.appendChild(input3);
    document.getElementById(input.id).focus()
}

function clearAuthCredentials() {
    document.getElementById('usr').value = '';
    document.getElementById('pwd').value = '';
}

function clearURL(){
    document.getElementById('url').value = '';
    document.getElementById('times').options.selectedIndex = 1;
    document.getElementById('requestType').options.selectedIndex = 1;
}

function removeRow(rowNumber) {
    rNum = rowNumber.id.charAt(rowNumber.id.length -1);
    document.getElementById('headerfieldsAll').removeChild(document.getElementById('headerfields' + rNum));
}

function hideReq() {
    document.getElementById("resultsBox").style.display = '';
    document.getElementById("responseDataText").style.color = "#000000";
    document.getElementById("resultsBoxHead").style.display = 'none';
    document.getElementById("responseHeaderText").style.color = "#FFFFFF";
    document.getElementById("resultsBoxcURL").style.display = 'none';
    document.getElementById("requestHeaderText").style.color = "#FFFFFF";
}

function hideRespData() {
    document.getElementById("resultsBox").style.display = 'none';
    document.getElementById("responseDataText").style.color = "#FFFFFF";
    document.getElementById("resultsBoxHead").style.display = '';
    document.getElementById("responseHeaderText").style.color = "#000000";
    document.getElementById("resultsBoxcURL").style.display = 'none';
    document.getElementById("requestHeaderText").style.color = "#FFFFFF";
}

function hideResp() {
    document.getElementById("resultsBox").style.display = 'none';
    document.getElementById("responseDataText").style.color = "#FFFFFF";
    document.getElementById("resultsBoxHead").style.display = 'none';
    document.getElementById("responseHeaderText").style.color = "#FFFFFF";
    document.getElementById("resultsBoxcURL").style.display = '';
    document.getElementById("requestHeaderText").style.color = "#000000";
}

/*Block some JS and Form behaviour from occuring*/
function returnFalse(event) {
    event.cancelBubble=true;
    if(event.stopPropagation) { event.stopPropagation(); }
    return false;
}
