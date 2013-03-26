#!/bin/bash

while true; do
    read -p "Enter yes or no?" yn
    case $yn in
        [Yy]* ) echo "Hi akshat"
        exit;;
	[Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
