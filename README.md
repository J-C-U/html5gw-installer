# HTML5 Gateway POC Installer

**WARNING : USE FOR PROOF OF CONCEPT ONLY. THIS INSTALLER USES SELF SIGNED CERTIFICATES AND NO HARDENING AND SHOULD NOT BE USED IN PRODUCTION ENVIRONMENT**

### Usage : 
1. Download HTML5 Gateway binary from Cyberark (inside Privilege Session Manager package)
2. Copy the file in the bin folder
3. Run install_poc.sh
4. The installation wizard will ask you : 
	- The FQDN of the Gateway. Place here the same name that will be used in the DNS entry of the server, and in PVWA HTML5GW configuration
	- The password for the Tomcat self signed certificate. 
5. **IMPORTANT** :  After installing HTML5 Gateway (with self signed certificates), you need to trust it on end-user computers. You can either connect to https://<span></span>FQDN_of_gateway and accept the certificate, or copy /opt/tomcat/cert.crt and install on user computers
