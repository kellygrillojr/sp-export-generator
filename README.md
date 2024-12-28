# Stored Procedure Export Generator

A ColdFusion-based tool for generating stored procedures that export data to CSV files. This tool provides a user-friendly interface for:

1. Selecting database schemas
2. Choosing tables to export
3. Configuring table joins
4. Selecting and ordering columns
5. Specifying export file paths

## Features

- Multiple table selection
- Configurable table joins (INNER, LEFT, RIGHT)
- Drag-and-drop column ordering
- Automatic stored procedure generation
- CSV export using BCP

## Requirements

- ColdFusion server
- SQL Server database
- BCP utility
- Appropriate database permissions

## Setup

1. Configure your `dashboard_portal` datasource in ColdFusion Administrator
2. Place the files in your web directory
3. Ensure the SQL Server service account has write permissions to the export directory

## Usage

1. Select your target schema
2. Choose the tables you want to export
3. Configure any necessary table joins
4. Select and order the columns for export
5. Specify the export file path
6. Generate and copy the stored procedure code