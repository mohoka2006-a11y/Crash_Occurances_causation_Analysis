DEPI  |  DIGITAL EGYPT PIONEERS INITIATIVE                                      DATA ANALYSTS TRACK

DEPI

Crash Occurrences &
Causation of Traffic Accidents

NYC Motor Vehicle Collisions | Data Analytics Case Study

Track: Data Analysts
Instructor: Amal Mahmoud
Noura Ibrahim Labeb • Menna Muhammad Ali • Mariem Reda Ahmed • Amin Mohamed Amin • Mohamed Ahmed Abdel Fattah


NYC Motor Vehicle Collisions • Data Analytics Case Study

DEPI  |  DIGITAL EGYPT PIONEERS INITIATIVE                                      DATA ANALYSTS TRACK

1. Executive Summary

This project analyzes police-reported motor vehicle collisions in New York City using the NYC Open Data Motor Vehicle Collisions – Crashes dataset and related vehicle-level records. The team applied SQL-based data cleaning and ETL, organized the prepared data into a relational analytical model, and used Tableau and Power BI to explore collision frequency, timing, geography, reported contributing factors, vehicle involvement, injuries, and fatalities.

The purpose is to turn complex public-safety records into a structured, validated resource for descriptive analysis and interactive reporting. The analysis identifies patterns and associations; it does not prove legal responsibility or causation.

2. Business Problem & Proposed Solution

Raw collision data is not immediately analysis-ready. It can contain missing or unspecified values, inconsistent categories, date/time and data-type issues, duplicate identifiers, and multiple vehicle rows for a single collision. Poor joins can also multiply event-level injury and fatality totals.

Proposed solution: profile the source; standardize and validate fields; stage the data; run SQL cleaning and ETL; load related fact, dimension, and vehicle-detail tables; validate keys and measures; then connect the curated model to BI dashboards.

3. Objectives & Scope

Objectives: identify collision trends over time; compare boroughs and locations; examine hour/day/month patterns; explore reported contributing factors and vehicle types; analyze injuries and fatalities by available road-user categories; and communicate evidence-based patterns through dashboards.

Scope: police-reported NYC motor vehicle collisions in the selected extract, including event date/time, borough and available location attributes, vehicle involvement, reported factors, and injury/fatality measures. The dataset should not be assumed to represent every traffic incident.

4. Dataset & Source

Dataset: Motor Vehicle Collisions – Crashes. Publisher: NYC Open Data; data provider: New York City Police Department (NYPD). Official source: https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95

Grain: one row in the Crashes table represents one collision event. Vehicle-level records are separate because a collision can involve multiple vehicles. NYC Open Data describes the data as preliminary and subject to change when reports are amended.

Refresh control: record the extraction timestamp, source update date, minimum/maximum crash dates, and row counts for every delivered extract. The newer refresh was described by the team as 2022-to-present; earlier project work used a 1,000,000-crash snapshot. Do not mix these periods or snapshot metrics without reconciliation.

5. Data Profiling & Cleaning

Profiling checks: row counts; distinct collision identifiers; null/blank/placeholder rates; category frequencies; date coverage; data types; numeric ranges; duplicate identifiers; and geographic validity.

Cleaning actions reported by the team: SQL-based cleaning; identifying missing values; standardizing missing/unspecified values into an Unknown category during preparation; and excluding Unknown values from selected analytical outputs. Apply exclusions by field and analytical purpose rather than indiscriminately.

Important treatment: retain source/staging traceability. Unknown borough may be retained as a visible category for completeness, as in earlier dashboard work. Do not silently convert missing injury/fatality values to zero. Preserve original values or an audit trail for transformed fields.

Additional validation: parse dates and times consistently; test midnight/noon; trim and standardize text; cast numeric measures; investigate duplicate collision IDs; validate coordinate ranges; and verify dimension keys.

6. SQL Cleaning & ETL Pipeline

1) Extract: import selected crash and vehicle records into staging while retaining source identifiers and load metadata.

2) Profile: measure counts, uniqueness, null rates, category distributions, date range, types, and invalid values.

3) Clean: normalize text, parse dates/times, cast numeric fields, investigate duplicates, and standardize missing/unspecified values.

4) Transform: derive calendar attributes from validated crash dates; deduplicate location values; map vehicle types and contributing factors; generate stable keys where required.

5) Load: load dimensions before dependent fact/detail tables; enforce primary keys, foreign keys, and the composite vehicle key.

6) Validate: reconcile source-to-target counts, uniqueness, referential integrity, measure totals, date coverage, and sample records.

7) Publish: connect Tableau and Power BI to curated tables or approved extracts; refresh and test the dashboards.

7. Relational Data Model

Five-table design previously established for the project:

crashes — central event-level table; one row per collision; collision_id identifies the event; date_id and location_id link to dimensions; event-level injury/fatality measures are stored at this grain.

dates — date dimension; date_id key; full_date and derived calendar attributes such as year, quarter, month, day, and weekday.

locations — location dimension; location_id key; borough, ZIP code, street descriptors, and available coordinates.

crash_vehicles — vehicle detail/bridge table; one row per vehicle involved in a collision; composite key (collision_id, vehicle_sequence).

contributing_factors — standardized factor reference/dimension used to categorize vehicle-level reported factors.

Relationships: dates 1-to-many crashes; locations 1-to-many crashes; crashes 1-to-many crash_vehicles; contributing_factors 1-to-many crash_vehicles where a factor is recorded and mapped.

Critical grain rule: collision-level injury/fatality measures must not be summed after joining to multiple vehicle rows without deduplication or pre-aggregation. Count distinct collision_id for collision KPIs; count vehicle rows for vehicle-level KPIs.

8. Analytical Questions & Methods

Questions: How do collisions vary by year, month, weekday, and hour? Which boroughs and locations have the highest recorded counts? Which reported factors appear most frequently? Which vehicle categories are most represented? How are injuries and fatalities distributed across boroughs, time, and road-user groups?

Methods: descriptive aggregation, time grouping, borough/location comparison, ranked categorical distributions, and severity breakdowns. Interpret outputs as descriptive patterns and associations, not causal proof.

9. BI Dashboards & Reporting

Tableau and Power BI are the project reporting tools. Dashboard views may include total collisions, persons injured, persons killed, vehicle records, collisions by hour and borough, monthly trends, reported contributing factors, vehicle types, and injury/fatality breakdowns.

Interactive dashboard elements previously worked on include date, borough, vehicle-type, and contributing-factor filters; a Top-N vehicle-type view; and trend, factor, and vehicle visualizations. Confirm the final feature list against the exact workbook submitted.

Use distinct collision counts for event-level KPIs. Ensure filters apply consistently and validate all dashboard totals against independent SQL queries.

10. Validation & Quality Assurance

Check collision_id uniqueness in the event table; vehicle composite-key uniqueness; foreign-key coverage; dimension-key uniqueness; and source-to-target row reconciliation.

Check that event-level measures are not multiplied by vehicle joins; distinguish null, Unknown, and zero; validate date/time edge cases; verify coordinate ranges; and reconcile dashboard KPIs with SQL.

After every refresh, test filters, Top-N logic, date coverage, calculated fields, and all worksheets affected by the data-source change.

11. Historical Project Snapshot — Not Current Refresh Totals

An earlier project snapshot recorded: 1,000,000 crashes; 1,799,870 vehicle records; 442,628 persons injured; 2,035 persons killed; 237,425 Brooklyn records with known borough; and 294,770 records with Unknown borough.

An earlier snapshot also recorded 290,811 vehicle-level records for Driver Inattention/Distraction. This is a vehicle/factor-record count and must not be described as 290,811 unique collisions.

These figures are historical baseline values only. Recalculate every KPI against the current 2022-to-present database before including numbers in the final presentation.

12. Limitations & Responsible Interpretation

Records represent police-reported collisions and may not include every traffic incident. NYC Open Data states that records are preliminary and may be amended.

Missing and Unknown values limit some comparisons. Reported contributing factors are recorded for designated vehicles and do not prove causation or fault.

Collision-level and vehicle-level records have different grains. Location analysis depends on the availability and quality of borough, street, ZIP, and coordinate fields.

Comparisons across periods should account for the exact extract coverage and possible reporting or schema changes.

13. Recommendations & Future Enhancements

Record extraction timestamp, source update date, date coverage, and source/target counts with each refresh. Preserve raw and staging layers and document field-specific exclusion rules.

Maintain a data dictionary and transformation log. Automate ETL validation and load audits. Version the database model, ETL scripts, and Tableau/Power BI workbooks together.

Re-run dashboard reconciliation after refreshes. Consider additional spatial analysis or trend comparisons only where the required fields and data quality support them.

14. Deliverables

Cleaned and standardized crash and vehicle datasets / curated relational tables; SQL cleaning and ETL scripts; relational schema and ERD; data-quality and validation checks; Tableau dashboard; Power BI reporting (as included in the submission); final documentation and presentation.

15. Development Plan

Week 1 — Data collection and profiling: source inventory, schema review, data types, missingness, duplicates, and coverage.

Week 2 — Cleaning and modeling: SQL cleaning/ETL, standardized dimensions, fact/detail tables, keys, and relationships.

Week 3 — Analysis and visualization: SQL analysis and development of Tableau and Power BI views.

Week 4 — Validation and refinement: reconcile KPIs, test joins, filters, date logic, and refresh behavior.

Week 5 — Documentation and presentation: finalize methodology, findings, limitations, and project presentation.

16. Conclusion

The project transforms NYC police-reported collision records into a structured analytical resource through SQL cleaning, ETL, relational modeling, validation, and BI reporting. Its value is in making collision patterns easier to examine across time, geography, vehicle involvement, reported factors, and injury/fatality outcomes. Reliable conclusions depend on correct data grain, transparent missing-value treatment, refresh validation, and careful interpretation.

References

NYC Open Data — Motor Vehicle Collisions – Crashes: https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95

Dataset metadata identifies NYPD as the provider, defines each crash-table row as a collision event, and notes that the data is preliminary and subject to amendment.

Items to Confirm Before Final Submission

Confirm the exact current extract date range, extraction timestamp, and row counts. The team described the refreshed database as 2022-to-present; earlier analysis used a 1,000,000-crash snapshot.

Recalculate historical snapshot KPIs against the latest database. Confirm exact SQL table/field names in the final schema.

Document precisely which fields had Unknown values excluded and whether exclusions were physical deletes or analytical filters. Preserve the final dashboard screenshots and final findings.

NYC Motor Vehicle Collisions • Data Analytics Case Study
