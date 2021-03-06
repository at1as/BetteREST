
/* Common variables */
var clickCount;
document.addEventListener("DOMContentLoaded", function(event) { 
  clickCount = document.getElementById('headerfieldsAll').children.length - 1;
});


/* Construct Simple Request Object */
function assembleRequestPayload() {
  var body      = {};
  body.headers  = {};

  /* URL */
  body.request  = document.getElementById('requestType').value;
  body.url      = document.getElementById('url').value;
  body.quantity = document.getElementById('times').value;

  /* HEADERS */
  for (var j=0; j <= clickCount; j++) {
    if (document.getElementById('key' + j)) {
      if (document.getElementById('key' + j).value != '') {
        body.headers[document.getElementById('key' + j).value] = document.getElementById('value' + j).value;
      }
    }
  }
  /* PAYLOAD */
  body.payload  = document.getElementById('payload').value;

  return body;
}

/* Construct Request object with all parameters*/
function assembleFullPayload() {
  var body      = assembleRequestPayload();

  /* AUTH */
  body.user     = document.getElementById('usr').value;
  body.password = document.getElementById('pwd').value;

  /* VARIABLES */
  var variable_keys = document.getElementsByName('varKey');
  var variable_vals = document.getElementsByName('varValue');
  body.variables = {};

  for (var i=0; i < variable_keys.length; i++) {
    if (variable_keys[i].value !== '' && variable_vals[i].value !== '') {
      body.variables[variable_keys[i].value] = variable_vals[i].value;
    }
  }

  /* SETTINGS */
  body.redirect = document.getElementById('followlocation').checked;
  body.cookies  = document.getElementById('cookies').checked;
  body.verbose  = document.getElementById('verbose').checked;
  body.ssl_ver  = document.getElementById('ssl_verifypeer').checked;
  body.logging  = document.getElementById('logging').checked;
  body.timeout  = document.getElementById('timeoutInterval').value;

  /* FILE UPLOAD */
  if (document.getElementById('filename').style.display != 'none') {
    body.file   = document.getElementById('filename').innerHTML;
  } else {
    body.file   = '';
  }

  /* VISIBILITY */
  body.show_url     = document.getElementById('path').style.display;
  body.show_auth    = document.getElementById('auth').style.display;
  body.show_head    = document.getElementById('headers').style.display;
  body.show_payload = document.getElementById('data').style.display;
  body.show_results = document.getElementById('results').style.display;
  body.data_height  = document.getElementById('payload').offsetHeight;

  return body;
}


/* Prepare and then send the request */
function sendRequest() {
  var url     = '/request';
  var payload = assembleFullPayload();

  /* Replace variable keys with their specified values */
  var variable_keys = Object.keys(payload.variables);
  for (var i=0; i < variable_keys.length; i++){
    var current_key = variable_keys[i];
    var current_value = payload.variables[variable_keys[i]];
    
    payload.url     = payload.url.replace('{{' + current_key + '}}', current_value);
    payload.payload = payload.payload.replace('{{' + current_key + '}}', current_value);

    /* Replace values in header */
    var keys = Object.keys(payload.headers);
    for(var n=0; n < keys.length; n++) {
      payload.headers[keys[n]] = payload.headers[keys[n]].replace('{{' + current_key + '}}', current_value);
    }

    /* Replace keys in header */
    for(var m=0; m < keys.length; m++) {
      if (keys[m].indexOf('{{' + current_key + '}}') != -1){
        payload.headers[keys[m].replace('{{' + current_key + '}}', current_value)] = payload.headers[keys[m]];
        delete payload.headers[keys[m]];
      }
    }
  }

  /* Send Request */
  var data    = JSON.stringify(payload);
  var client  = new XMLHttpRequest();
  client.open('POST', url, false);
  client.setRequestHeader('Content-Type', 'application/json');
  client.send(data);

  if (client.status == 200) {
    var response = JSON.parse(client.responseText);
    console.log(response);
    document.getElementById('requestTime').innerHTML        = response.return_time + ' seconds';
    document.getElementById('returnCode').innerHTML         = response.return_code + ' ' + response.return_msg;
    document.getElementById('resultsBody').innerHTML        = response.return_body;
    document.getElementById('results-req-head').innerHTML   = response.return_headers;
    document.getElementById('results-resp-head').innerHTML  = response.request_options;
  } else {
    console.log("Unknown Error: POST " + url + " failed.");
  }
}


/* Save request in view to a file */
function save() {
  var url             = '/save';
  var payload         = assembleRequestPayload();
  payload.collection  = document.getElementById('collection_name').value || 'Default';
  payload.name        = document.getElementById('test_name').value;
  var data            = JSON.stringify(payload);
  var client          = new XMLHttpRequest();

  client.open('POST', url, false);
  client.setRequestHeader('Content-Type', 'application/json');
  client.send(data);

  if (client.status == 200) {
    modalHideAll();
  } else {
    console.log('Unknown Error: POST ' + url + ' failed.');
  }
}


/* Retrives a list of saved request names per collection */
function savedRequestList() {
  var url     = '/savedrequests';
  var client  = new XMLHttpRequest();

  client.open('GET', url, false);
  client.send();

  /* Clear and then populate modal with response */
  modalToggle('load-modal');
  var data_container        = document.getElementById('reqdata');
  data_container.innerHTML  = '';

  if (client.status == 200) {
    var response  = JSON.parse(client.responseText);
    var keys      = Object.keys(response);

    /* Iterate through collections and saved requests per collection */
    for(var i=0; i < keys.length; i++) {

      var collection        = document.createElement('div');
      collection.className  = 'collection-header';
      collection_name       = '<span id="collection_name>" class="load_collection_name">' + keys[i] + '</span>';
      collection.innerHTML  = collection_name + '<span aria-hidden="true" onclick="deleteCollection(this)" class="rm-collection">&times;</span><span class="sr-only">Close</span>';

      for(var j=0; j < response[keys[i]].length; j++) {
        var req_container   = document.createElement('div');
        var req_list        = document.createElement('div');
        req_container.innerHTML = '<span aria-hidden="true" onclick="deleteRequest(this)" class="rm-collection">&times;</span><span class="sr-only">Close</span>';
        req_list.id         = keys[i] + '-' + response[keys[i]][j];
        req_list.className  = 'collection-data';
        req_list.innerHTML  = response[keys[i]][j];
        req_list.setAttribute('onclick', 'loadRequest(this)');

        req_container.appendChild(req_list);
        collection.appendChild(req_container);
      }
      data_container.appendChild(collection);
    }
  } else {
    data_container.innerHTML('Unknown Error: GET ' + url + ' failed');
  }
}


/* Retrieves all data from one request and loads into current view */
function loadRequest(element){

  var request = element.id.split('-');
  var url     = '/savedrequests/' + request[0] + '/' + request[1];
  var client  = new XMLHttpRequest();

  client.open('GET', url, false);
  client.send();

  if (client.status == 200) {
    modalHideAll();
    clearFile();
    populateView(JSON.parse(client.responseText));
    warn();
  } else {
    console.log('Unknown Error: GET ' + url + ' failed');
  }
}


/* Populate fields with data */
function populateView(fielddata){
  if (fielddata.url) {
    document.getElementById('url').value = fielddata.url;
  }
  if (fielddata.request) {
    document.getElementById('requestType').value = fielddata.request;
  }
  if (fielddata.quantity) {
    document.getElementById('times').value = fielddata.quantity;
  }
  if (fielddata.payload) {
    document.getElementById('payload').value = fielddata.payload;
  }
  if (fielddata.file && fielddata.file != '') {
    document.getElementById('filename').innerHTML       = fielddata.file;
    document.getElementById('filename').style.display   = '';
    document.getElementById('clear-file').style.display = '';
    document.getElementById('payload').style.display    = 'none';
  }
  if (fielddata.user) {
    document.getElementById('usr').value = fielddata.user;
  }
  if (fielddata.password) {
    document.getElementById('pwd').value = fielddata.password;
  }
  if (fielddata.variables){
    var variables = fielddata.variables;
    var variable_keys = Object.keys(fielddata.variables);

    /* Create variables fields until all stored variables have an input field */
    while (document.getElementById('variables_list').children.length < (variable_keys.length * 2)) {
      addVariables();
    }
    for (var i=0; i < variable_keys.length; i++) {
      document.getElementById('varKey' + i).value = variable_keys[i];
      document.getElementById('varValue' + i).value = variables[variable_keys[i]]; 
    }
  }
  if (fielddata.timeout) {
    document.getElementById('timeoutInterval').value = fielddata.timeout;
  }
  if (fielddata.hasOwnProperty('redirect')) {
    document.getElementById('followlocation').checked = fielddata.redirect;
  }
  if (fielddata.hasOwnProperty('cookies')) {
    document.getElementById('cookies').checked = fielddata.cookies;
  }
  if (fielddata.hasOwnProperty('verbose')) {
    document.getElementById('verbose').checked = fielddata.verbose;
  }
  if (fielddata.hasOwnProperty('ssl_ver')) {
    document.getElementById('ssl_verifypeer').checked = fielddata.ssl_ver;
  }
  if (fielddata.hasOwnProperty('logging')) {
    document.getElementById('logging').checked = fielddata.logging;
  }

  if (fielddata.headers) {
    var header_keys   = Object.keys(fielddata['headers']);
    var header_fields = document.getElementById('headerfieldsAll').children.length - 1;
    var extra_headers = header_keys.length - header_fields;
    
    if (extra_headers > 0) {
      for (var m = 0; m < extra_headers - 1; m++) {
        addNewHeader();
      }
    } else if (extra_headers <= 0) {
      for (var m = 0; m < Math.abs(extra_headers) + 1; m++) {
        removeLastHeader();
      }
    }

    indexes = getHeaderIndexes();

    for(var n=0; n<indexes.length; n++) {
       document.getElementById('key' + indexes[n]).value   = header_keys[n];
       document.getElementById('value' + indexes[n]).value = fielddata['headers'][header_keys[n]];
    }
  }

  if (fielddata.show_url == 'none') {
    toggleRequestVisibility();
  }
  if (fielddata.show_auth == 'none') {
    toggleAuthVisibility();
  }
  if (fielddata.show_head == 'none') {
    toggleHeaderVisibility();
  }
  if (fielddata.show_payload == 'none') {
    toggleDataVisibility();
  }
  if (fielddata.show_results == 'none') {
    toggleResultsVisibility();
  }
}


/* delete a collection of requests */
function deleteCollection(button_id){
  var collection_name = button_id.parentNode.firstChild.innerHTML;
  var url     = '/collections/' + collection_name;
  var client  = new XMLHttpRequest();

  client.open('DELETE', url, false);
  client.send();

  if (client.status == 200) {
    modalHideAll();
  } else {
    console.log('Unknown Error: DELETE ' + collection_name + ' failed');
  }
}


/* delete request from collection */
function deleteRequest(button_id){
  var request_name = button_id.parentNode.getElementsByTagName('div')[0].innerHTML;
  var collection_name = button_id.parentNode.parentNode.firstChild.innerHTML;

  var url     = '/collections/' + collection_name + '/' + request_name;
  var client  = new XMLHttpRequest();

  client.onreadystatechange = function() {
    if (client.readyState == 4 && client.status == 200) {
      modalHideAll();
    } else if (client.readyState == 4) {
      console.log('Unknown Error: DELETE ' + collection_name + '/' + request_name + ' failed');
    }
  }

  client.open('DELETE', url, true);
  client.send();
}


/* delete log from list */
function deleteLog(button_id){
  var log_name = button_id.getAttribute('name');

  var url     = '/logs/' + log_name;
  var client  = new XMLHttpRequest();

  client.onreadystatechange = function() {
    if (client.readyState == 4 && client.status == 200) {
      modalHideAll();
      logsList();
    } else if (client.readyState == 4) {
      console.log('Unknown Error: DELETE ' + log_name + ' failed');
    }
  }

  client.open('DELETE', url, true);
  client.send();
}


/* Retrieve a list of all log entries */
function logsList(){
  var url     = '/logs';
  var client  = new XMLHttpRequest();

  client.open('GET', url, false);
  client.send();

  if (client.status == 200) {
    modalToggle('logs-modal');
    var log_list = JSON.parse(client.responseText).logs;

    /* Clear prior log entries from modal */
    var log_container = document.getElementById('logsdata');
    while (log_container.firstChild) {
      log_container.removeChild(log_container.firstChild);
    }

    /* Now populate modal with log entries */
    for (var j=0; j<log_list.length; j++) {
      var log_item        = document.createElement('a');
      var item_txt        = document.createTextNode(log_list[j]);
      var close           = document.createElement('span');
      var entry_container = document.createElement('div');

      log_item.href       = '/logs/' + log_list[j];
      log_item.className  = 'logNodes';
      log_item.appendChild(item_txt);
      close.innerHTML     = 'x';
      close.className     = 'float-red';
      close.setAttribute('onclick', 'deleteLog(this)');
      close.setAttribute('name', log_list[j]);

      entry_container.className = 'logEntry';
      entry_container.appendChild(log_item);
      entry_container.appendChild(close);
      document.getElementById('logsdata').appendChild(entry_container);
    }
  } else {
    console.log('Unknown Error: GET ' + logs + ' failed');
  }
}


/* Toggle Modal display */
function modalToggle(modal_id) {
  document.getElementById('dropdown').style.display = 'none';
  bgrnd = document.getElementById('backdrop');
  modal = document.getElementById(modal_id);
  bgrnd.style.display = (bgrnd.style.display == '') ? 'none' : '';
  modal.style.display = (modal.style.display == '') ? 'none' : '';
}

function modalHideAll() {
  document.getElementById('dropdown').style.display           = '';
  document.getElementById('backdrop').style.display           = 'none';
  document.getElementById('config-modal').style.display       = 'none';
  document.getElementById('save-modal').style.display         = 'none';
  document.getElementById('load-modal').style.display         = 'none';
  document.getElementById('file-upload-modal').style.display  = 'none';
  document.getElementById('import-modal').style.display       = 'none';
  document.getElementById('variables-modal').style.display    = 'none';
  document.getElementById('logs-modal').style.display         = 'none';
  document.getElementById('file-upload-warning').innerHTML    = '';
  document.getElementById('import-warning').innerHTML         = '';
}

/* Change page layout to reflect minimizing/maximising divs */
function toggleRequestVisibility(){
  var path_box   = document.getElementById('path');
  var req_header = document.getElementById('headingReq');

  path_box.style.display = (path_box.style.display != 'none' ? 'none' : '');
  req_header.innerHTML   = (path_box.style.display != 'none' ? '[&ndash;] Request' : '[+] Request');
  req_header.className   = (path_box.style.display != 'none' ? 'shown-box' : 'hidden-box');
}

function toggleAuthVisibility(){
  var auth_box    = document.getElementById('auth');
  var auth_header = document.getElementById('headingAuth');

  auth_box.style.display  = (auth_box.style.display != 'none' ? 'none' : '');
  auth_header.innerHTML   = (auth_box.style.display != 'none' ? '[&ndash;] Authentication' : '[+] Authentication');
  auth_header.className   = (auth_box.style.display != 'none' ? 'shown-box' : 'hidden-box');
}

function toggleHeaderVisibility(){
  var headers_box = document.getElementById('headers');
  var head_header = document.getElementById('headingHead');

  headers_box.style.display = (headers_box.style.display != 'none' ? 'none' : '');
  head_header.innerHTML     = (headers_box.style.display != 'none' ? '[&ndash;] Headers' : '[+] Headers');
  head_header.className     = (headers_box.style.display != 'none' ? 'shown-box' : 'hidden-box');
}

function toggleDataVisibility(){
  var data_box    = document.getElementById('data');
  var data_header = document.getElementById('headingData');

  data_box.style.display  = (data_box.style.display != 'none' ? 'none' : '');
  data_header.innerHTML   = (data_box.style.display != 'none' ? '[&ndash;] Payload' : '[+] Payload');
  data_header.className   = (data_box.style.display != 'none' ? 'shown-box' : 'hidden-box');
}

function toggleResultsVisibility() {
  var results_box     = document.getElementById('results');
  var results_header  = document.getElementById('headingResults');

  results_box.style.display = (results_box.style.display != 'none' ? 'none' : '');
  results_header.innerHTML  = (results_box.style.display != 'none' ? '[&ndash;] Results' : '[+] Results');
  results_header.className  = (results_box.style.display != 'none' ? 'shown-box' : 'hidden-box');
}


/* Header functions */
/* Append header to bottom */
function addNewHeader() {
  clickCount += 1;

  var input_container = document.createElement('div');
  var header_key      = document.createElement('input');
  var header_val      = document.createElement('input');
  var close_btn       = document.createElement('button');

  input_container.type      = 'div';
  input_container.id        = 'headerfields' + clickCount;
  input_container.className = 'headerContainer';

  header_key.type         = 'text';
  header_key.name         = 'key';
  header_key.id           = 'key' + clickCount;
  header_key.className    = 'key form-control head-input';
  header_key.placeholder  = ' Name';
  header_key.autocomplete = 'off';

  /* Not sure why this is necessary. But it is */
  //header_key.style        = 'margin-right:9px';

  header_val.type         = 'text';
  header_val.name         = 'value';
  header_val.id           = 'value' + clickCount;
  header_val.className    = 'value form-control head-input';
  header_val.placeholder  = ' Value';
  header_val.autocomplete = 'off';

  close_btn.type      = 'button';
  close_btn.id        = 'close' + clickCount;
  close_btn.className = 'close';
  close_btn.tabIndex  = '-1';
  close_btn.innerHTML = '<span style="line-height:inherit" aria-hidden="true">&times;</span><span class="sr-only">Close</span>';
  close_btn.setAttribute('onclick', 'removeRow(this)');

  document.getElementById('headerfieldsAll').appendChild(input_container);
  input_container.appendChild(header_key);
  input_container.appendChild(header_val);
  input_container.appendChild(close_btn);
  
}

/* Remove a header row from the bottom */
function removeLastHeader() {
  var rows      = document.getElementById('headerfieldsAll').children.length - 1;
  var last_row  = document.getElementById('headerfieldsAll').children[rows];
  last_row.parentNode.removeChild(last_row);
}

function getHeaderIndexes(){
  var rows    = document.getElementById('headerfieldsAll').children;
  var indexes = [];
  for(var i=0; i < rows.length; i++) {
    if (rows[i].id.match(/\d+/) !== null){
      indexes.push(rows[i].id.match(/\d+/));
    }
  }
  return indexes;
}


/* Clear field functions */
function clearURL(){
  document.getElementById('url').value = '';
  document.getElementById('times').options.selectedIndex        = 0;
  document.getElementById('requestType').options.selectedIndex  = 0;
}

function clearAuthCredentials() {
  document.getElementById('usr').value = '';
  document.getElementById('pwd').value = '';
}

function removeRow(rowNumber) {
  rNum = rowNumber.id.charAt(rowNumber.id.length -1);
  document.getElementById('headerfieldsAll').removeChild(document.getElementById('headerfields' + rNum));
}

function clearFileUpload() {
  var oldInput        = document.getElementById('datafile');
  var newInput        = document.createElement('input');
  newInput.id         = oldInput.id;
  newInput.type       = oldInput.type;
  newInput.name       = oldInput.name;
  newInput.className  = oldInput.className;
  oldInput.parentNode.replaceChild(newInput, oldInput);
}

function clearVariables() {
  // Clear variables from Settings -> Variables
  document.getElementById('varKey0').value   = '';
  document.getElementById('varValue0').value = '';

  var container = document.getElementById('variables_list');
  var children = container.children;

  while (container.children.length > 2){
    container.removeChild(container.lastChild);
  }
}

/*clear all form fields. Delete additional header fields*/
function clearAllFields() {
  document.getElementById('requestType').value    = 'GET';
  document.getElementById('times').value          = '1';
  document.getElementById('url').value            = '';
  document.getElementById('usr').value            = '';
  document.getElementById('pwd').value            = '';
  document.getElementById('payload').value        = '';
  document.getElementById('payload').style.height = '100px';

  if (document.getElementById('resultsBody')) {
    document.getElementById('resultsBody').value         = '';
    document.getElementById('resultsBody').style.height  = '180px';
  }
  if (document.getElementById('results-req-head')) {
    document.getElementById('results-req-head').value         = '';
    document.getElementById('results-req-head').style.height  = '180px';
  }
  if (document.getElementById('results-resp-head')) {
    document.getElementById('results-resp-head').value         = '';
    document.getElementById('results-resp-head').style.height  = '180px';
  }
  while (headerfieldsAll.firstChild) {
    headerfieldsAll.removeChild(headerfieldsAll.firstChild);
  }
  document.getElementById('requestTime').innerHTML  = '';
  document.getElementById('returnCode').innerHTML   = '';
  clearFile();
}


/* Page View functions */
function toggleResponseContent(new_selection){
  /* Clear current filters */
  document.getElementById('response-data-link').style.color   = '';
  document.getElementById('resultsBody').style.display        = 'none';
  document.getElementById('response-header-link').style.color = '';
  document.getElementById('results-req-head').style.display   = 'none';
  document.getElementById('request-header-link').style.color  = '';
  document.getElementById('results-resp-head').style.display  = 'none';

  /* Apply new filter */
  new_selection.style.color = '#337ab7';

  if (new_selection.id == 'response-data-link') {
    document.getElementById('resultsBody').style.display        = '';
  } else if (new_selection.id == 'response-header-link') {
    document.getElementById('results-req-head').style.display   = '';
  } else if (new_selection.id == 'request-header-link') {
    document.getElementById('results-resp-head').style.display  = '';
  }
}


/* Shut down server and then reload page */
function quit(){
  var url = '/quit';
  var client = new XMLHttpRequest();
  client.open('GET', url, false);

  try {
    client.send();
  } catch (e) {
    console.log('Catching expected exception. Reloading page now');
  } finally {
    window.location.reload();
  }
}


/* Warnings */
function warn() {
  // Clear Previous text
  document.getElementById('warning-text').style.display = 'none';
  document.getElementById('warning-text').setAttribute('tooltip', '');
  var current_warning = '';
  var warning_count   = 0;

  // Wrong type of request with body
  var bodyless_requests = ["GET", "DELETE", "HEAD", "PATCH", "OPTIONS"];
  var current_request   = document.getElementById('requestType').value;
  if (bodyless_requests.indexOf(current_request) >= 0) {
    if (document.getElementById('payload').value != '' && document.getElementById('payload').style.display != 'none') {
      warning_count += 1;
      document.getElementById('warning-text').style.display = '';
      document.getElementById('warning-text').setAttribute('tooltip', current_request + ' request should not contain a payload');
      current_warning = document.getElementById('warning-text').getAttribute('tooltip');
    } else if (document.getElementById('filename').style.display != 'none') {
      warning_count += 1;
      document.getElementById('warning-text').style.display = '';
      document.getElementById('warning-text').setAttribute('tooltip', current_request + ' request should not contain a data payload');
      current_warning = document.getElementById('warning-text').getAttribute('tooltip');
    }
  }

  // Empty username OR password
  var username_entered = document.getElementById('usr').value != '';
  var password_entered = document.getElementById('pwd').value != '';
  if ((username_entered && !password_entered) || (!username_entered && password_entered)) {
    warning_count += 1;
    document.getElementById('warning-text').style.display = '';
    document.getElementById('warning-text').setAttribute('tooltip', current_warning + '\nAuthentication must provide username and password');
    current_warning = document.getElementById('warning-text').getAttribute('tooltip');
  }

  // Empty header key OR value
  var indexes = getHeaderIndexes();
  var header_warning = false;
  indexes.forEach(function(index) {
    var key_id = document.getElementById('key' + index);
    var val_id = document.getElementById('value' + index);
    if ((key_id.value == '' || val_id.value == '') && (key_id.value != val_id.value)) {
      header_warning = true;
    }
  });
  if (header_warning) {
    warning_count += 1;
    document.getElementById('warning-text').style.display = '';
    document.getElementById('warning-text').setAttribute('tooltip', current_warning + '\nHeaders must contain a key and value');
    current_warning = document.getElementById('warning-text').getAttribute('tooltip');
  }
  
  document.getElementById('warning-text').innerHTML = '[ ' + warning_count + ' ]';
}


document.addEventListener("DOMContentLoaded", function(event) {
  /* Import from POSTMAN */
  document.getElementById('import_form').onsubmit = function(event) {
    event.preventDefault();

    var data_store  = document.getElementById('importfile');
    var form        = new FormData();
    form.append('file', data_store.files[0]);

    var client = new XMLHttpRequest();

    client.onreadystatechange = function() {
      if (client.readyState == 4 && client.status == 200) {
        modalHideAll();
      } else if (client.readyState == 4 && client.status == 422) {
        document.getElementById('import-warning').innerHTML = 'Error parsing POSTMAN file';
      } else if (client.readyState == 4 && client.status == 415) {
        document.getElementById('import-warning').innerHTML = 'Error uploading POSTMAN file. Ensure file extension is ".json"';
      } else if (client.readyState == 4) {
        document.getElementById('import-warning').innerHTML = 'Unknown Error uploading POSTMAN file';
      }
    }

    client.open('POST', '/import', true);
    client.send(form);
  }


  /* Upload file */
  document.getElementById('upload_form').onsubmit = function(event) {
    event.preventDefault();

    var data_store  = document.getElementById('datafile');
    var form        = new FormData();
    form.append('file', data_store.files[0]);

    var client = new XMLHttpRequest();

    client.onreadystatechange = function() {
      if (client.readyState == 4 && client.status == 200) {
        var filename  = document.getElementById('datafile').files[0].name;

        document.getElementById('payload').style.display    = 'none';
        document.getElementById('filename').style.display   = '';
        document.getElementById('clear-file').style.display = '';
        document.getElementById('filename').innerHTML       = filename;

        modalHideAll();
      } else if (client.readyState == 4 && client.status == 422) {
        document.getElementById('file-upload-warning').innerHTML = 'Error processing file "' + filename + '"';
      } else if (client.readyState == 4) {
        document.getElementById('file-upload-warning').innerHTML = 'Unknown error uploading file "' + filename + '"';
      }
    }

    client.open('POST', '/upload', true);
    client.send(form);
  }
});

function clearFile(){
  document.getElementById('payload').style.display    = '';
  document.getElementById('clear-file').style.display = 'none';
  document.getElementById('filename').innerHTML       = '';
  document.getElementById('filename').style.display   = 'none';
  clearFileUpload();
}

function addVariables(){
  // Add new row of variables in Settings -> Variables
  var container = document.getElementById('variables_list');
  var container_children = container.children.length;
  var next_row = getNextRow(container_children);

  var new_key = document.createElement('input');
  new_key.className = 'form-control var-input';
  new_key.type = 'text';
  new_key.name = 'varKey';
  new_key.id = 'varKey' + next_row;
  new_key.placeholder = 'Key';
  new_key.style.marginRight = '5px';
  
  var new_val = document.createElement('input');
  new_val.className = 'form-control var-input';
  new_val.type = 'text';
  new_val.name = 'varValue';
  new_val.id = 'varValue' + next_row;
  new_val.placeholder = 'Value';  

  container.appendChild(new_key);
  container.appendChild(new_val);
}

function getNextRow(child_element_count){
  // Given number of child elements present, determine next row
  var row = parseInt(child_element_count/2);
  if (child_element_count % 2 === 1) {
    row += 1;
  }
  return row;
}

/* Event listeners */

/* Commit page state on key press, click and changes */
window.onkeyup = function(e) {
  var fielddata = assembleFullPayload();
  localStorage.fielddata = JSON.stringify(fielddata);
  warn();
  
  /* Close modal on 'escape' or 'enter' key */
  var pressed_key = e.keyCode ? e.keyCode : e.which;
  if (pressed_key === 27 || pressed_key === 13) {
    modalHideAll();
  }
}
window.onclick = function() {
  var fielddata = assembleFullPayload();
  localStorage.fielddata = JSON.stringify(fielddata);
  warn();
}
window.onchange = function() {
  var fielddata = assembleFullPayload();
  localStorage.fielddata = JSON.stringify(fielddata);
  warn();
}

/* Reload saved page state on refresh */
window.onload = function() {
  populateView(JSON.parse(localStorage.fielddata));
  warn();
}


/* Block some JS and Form behaviour from occuring */
function returnFalse(event) {
  event.cancelBubble=true;
  if(event.stopPropagation) {
    event.stopPropagation();
  }
  return false;
}

