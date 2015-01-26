/******************************************************************************
*
* CHECK_SPROBE.C
*
* Last Modified: $Date: 2004-July-09 16:27:51 $
*
* Command line: CHECK_SPROBE -H <ip_address> [-C community] -o <oid>
*
* Description:
*
*
* Dependencies:
*
* This plugin used the 'snmpget' command included with the UCD-SNMP
* package.  If you don't have the package installed you will need to
* download it from http://ucd-snmp.ucdavis.edu before you can use
* this plugin.
*
* Return Values: (status to Nagios)
*
* UNKNOWN	= 
* OK		= 
* WARNING	= 
* CRITICAL	= 
*
* Acknowledgements:
*
* The idea for the plugin (as well as some code) were taken from Jim
* Trocki's pinter alert script in his "mon" utility, found at
* http://www.kernel.org/software/mon
*
* Notes:
* 'JetDirect' is copyrighted by Hewlett-Packard.  
*                    HP, please don't sue me... :-)
*
* License Information:
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*
*****************************************************************************/

#include "common.h"
#include "popen.h"
#include "netutils.h"
#include "utils.h"

const char *progname = "check_sprobe";
#define REVISION "$Revision: 1.0.0.0 $"
#define COPYRIGHT "2003-2005"

#define TEMP_OID                 ".1.3.6.1.4.1.3854.1.2.2.1.16.1"
#define HUMID_OID                ".1.3.6.1.4.1.3854.1.2.2.1.17.1"
#define SWITCH_OID               ".1.3.6.1.4.1.3854.1.2.2.1.18.1.3"

#define STATUS               4 
#define VALUE                3 


#define MAX_OID_LENGTH           35
#define MAX_STRING_LENGTH        16

#define DEFAULT_COMMUNITY        "public"

int process_arguments (int, char **);
int validate_arguments (void);
void print_help (void);
void print_usage (void);

char *community = DEFAULT_COMMUNITY;
/*Ake - 08 Jul 04 - add variable oid*/
char *oid = NULL;
char *typeSensor = NULL;
char *portSensor = NULL;
char *address = NULL;
char *udpport = NULL;

int
main (int argc, char **argv)
{
    char command_line[1024];
    int result;
    int line;
    char input_buffer[MAX_INPUT_BUFFER];
    char query_string[512];
    char error_message[MAX_INPUT_BUFFER];
    char *temp_buffer;
    int sensor_status = 0;
    int sensor_value = 0;
    
    oid = malloc(MAX_OID_LENGTH);
    if (oid == NULL){
        printf ("check_sprobe:Could not allocate memory:oid");
        return STATE_UNKNOWN;
    }

    
    if (process_arguments (argc, argv) != OK)
        usage ("Invalid command arguments supplied\n");
    
    /* removed ' 2>1' at end of command 10/27/1999 - EG */
    changeToOID(oid, STATUS, typeSensor, portSensor);
    /* get the command to run */
    //printf ( "%s -m : -v 1 -t 30 -c %s %s %s\n", PATH_TO_SNMPGET, community, address, oid);
    sprintf (command_line, "%s -m : -v 1 -t 30 -c %s %s:%s %s", PATH_TO_SNMPGET, community, address, udpport, oid);
    
    /* run the command */
    child_process = spopen (command_line);
    if (child_process == NULL) {
        printf ("Could not open pipe: %s\n", command_line);
        return STATE_UNKNOWN;
    }
    
    child_stderr = fdopen (child_stderr_array[fileno (child_process)], "r");
    if (child_stderr == NULL) {
        printf ("Could not open stderr for %s\n", command_line);
    }
    
    result = STATE_OK;
    
    fgets (input_buffer, MAX_INPUT_BUFFER - 1, child_process);
    
    /*printf("%s", input_buffer);*/
    temp_buffer = strtok (input_buffer, "=");
    /*printf("%s\n", temp_buffer);*/
    temp_buffer = strtok (NULL, " ");
    /*printf("%s\n", temp_buffer);*/
    temp_buffer = strtok (NULL, " ");
    /*printf("%s\n", temp_buffer);*/
    
    if (temp_buffer != NULL) {
        sensor_status = atoi (temp_buffer);
    //   printf("sensor status is %d\n", sensor_status);
    }
    else {
        result = STATE_UNKNOWN;
        strcpy (error_message, input_buffer);
    }
    
    
    /* WARNING if output found on stderr */
    if (fgets (input_buffer, MAX_INPUT_BUFFER - 1, child_stderr))
        result = max_state (result, STATE_WARNING);
    
    /* close stderr */
    (void) fclose (child_stderr);
    
    /* close the pipe */
    if (spclose (child_process))
        result = max_state (result, STATE_WARNING);
    
    changeToOID(oid, VALUE, typeSensor, portSensor);
    /* get the command to run */
    //printf ( "%s -m : -v 1 -t 30 -c %s %s %s\n", PATH_TO_SNMPGET, community, address, oid);
    //sprintf (command_line, "%s -m : -v 1 -t 30 -c %s %s %s", PATH_TO_SNMPGET, community, address, oid);
    //printf ("%s -m all -v 1 -t 30 -c %s %s:%s %s", PATH_TO_SNMPGET, community, address, udpport, oid);
    sprintf (command_line, "%s -m all -v 1 -t 30 -c %s %s:%s %s", PATH_TO_SNMPGET, community, address, udpport, oid);

    /* run the command */
    child_process = spopen (command_line);
    if (child_process == NULL) {
        printf ("Could not open pipe: %s\n", command_line);
        return STATE_UNKNOWN;
    }
    
    child_stderr = fdopen (child_stderr_array[fileno (child_process)], "r");
    if (child_stderr == NULL) {
        printf ("Could not open stderr for %s\n", command_line);
    }
    
    result = STATE_OK;
    
    fgets (input_buffer, MAX_INPUT_BUFFER - 1, child_process);
    
    /*printf("%s", input_buffer);*/
    temp_buffer = strtok (input_buffer, "=");
    /*printf("%s\n", temp_buffer);*/
    temp_buffer = strtok (NULL, " ");
    /*printf("%s\n", temp_buffer);*/
    temp_buffer = strtok (NULL, " ");
    /*printf("%s\n", temp_buffer);*/
    
    if (temp_buffer != NULL) {
        sensor_value = atoi (temp_buffer);
    //printf("sensor value is %d\n", sensor_value);
    }
    else {
        result = STATE_UNKNOWN;
        strcpy (error_message, input_buffer);
    }
    
    
    /* WARNING if output found on stderr */
    if (fgets (input_buffer, MAX_INPUT_BUFFER - 1, child_stderr))
        result = max_state (result, STATE_WARNING);
    
    /* close stderr */
    (void) fclose (child_stderr);
    
    /* close the pipe */
    if (spclose (child_process))
        result = max_state (result, STATE_WARNING);
    
    /* if there wasn't any output, display an error */
    /*if (line == 0) {*/
    
    /*
    result=STATE_UNKNOWN;
    strcpy(error_message,"Error: Could not read plugin output\n");
    */
    
    /* might not be the problem, but most likely is.. */
    /*result = STATE_UNKNOWN;
    sprintf (error_message, "Timeout: No response from %s\n", address);
    }
    */
    
    /* if we had no read errors, check the printer status results... */
    /*if (result == STATE_OK) {*/
    /*printf("entered OID is %s\n", oid);*/
    
    /* If OID entered is used to retrieve info about sensor status */
    if (!strcmp(typeSensor, "Temperature") || !strcmp(typeSensor, "Humidity") 
        || !strcmp(typeSensor, "Airflow") || !strcmp(typeSensor, "4-20mAmp") 
        || !strcmp(typeSensor, "DC_Voltage")) {
        switch (sensor_status) {
            case 0:
            case 1:
                result = STATE_UNKNOWN;
                sprintf (error_message, "No status");
                break;
            case 2:
                result = STATE_OK;
                sprintf (error_message, "%s is %d, status is now Normal", typeSensor, sensor_value);
                break;
            case 3:
                result = STATE_WARNING;
                sprintf (error_message, "%s is %d, status is now High Warning", typeSensor, sensor_value);
                break;
            case 4:
                result = STATE_CRITICAL;
                sprintf (error_message, "%s is %d, status is now High Critical", typeSensor, sensor_value);
                break;
            case 5:
                result = STATE_WARNING;
                sprintf (error_message, "%s is %d, status is now Low Warning", typeSensor, sensor_value);
                break;
            case 6:
                result = STATE_CRITICAL;
                sprintf (error_message, "%s is %d, status is now Low Critical", typeSensor, sensor_value);
                break;
            case 7:
                result = STATE_CRITICAL;
                sprintf (error_message, "Not Plugged In");
                break;
                /*default:
                result = STATE_UNKNOWN;
                strcpy (error_message, "Unknown problem");
                break;*/
        }
    }
    else if (!strcmp(typeSensor, "Relay") || !strcmp(typeSensor, "Motion")
             || !strcmp(typeSensor, "AC_Voltage") || !strcmp(typeSensor, "Water")
             || !strcmp(typeSensor, "Security") || !strcmp(typeSensor, "Drycontact")) {
        switch (sensor_status) {
            case 0:
            case 1:
                result = STATE_UNKNOWN;
                strcpy (error_message, "No status");
                break;
            case 2:
                result = STATE_OK;
                strcpy (error_message, "Normal");
                break;
            case 4:
                result = STATE_CRITICAL;
                strcpy (error_message, "High critical");
                break;
            case 6:
                result = STATE_CRITICAL;
                strcpy (error_message, "Low critical");
                break;
            case 7:
                result = STATE_CRITICAL;
                strcpy (error_message, "Not Plugged In");
                break;
        /*default:
        result = STATE_UNKNOWN;
        strcpy (error_message, "Unknown problem");
        break;*/
        }
    }
    else { /* If oid entered is not used for retrieve the status of sensors */
        result = STATE_UNKNOWN;
        strcpy (error_message, "OID is unrecognizable");
    }
    /*}*/
    
    /*printf("%s: %s\n", state_text (result), error_message);*/
    printf("%s\n", error_message);
    
    free(oid);
    free(community);
    free(typeSensor);
    free(portSensor);
    free(udpport);
    return result;
}

int changeToOID(char *output, int opSensortmp, char *typeSensortmp, char *portSensortmp)
{
   if (!strcmp(typeSensortmp, "Temperature")) {
      strcpy(output, TEMP_OID);
      if (opSensortmp == STATUS) {
         strcat(output, ".4");
      }
      else if (opSensortmp == VALUE) {
         strcat(output, ".3");
      }
      else {             
         printf("\nOperate command not found\n");
         print_help ();
         strcpy(output, NULL);
         return strlen(output);
      }
   }
   else if (!strcmp(typeSensortmp, "Humidity") || !strcmp(typeSensortmp, "Airflow")
            || !strcmp(typeSensortmp, "4-20mAmp") || !strcmp(typeSensortmp, "DC_Voltage")) { 
      strcpy(output, HUMID_OID);
      if (opSensortmp == STATUS) {
         strcat(output, ".4");
      }
      else if (opSensortmp == VALUE) {
         strcat(output, ".3");
      }
      else {             
         printf("\nOperate command not found\n");
         print_help ();
         strcpy(output, NULL);
         return strlen(output);
      }
   }
   else if (!strcmp(typeSensortmp, "Relay") || !strcmp(typeSensortmp, "Motion")
            || !strcmp(typeSensortmp, "AC_Voltage") || !strcmp(typeSensortmp, "Water")
            || !strcmp(typeSensortmp, "Security") || !strcmp(typeSensortmp, "Drycontact")) {
      strcpy(output, SWITCH_OID);
   }
   else {             
      printf("\nType of sensor not found\n");
      print_help ();
      strcpy(output, NULL);
      return strlen(output);
   }
   
   sprintf(output + strlen(output), ".%d", atoi(portSensortmp)-1);
   return strlen(output);
}

/* process command-line arguments */
int
process_arguments (int argc, char **argv)
{
    int c;
    
#ifdef HAVE_GETOPT_H
    int option_index = 0;
    static struct option long_options[] = {
        {"hostname", required_argument, 0, 'H'},
        {"community", required_argument, 0, 'C'},
        /*Ake - 8 July 04 - add commandline argument OID*/
        {"type", required_argument, 0, 'T'},
        {"port", required_argument, 0, 'p'},
	{"udp", optional_argument, 0, 'P'},
        /*{"critical",       required_argument,0,'c'}, */
        /*{"warning",        required_argument,0,'w'}, */
        {"version", no_argument, 0, 'V'},
        {"help", no_argument, 0, 'h'},
        {0, 0, 0, 0}
    };
#endif

    /* Ake - 8 July 04 - */
    /*if (argc < 2) */
//    if (argc < 3) {
//        print_help(); 
//        return ERROR;
//    }

    udpport = malloc(MAX_STRING_LENGTH);
    if (udpport == NULL) {
        printf ("check_sprobe:Could not allocate memory:udpport");
        return STATE_UNKNOWN;
    }
//    sprintf(udpport, "%d", 161);

    while (1) {
#ifdef HAVE_GETOPT_H
        /*Ake - 08 Jul 04 - add o in the optstring*/
        /*c = getopt_long (argc, argv, "+hVH:C:", long_options, &option_index);*/
        c = getopt_long (argc, argv, "+hVH:C:T:p:P:", long_options, &option_index);

#else
        /* Ake - 08 Jul 04 - add o in the optstring */
        /* c = getopt (argc, argV, "+?hVH:C:"); */
        c = getopt (argc, argv, "+?hVH:C:T:p:P:");
#endif

        if (c == -1 || c == EOF || c == 1)
            break;

        switch (c) {
            case 'H':   /* hostname */
                if (is_host (optarg)) {
                    address = strscpy(address, optarg) ;
                }
                else {
                    usage ("Invalid host name\n");
                }
                break;
            case 'C':   /* community */
		community = malloc(MAX_STRING_LENGTH);
		if (community == NULL) {
		    printf ("check_sprobe:Could not allocate memory:community");
		    return STATE_UNKNOWN;
		}
                community = strscpy (community, optarg);
                break;
                /* Ake - 08 Jul 04 - add switch case for option 'o' */
            case 'T':/* this argument is for OID */
                typeSensor = malloc(MAX_STRING_LENGTH);
                if (typeSensor == NULL){
                    printf ("check_sprobe:Could not allocate memory:typeSensor");
                    return STATE_UNKNOWN;
                }
                typeSensor = strcpy (typeSensor, optarg);
                break;
            case 'p':/* this argument is for OID */
                portSensor = malloc(MAX_OID_LENGTH);
                if (portSensor == NULL){
                    printf ("check_sprobe:Could not allocate memory:portSensor");
                    return STATE_UNKNOWN;
                }
                portSensor = strcpy (portSensor, optarg);
                break;
	    case 'P': /* this is custom UDP port instead of 161 (default) */
		udpport = strcpy (udpport, optarg);
		break;
            case 'V':   /* version */
                print_revision (progname, REVISION);
                exit (STATE_OK);
            case 'h':   /* help */
                print_help ();
                exit (STATE_OK);
            case '?':   /* help */
                //print_help();
                usage ("Invalid argument\n");
        }
    }
    //printf("operate:%s\n", opSensor);
    //printf("OID:%s\n", oid);

    c = optind;
    if (address == NULL) {
        if (is_host (argv[c])) {
            address = argv[c++];
        }
        else {
            usage ("Invalid host name");
        }
    }

    if (argv[c] != NULL ) {
        community = argv[c];
    }
    
    return validate_arguments ();
}

int
validate_arguments (void)
{
    return OK;
}

void
print_help (void)
{
//    print_revision (progname, REVISION);
//    printf
//           ("Copyright (c) 2000 Ethan Galstad/Karl DeBisschop\n\n"
//           "This plugin tests the STATUS of an HP printer with a JetDirect card.\n"
//            "Net-snmp must be installed on the computer running the plugin.\n\n");
    print_usage ();
    printf
           ("\nOptions:\n"
            " -H, --hostname=STRING or IPADDRESS\n"
            "   Check server on the indicated host\n"
            " -C, --community=STRING\n"
            "   The SNMP community name (default=%s)\n"
            " -T, --type=STRING\n"
                    "   Type of sensor ( Temperature,Humidity,Airflow,4-20mAmp\n"
            "                   ,DC_Voltage,Relay,Motion,AC_Voltage\n"
            "                   ,Water,Security,Drycontact ) \n"
            " -p, --port=INTEGER\n"
            "   Port of sensor \n"
	    " -P, --udp=INTEGER\n"
            " -h, --help\n"
            "   Print detailed help screen\n"
            " -V, --version\n" "   Print version information\n\n",DEFAULT_COMMUNITY);
    //support ();
}





void
print_usage (void)
{
    printf
            ("Usage: %s -H host [-C community] -T type -p port -P udp_port\n"
            "       %s --help\n"
            "       %s --version\n", progname, progname, progname);
    printf
            ("\nExample: %s -H 192.168.0.100 -C public -T Temperature -p 1 -P 10161\n", progname);
}


/*
       if(argc<2||argc>3){
       printf("Incorrect number of arguments supplied\n");
       printf("\n");
       print_revision(argv[0],"$Revision: 1.8.2.2 $");
       printf("Copyright (c) 1999 Ethan Galstad (nagios@nagios.org)\n");
       printf("License: GPL\n");
       printf("\n");
       printf("Usage: %s <ip_address> [community]\n",argv[0]);
       printf("\n");
       printf("Note:\n");
       printf(" <ip_address>     = The IP address of the JetDirect card\n");
       printf(" [community]      = An optional community string used for SNMP communication\n");
       printf("                    with the JetDirect card.  The default is 'public'.\n");
       printf("\n");
       return STATE_UNKNOWN;
       }

       /* get the IP address of the JetDirect device */
/*	strcpy(address,argv[1]); */
       
       /* get the community name to use for SNMP communication */
/*	if(argc>=3)
       strcpy(community,argv[2]);
       else
       strcpy(community,"public");
*/
