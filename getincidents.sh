#!/bin/bash
curl --user chauffourm:\$now1 https://brinkslatam.service-now.com/incident_list.do?sysparm_query=stateIN-5%2C2%2C1%2C8%5Eassignment_groupSTARTSWITHBKFR%5EimpactIN1%2C2%5Esys_created_on%3E%3Djavascript%3Ags.daysAgoStart\(1\)%5EcategoryINfr_access%2Cfr_office_software%2Cfr_business_application%2Cfr_hardware%2Cfr_messaging%2Cfr_mobility%2Cfr_network%2Cfr_security%2Cfr_system\&CSV > public/incidents.csv

