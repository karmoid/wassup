#!/bin/bash
curl --user chauffourm:\$now1 https://brinkslatam.service-now.com/change_request_list.do?sysparm_query=active%3Dtrue%5EstateIN14%2C15%2C13%2C10%5Eu_it_resources_involvedSTARTSWITHBKFR\&CSV > public/changes.wrk
iconv -f ISO-8859-15 -t UTF-8 public/changes.wrk > public/changes.csv
rm public/changes.wrk