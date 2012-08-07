<%
/**
 * Copyright (c) 2000-2011 Liferay, Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation; either version 2.1 of the License, or (at your option)
 * any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 */
%>

<%@ taglib uri="http://java.sun.com/portlet_2_0" prefix="portlet"       %>
<%@ taglib uri="http://liferay.com/tld/theme"    prefix="liferay-theme" %>

<portlet:defineObjects />
<liferay-theme:defineObjects />
<%//
  // mi-hostname Submission Form
  //
  // The form has 1 input textareas or an upload file button
  // Text area and file upload works in a mutual exclusive fashion
  // The message will be the input for the test job that executes 
  // on the distributed infrastructure
  // 
  // The other inputs are related to:
  //   Job description  - A human readable job description
  //   Start/Stop Flags - If selected a mail will be sent upon job' start/stop 
  //   Email address    - The email address to be used for notification                 
  //
  // The ohter three buttons of the form are used for:
  //    o Demo:          Used to fill with demo values the text areas
  //    o SUBMIT:        Used to execute the job on the eInfrastructure
  //    o Reset values:  Used to reset input fields
  //  
%>

<%
// Below the descriptive area of the mi-hostname web form 
%>
<table>
<tr>
<td valign="top">
<img align="left" style="padding:10px 10px;" src="<%=renderRequest.getContextPath()%>/images/AppLogo.png" />
</td>
<td>
Please fill the following form and then press <b>'SUBMIT'</b> button to launch this application.<br>
Requested inputs are:
<ul>
	<li>An input file (its text or a file to upload)</li>
        <li>Any other input ...</li>
</ul>
Pressing the <b>'Demo'</b> Button input fields will be filled with Demo values.<br>
Pressing the <b>'Reset'</b> Button all input fields will be initialized.<br>
Pressing the <b>'About'</b> Button information about the application will be shown
</td>
<tr>
</table align="center">
<%
// Below the application submission web form 
//
// The <form> tag contains a portlet parameter value called 'PortletStatus' the value of this item
// will be read by the processAction portlet method which then assigns a proper view mode before
// the call to the doView method.
// PortletStatus values can range accordingly to values defined into Enum type: Actions
// The processAction method will assign a view mode accordingly to the values defined into
// the Enum type: Views. This value will be assigned calling the function: setRenderParameter
//
%>
<form enctype="multipart/form-data" action="<portlet:actionURL portletMode="view"><portlet:param name="PortletStatus" value="ACTION_SUBMIT"/></portlet:actionURL>" method="post">
<dl>
        <center>
	<!-- This block contains: label, file input and textarea of the application -->
	<dd>		
 		<p><b>Application' input file</b> <input type="file" name="file_inputFile" id="upload_inputFileId" accept="*.*" onchange="uploadInputFile()"/></p>
		<textarea id="inputFileId" rows="20" cols="100%" name="inputFile">Insert here your text file, or upload a file</textarea>
	</dd>
	<!-- This block contains the experiment name -->
	<dd>
		<p>Insert below your <b>job identifier</b></p>
		<textarea id="jobIdentifierId" rows="1" cols="60%" name="JobIdentifier">multi-infrastructure job description</textarea>
	</dd>	
        </center>
        <!-- This block contains notification flags -->  
        <dd>            
            <p><b>Notification flags</b></br>
               Please check following flags in case you wish to be notified about the application execution.            
            <ul>
                <li><input type="checkbox" id="notifyStart" name="notifyStart" /> I would like to be notified for application execution START        
                <li><input type="checkbox" id="notifyStop"  name="notifyStop"  /> I would like to be notified when the application has COMPLETEd its execution        
                <li><textarea id="notifyEmail" rows="1" cols="40%" name="notifyEmail"><%= user.getEmailAddress() %></textarea>
            </ul>
	</dd>
        <center>
	<!-- This block contains form buttons: Demo, SUBMIT and Reset values -->
  	<dd>
  		<td><input type="button" value="Demo" onClick="addDemo()"></td>
  		<td><input type="button" value="Submit" onClick="preSubmit()"></td> 
  		<td><input type="reset" value="Reset values" onClick="resetForm()"></td>
  	</dd>
        </center>
</dl>
</form>
   <tr>
        <form action="<portlet:actionURL portletMode="HELP"> /></portlet:actionURL>" method="post">
        <td><input type="submit" value="About"></td>
        </form>        
   </tr>
</table>
</center>

<%
// Below the javascript functions used by the web form 
%>
<script language="javascript">
//
// preSubmit
//
function preSubmit() {  
    var inputFileName=document.getElementById('upload_inputFileId');
    var inputFileText=document.getElementById('inputFileId');
    var jobIdentifier=document.getElementById('jobIdentifierId');
    var state_inputFileName=false;
    var state_inputFileText=false;
    var state_jobIdentifier=false;
    
    if(inputFileName.value=="") state_inputFileName=true;
    if(inputFileText.value=="" || inputFileText.value=="Insert here your text file, or upload a file") state_inputFileText=true;
    if(jobIdentifier.value=="") state_jobIdentifier=true;    
       
    var missingFields="";
    if(state_inputFileName && state_inputFileText) missingFields+="  Input file or Text message\n";
    if(state_jobIdentifier) missingFields+="  Job identifier\n";
    if(missingFields == "") {
      document.forms[0].submit();
    }
    else {
      alert("You cannot send an inconsisten job submission!\nMissing fields:\n"+missingFields);
        
    }
}
//
//  uploadMacroFile
//
// This function is responsible to disable the related textarea and 
// inform the user that the selected input file will be used
function uploadInputFile() {
	var inputFileName=document.getElementById('upload_inputFileId');
	var inputFileText=document.getElementById('inputFileId');
	if(inputFileName.value!='') {
		inputFileText.disabled=true;
		inputFileText.value="Using file: '"+inputFileName.value+"'";
	}
}

//
//  resetForm
//
// This function is responsible to enable all textareas
// when the user press the 'reset' form button
function resetForm() {
	var currentTime   = new Date();
	var inputFileName = document.getElementById('upload_inputFileId');
	var inputFileText = document.getElementById('inputFileId'       );
	var jobIdentifier = document.getElementById('jobIdentifierId'   );
        var notifyStart   = document.getElementById('notifyStart'  );
        var notifyStop    = document.getElementById('notifyStop'   );
        var notifyEmail   = document.getElementById('notifyEmail'   );        
        
        // Enable the textareas
	inputFileText.disabled=false;
	inputFileName.disabled=false;
        
        // Reset checkboxes and email address
        notifyStart.checked = "false";
        notifyStop.checked  = "false";
        notifyEmail.value   = "<%= user.getEmailAddress() %>";
            
	// Reset the job identifier
        jobIdentifier.value = "multi-infrastructure job description";
}

//
//  addDemo
//
// This function is responsible to enable all textareas
// when the user press the 'reset' form button
function addDemo() {
	var currentTime = new Date();
	var inputFileName=document.getElementById('upload_inputFileId');
	var inputFileText=document.getElementById('inputFileId');
	var jobIdentifier=document.getElementById('jobIdentifierId');
	
	// Disable all input files
        inputFileText.disabled=false;
	inputFileName.disabled=true;
	
	// Secify that the simulation is a demo
	jobIdentifier.value="multi-infrastructure demo job description";
	
        // Add the demo value for the text file
	inputFileText.value="This is the demo file content ...";
}
</script>
