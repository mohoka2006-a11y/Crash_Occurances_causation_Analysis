# Crash Occurances & Causation of Traffic Accident

## Project Overview

This project analyzes police-reported motor vehicle collisions in New York City using the NYC Open Data Motor Vehicle Collisions - Crashes dataset.

Each row represents a collision event. The dataset includes information such as crash date and time, borough and street location, geographic coordinates, contributing factors, vehicle types, and the number of people injured or killed.

The project will use SQL and Python to clean, prepare, and analyze the data, then use Power BI and Tableau to create visualizations and interactive dashboards. The goal is to identify patterns in when and where collisions occur, explore reported contributing factors, and understand injury and fatality trends.

The dataset is preliminary and may be updated when crash reports are amended. Findings will be interpreted as patterns in the available police-reported data, not proof that a particular factor caused a collision.

## Dataset
- Name: NYC Motor Vehicle Collisions - Crashes
- Source: NYC Open Data / New York City Police Department (NYPD)
- Dataset link: [Motor Vehicle Collisions - Crashes](https://catalog.data.gov/dataset/motor-vehicle-collisions-crashes)

## Team Members

* Noura Ibrahim Labeb
* Menna Muhammad Ali
* Mariem Reda Ahmed
* Amin Mohamed Amin
* Mohamed Ahmed Abdel Fattah

## Instructor

Amal Mahmoud

## Project Objectives

1. Identify trends in the number of reported collisions over time.
2. Compare collision patterns across NYC boroughs and locations.
3. Explore collision frequency by time of day, day of the week, and month, where the data supports these comparisons.
4. Analyze reported contributing factors and vehicle types associated with collisions.
5. Examine the number of people injured or killed, including pedestrians, cyclists, and motorists where those fields are available.
6. Clean and validate the data, document missing or inconsistent values, and prepare reliable visualizations.
7. Present evidence-based findings that may help inform traffic-safety discussions.

## Project Scope

The project will focus on police-reported motor vehicle collisions in New York City contained in the selected dataset.
The analysis may include:

- Time analysis: collisions by date, month, day of the week, and time of day.
- Location analysis: collisions by borough, ZIP code, street, and available geographic coordinates.
- Safety outcomes: counts of injured and killed people, including pedestrians, cyclists, and motorists where the relevant fields are available.
- Contributing factors: patterns in the factors reported for vehicles involved in collisions.
- Vehicle analysis: comparisons by reported vehicle type where the data is available and sufficiently consistent.
- Data quality: missing values, duplicate collision identifiers, inconsistent category labels, invalid coordinates, and data-type issues.

Data preparation will include checking the unique collision identifier, standardizing dates and times, reviewing missing values, validating numeric fields, and handling inconsistent text categories. Missing values will not automatically be treated as zero; the approach will depend on the meaning of each field.

The project will use SQL and Python for data cleaning and analysis, and Power BI and Tableau for interactive dashboards. The analysis will describe trends and associations in the dataset without claiming that the observed contributing factors necessarily prove causation. Because the dataset contains police-reported collisions, it should not be assumed to represent every traffic incident.

## Tools & Technologies

* Python
* SQL
* Power BI
* Tableau

## Project Plan

| Week   | Activities                                                            |
| ------ | --------------------------------------------------------------------- |
| Week 1 | Data collection, data entry, and data cleaning                        |
| Week 2 | Linking tables and combining data from multiple files                 |
| Week 3 | Data analysis and visualization using Python, Power BI, and Tableau   |
| Week 4 | Reviewing the previous steps and validating the analysis and results  |
| Week 5 | Preparing the final presentation and documenting the project findings |
