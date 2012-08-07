/**************************************************************************
Copyright (c) 2011:
Istituto Nazionale di Fisica Nucleare (INFN), Italy
Consorzio COMETA (COMETA), Italy

See http://www.infn.it and and http://www.consorzio-cometa.it for details on
the copyright holders.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

@author <a href="mailto:riccardo.bruno@ct.infn.it">Riccardo Bruno</a>(COMETA)
****************************************************************************/
package it.infn.ct;

import java.io.*;


/**
 * Class that collects portal info for infrastrucutes' jobs
 */
public class PortalInfo {
	int    applicationId   = -1; // GridEngine' GridOperations id
	String portalName      = ""; // Name of the portal who executed the job
	String screenName      = ""; // User who executed the job
        String emailAddress    = ""; // User' email address
	String jobDescription  = ""; // job' user description
	String applicationName = ""; // Name of the application
        String notifyEmail     = ""; // Notification email
        String notifyStart     = ""; // Notification start flag
        String notifyStop      = ""; // Notification stop  flag

	private String LS                   = System.getProperty("line.separator");
        private String TMPDIR               = System.getProperty("java.io.tmpdir");
	private String portalInfoScriptName = null;
	private String portalInfoScriptCode = null;
        private String appServerPath;        
        private String timestamp;
        
        // AppLogger
        private AppLogger _log=null;

	/**
	 * Create the portal data object
	 */
	public PortalInfo(AppLogger _log
                         ,String    timestamp
                         ,String    appServerPath
                         ,String    portalName
			 ,String    screenName
                         ,String    emailAddress
			 ,int       applicationId
			 ,String    applicationName
			 ,String    jobDescription
                         ,String    notifyEmail
                         ,String    notifyStart
                         ,String    notifyStop
                ) {
                this._log            = _log;
                this.timestamp       = timestamp;
                this.appServerPath   = appServerPath;
		this.portalName      = portalName;
		this.screenName      = screenName;
                this.emailAddress    = emailAddress;
		this.applicationName = applicationName;
		this.applicationId   = applicationId;
		this.jobDescription  = jobDescription;
                this.notifyEmail     = notifyEmail;
                this.notifyStart     = notifyStart;
                this.notifyStop      = notifyStop;
                _log.info(
                       LS+"Instanciated PortalInfo:"
                      +LS+"------------------------"
                      +LS+"timestamp      : '"+timestamp      +"'"
                      +LS+"appServerPath  : '"+appServerPath  +"'"                                                
                      +LS+"portalName     : '"+portalName     +"'"
                      +LS+"screenName     : '"+screenName     +"'"
                      +LS+"emailAddress   : '"+emailAddress   +"'"
                      +LS+"applicationName: '"+applicationName+"'"
                      +LS+"applicationId  : '"+applicationId  +"'"
                      +LS+"jobDescription : '"+jobDescription +"'"
                      +LS+"notifyEmail    : '"+notifyEmail    +"'"
                      +LS+"notifyStart    : '"+notifyStart    +"'"  
                      +LS+"notifyStop     : '"+notifyStop     +"'"                        
                      +LS+"------------------------"
                      +LS+"portalInfo.sh"
                      +LS+"------------------------"
                      +LS+mkPortalInfoScriptCode());
	}
        
        /**
         * PortalInfo class stores its information into a temporary file
         * this method removes the file upon the GC frees this object
         *
        protected void finalize() {
            if (portalInfoScriptName != null) {
               try{
                   // !!! Job execution may require a bit of time
                   // to be accomplished; files used
                   // before to remove files used by the jobSubmit()
                   // it is better to wait a bit
                   Thread.currentThread().sleep(30*60*1000);// (30-min)*(60-sec)*(1-sec)
                   // Notify the file cleanup
                   _log.info(
                          LS+"Freeing AppInfo:"
                         +LS+"----------------"
                         +LS+"Removing: "+portalInfoScriptName
                           ); 
                   File f = new File(portalInfoScriptName);
                   if(!f.delete())
                       _log.error("Unable to delete PortalInfo file: "+portalInfoScriptName);
               }
               catch(InterruptedException ie) {
                   // Do nothing
               }                                  
            }                        
        }
        */ 
                
	/**
	 * Creates and return the metadata file content stored in memory
	 */
	public String mkPortalInfoScriptCode() {
		return portalInfoScriptCode=String.format(
			    "#!/bin/sh"
			+LS+"#"
			+LS+"# PortalInfo.sh - Portal Information File"
			+LS+"#"
			+LS+"# This file contains portal info to be shared with the Grid Job executing on the Worker Node"
			+LS+"# Source this file from the pilot script in order to load the values below"
			+LS+""
                        +LS+"export SG_PORTAL_SCREEN_NAME='%s'"
                        +LS+"export SG_PORTAL_USER_EMAIL='%s'"
			+LS+"export SG_PORTAL_NAME='%s'"
			+LS+"export SG_PORTAL_APP_ID=%s"
			+LS+"export SG_PORTAL_APP_NAME='%s'"
			+LS+"export SG_PORTAL_JOB_DESC='%s'"
                        +LS+"export SG_PORTAL_JOB_NOTIFY_EMAIL='%s'"
                        +LS+"export SG_PORTAL_JOB_NOTIFY_START='%s'"
                        +LS+"export SG_PORTAL_JOB_NOTIFY_STOP='%s'"                        
			+LS+""
			,screenName
                        ,emailAddress
			,portalName
			,applicationId
			,applicationName
			,jobDescription
                        ,notifyEmail
                        ,notifyStart
                        ,notifyStop
		)+LS+"#"
                 +LS+"# Content of WEBINF/job/PortalInfo.sh"
                 +LS+"#"
                 +LS+""
                 +LS+printPortalInfoScript();
	}
        
        /**
         * Returns the content of WEBINF/job/PortalInfo.sh script
         * this file contains functions and environment variables
         * that can be used by the job pilot script while executing
         * on the distributed infrastructure
         * The portlet developer can modify this script accordingly
         * to their own needs
         */
        private String printPortalInfoScript() {
            String portalInfoScriptContent="";
            
            try {
                portalInfoScriptContent=file2String(appServerPath+"WEB-INF/job/PortalInfo.sh");
            }
            catch(IOException e) {
                portalInfoScriptContent="##"
                                    +LS+"## (WARNING) - WEB-INF/job/PortalInfo.sh"
                                    +LS+"##             The file is missing or a problem occurred reading its content"
                                    +LS+"";             
            }
            return portalInfoScriptContent;
        }
        
        /**
        * This method takes as input a filename and will transfer its content inside a String variable
        * 
        * @param file A complete path to a given file
        * @return File content into a String
        * @throws IOException 
        */
        private String file2String(String file) throws IOException {
            String line;
            StringBuilder stringBuilder = new StringBuilder();            
            BufferedReader reader = new BufferedReader( new FileReader (file));                
            while((line = reader.readLine()) != null ) {
                stringBuilder.append(line);
                stringBuilder.append(LS);
            }                        
            return stringBuilder.toString();
        } 
        
        /**
        * This method will transfer the content of a given String into a given filename
        * 
        * @param fileName    A complete path to a file to write
        * @param fileContent The string content of the file to write
        * @throws IOException 
        */
        private void String2File(String fileName,String fileContent) throws IOException {                        
            BufferedWriter writer = new BufferedWriter(new FileWriter(fileName));                
            writer.write(fileContent);
            writer.close();
        }
	
	/**
	 * Dump the class values
	 */
	public String dump() {
		return mkPortalInfoScriptCode();
	}
        
        /**
         * Set the timestamp
         */
        public void setTimeStamp(String timestamp) {
            this.timestamp=timestamp;
        }
        
        /**
         * Set the application server path
         */
        public void setAppServerPath(String appServerPath) {
            this.appServerPath=appServerPath;
        }

	/**
	 * Set the portal user name
	 */
	public void setScreenName(String screenName) {
		this.screenName=screenName;
	}
        
       	/**
	 * Set the portal user name
	 */
	public void setEmailAddress(String emailAddress) {
		this.emailAddress=emailAddress;
	}

	/**
	 * Set the portal name
	 */
	public void setPortalName(String portalName) {
		this.portalName=portalName;
	}

	/**
	 * Set the application name
	 */
	public void setApplicationName(String applicationName) {
		this.applicationName=applicationName;
	}

	/**
	 * Set the application id
	 */
	public void setApplicationId(int applicationId) {
		this.applicationId=applicationId;
	}	

	/**
	 * Set the job description field
	 */
	public void setJobDescription(String jobDescription) {
		this.jobDescription=jobDescription;
	}

	/**
	 * Creates a temporary file containing job portal script code
	 */
	public String jobPortalInfo() {
            if(portalInfoScriptName == null) {              
                mkPortalInfoScriptCode();
                String fileName="";
                String tmpDir="";
                try {
                        portalInfoScriptName = TMPDIR         + "/"
                                             + timestamp      + "_"
                                             + screenName     + "_"  
                                             + "PortalInfo.sh";
                        
                        String2File(portalInfoScriptName,portalInfoScriptCode);
                        _log.info(
                                LS+"jobPortalInfo"
                                +LS+"-----------------"
                                +LS+"portalInfoScriptName: '"+portalInfoScriptName+"'"                                  
                                );                            
                } catch (IOException e) {
                        _log.error("Unable to create job' PortalInfo.sh file");
                }
            }
            return portalInfoScriptName;
	}	
} // portalInfo

