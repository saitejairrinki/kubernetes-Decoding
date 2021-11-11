#!/bin/bash
apt &>> /dev/null
if [ $? -eq 0 ]
   then

       sudo apt update
       sudo apt upgrade -y
       python3 --version
       sudo apt install mkdocs -y 
       sudo apt install python3-pip -y
       pip3 install mkdocs-material 
       
else 
     echo " ======================================== "     
     echo " This script on works Ubuntu-20 or later "
     echo " ======================================== "     
fi     
