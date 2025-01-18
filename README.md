# FM 2024 Facepack XML Updater

## Overview
This script automatically adds player IDs to the `config.xml` file in Football Manager 2024. It scans a specified directory for player face images and updates the XML configuration file to include any missing player IDs.

## Features
- Automatically scans a directory for `.png` files representing player faces.
- Updates the `config.xml` file to include any missing player IDs.
- Ensures the XML file is properly formatted and sorted.
- User-friendly GUI for selecting the directory and config file.

## Requirements
- Perl
- Win32::GUI
- XML::LibXML

## Installation
1. Install Perl from [Strawberry Perl](http://strawberryperl.com/).
2. Install the required Perl modules:
   ```sh
   cpan install Win32::GUI XML::LibXML
