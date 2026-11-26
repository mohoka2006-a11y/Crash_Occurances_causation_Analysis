
/*
===============================================================================
NYC MOTOR VEHICLE COLLISIONS — SQL SERVER CLEANING, EDA & ETL
Platform: Microsoft SQL Server 2025 Express (T-SQL)
Database: Crash_Analysis
Raw source: dbo.nyc_crashes_1m
Expected raw rows: 1,000,000
Source columns: 29

IMPORTANT:
1. This is a T-SQL rewrite. It is NOT PostgreSQL/Supabase SQL.
2. The raw table dbo.nyc_crashes_1m is never modified or deleted.
3. Run Sections 1–14 individually or together for profiling and EDA.
4. Run Section 15 as one complete batch/script for the ETL.
5. Target tables are created if they do not already exist:
   dbo.dates, dbo.locations, dbo.contributing_factors,
   dbo.crashes, dbo.crash_vehicles.
6. The source collision IDs are 32 hexadecimal characters in the CSV.
   They are normalized to SQL Server UNIQUEIDENTIFIER (GUID), not BIGINT.
7. Rows with an invalid/missing collision ID or invalid/missing crash date
   are excluded from the modeled crashes table, but remain untouched in raw.
8. Duplicate collision IDs are profiled in Section 2. ETL keeps one row per
   collision ID (the earliest date/time row) to protect the primary key.
9. Placeholder contributing factors are excluded from the factor dimension,
   but the raw values remain unchanged. Vehicle rows may have NULL factor_id.
10. Review the actual row counts after ETL. Do not assume all 1M raw rows
    will become crash rows until the quality checks are reviewed.

If any target tables already exist with a different structure, stop and inspect
them before running Section 15. This script does not silently redesign existing
tables.
===============================================================================
*/

USE Crash_Analysis;
GO

SET NOCOUNT ON;
GO

/*=============================================================================
  SECTION 1 — RAW SOURCE ROW COUNT
=============================================================================*/

SELECT COUNT_BIG(*) AS total_raw_records
FROM dbo.nyc_crashes_1m;
GO

/*=============================================================================
  SECTION 2 — COLLISION ID UNIQUENESS
=============================================================================*/

SELECT
    COUNT_BIG(*) AS total_rows,
    COUNT(DISTINCT NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), COLLISION_ID))), ''))
        AS unique_nonblank_collision_ids,
    COUNT_BIG(*) -
    COUNT(DISTINCT NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), COLLISION_ID))), ''))
        AS duplicate_id_excess
FROM dbo.nyc_crashes_1m;
GO

/*=============================================================================
  SECTION 3 — MISSING VALUE PROFILE
=============================================================================*/

SELECT
    COUNT_BIG(*) AS total_records,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), COLLISION_ID))), '') IS NULL THEN 1 ELSE 0 END) AS missing_collision_ids,
    SUM(CASE WHEN CRASH_DATE IS NULL THEN 1 ELSE 0 END) AS missing_crash_dates,
    SUM(CASE WHEN CRASH_TIME IS NULL THEN 1 ELSE 0 END) AS missing_crash_times,
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(varchar(100), BOROUGH))), '') IS NULL THEN 1 ELSE 0 END) AS missing_boroughs,
    SUM(CASE WHEN ZIP_CODE IS NULL THEN 1 ELSE 0 END) AS missing_zip_codes,
    SUM(CASE WHEN LATITUDE IS NULL OR LONGITUDE IS NULL THEN 1 ELSE 0 END) AS missing_coordinate_pairs
FROM dbo.nyc_crashes_1m;
GO

/*=============================================================================
  SECTION 4 — INVALID COLLISION ID CHECK
=============================================================================*/

SELECT COUNT_BIG(*) AS invalid_collision_ids
FROM dbo.nyc_crashes_1m AS r
CROSS APPLY
(
    SELECT REPLACE(LTRIM(RTRIM(CONVERT(varchar(50), r.COLLISION_ID))), '-', '') AS id_hex
) AS x
CROSS APPLY
(
    SELECT CASE
        WHEN LEN(x.id_hex) = 32 THEN
            STUFF(STUFF(STUFF(STUFF(x.id_hex, 9, 0, '-'), 14, 0, '-'), 19, 0, '-'), 24, 0, '-')
        ELSE NULL
    END AS guid_text
) AS g
WHERE NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), r.COLLISION_ID))), '') IS NOT NULL
  AND TRY_CONVERT(uniqueidentifier, g.guid_text) IS NULL;
GO

/*=============================================================================
  SECTION 5 — IMPORTED COLUMN DATA TYPES
=============================================================================*/

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'nyc_crashes_1m'
ORDER BY ORDINAL_POSITION;
GO

/*=============================================================================
  SECTION 6 — DATE AND TIME CONVERSION PREVIEW

  Purpose:
  Display crash dates and times in readable formats.
  Time format: hh:mm AM/PM.
  Uses DATEPART instead of FORMAT to avoid TIME formatting issues.
=============================================================================*/

SELECT TOP (10)
    TRY_CONVERT(date, CRASH_DATE, 101) AS crash_date,

    CASE
        WHEN CRASH_TIME IS NULL THEN 'Missing'
        ELSE
            CONCAT(
                CASE
                    WHEN DATEPART(HOUR, CRASH_TIME) % 12 = 0 THEN 12
                    ELSE DATEPART(HOUR, CRASH_TIME) % 12
                END,
                ':',
                RIGHT(
                    '0' + CONVERT(varchar(2), DATEPART(MINUTE, CRASH_TIME)),
                    2
                ),
                ' ',
                CASE
                    WHEN DATEPART(HOUR, CRASH_TIME) < 12 THEN 'AM'
                    ELSE 'PM'
                END
            )
    END AS crash_time

FROM dbo.nyc_crashes_1m
ORDER BY CRASH_DATE;
GO

/*=============================================================================
  SECTION 7 — DATE RANGE AND INVALID DATE CHECK
=============================================================================*/

SELECT
    MIN(TRY_CONVERT(date, CRASH_DATE, 101)) AS earliest_crash_date,
    MAX(TRY_CONVERT(date, CRASH_DATE, 101)) AS latest_crash_date,
    SUM(CASE WHEN CRASH_DATE IS NOT NULL
                  AND TRY_CONVERT(date, CRASH_DATE, 101) IS NULL
             THEN 1 ELSE 0 END) AS invalid_dates
FROM dbo.nyc_crashes_1m;
GO

/*=============================================================================
  SECTION 8 — CONTRIBUTING FACTOR FREQUENCY
  Count meaningful factor labels across all five factor columns.
  Placeholder labels are excluded from analysis, not deleted from raw data.
=============================================================================*/

WITH factor_values AS
(
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(255), [CONTRIBUTING_FACTOR_VEHICLE_1]))) AS factor_name FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(255), [CONTRIBUTING_FACTOR_VEHICLE_2]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(255), [CONTRIBUTING_FACTOR_VEHICLE_3]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(255), [CONTRIBUTING_FACTOR_VEHICLE_4]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(255), [CONTRIBUTING_FACTOR_VEHICLE_5]))) FROM dbo.nyc_crashes_1m
)
SELECT TOP (15)
    factor_name,
    COUNT_BIG(*) AS occurrences
FROM factor_values
WHERE NULLIF(factor_name, N'') IS NOT NULL
  AND UPPER(factor_name) NOT LIKE N'%DOES NOT APPLY%'
  AND UPPER(factor_name) NOT LIKE N'%UNKNOWN%'
  AND UPPER(factor_name) NOT LIKE N'%UNSPECIFIED%'
  AND UPPER(factor_name) NOT LIKE N'%NOT REPORTED%'
  AND UPPER(factor_name) NOT LIKE N'%NOT KNOWN%'
  AND UPPER(factor_name) NOT LIKE N'%NOT APPLICABLE%'
  AND UPPER(factor_name) NOT LIKE N'%N/A%'
GROUP BY factor_name
ORDER BY occurrences DESC;
GO

/*=============================================================================
  SECTION 9 — CRASHES BY BOROUGH
=============================================================================*/

SELECT
    UPPER(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH)))) AS borough,
    COUNT_BIG(*) AS crash_records
FROM dbo.nyc_crashes_1m
WHERE NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH))), N'') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH))))
ORDER BY crash_records DESC;
GO

/*=============================================================================
  SECTION 10 — CRASHES BY HOUR

  Display: 12 AM, 1 AM, 2 AM ... 11 PM.
  Output: ONLY crash_hour and crash_records.
  Sorted by highest crash count.
=============================================================================*/

WITH hourly_crashes AS
(
    SELECT
        DATEPART(HOUR, CRASH_TIME) AS original_hour
    FROM dbo.nyc_crashes_1m
    WHERE CRASH_TIME IS NOT NULL
)
SELECT
    CONCAT(
        CASE
            WHEN original_hour % 12 = 0 THEN 12
            ELSE original_hour % 12
        END,
        ' ',
        CASE
            WHEN original_hour < 12 THEN 'AM'
            ELSE 'PM'
        END
    ) AS crash_hour,

    COUNT_BIG(*) AS crash_records

FROM hourly_crashes
GROUP BY original_hour
ORDER BY crash_records DESC;
GO

/*=============================================================================
  SECTION 11 — CRASHES BY WEEKDAY

  SET DATEFIRST 1 makes Monday = 1 and Sunday = 7 for this session.
=============================================================================*/

SET DATEFIRST 1;

SELECT
    DATEPART(WEEKDAY, TRY_CONVERT(date, CRASH_DATE, 101)) AS weekday_number,
    DATENAME(WEEKDAY, TRY_CONVERT(date, CRASH_DATE, 101)) AS weekday_name,
    COUNT_BIG(*) AS crash_records
FROM dbo.nyc_crashes_1m
WHERE TRY_CONVERT(date, CRASH_DATE, 101) IS NOT NULL
GROUP BY
    DATEPART(WEEKDAY, TRY_CONVERT(date, CRASH_DATE, 101)),
    DATENAME(WEEKDAY, TRY_CONVERT(date, CRASH_DATE, 101))
ORDER BY weekday_number;
GO

/*=============================================================================
  SECTION 12 — INJURIES AND FATALITIES BY BOROUGH
=============================================================================*/

SELECT
    UPPER(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH)))) AS borough,
    COUNT_BIG(*) AS crash_records,
    SUM(COALESCE(TRY_CONVERT(bigint, NUMBER_OF_PERSONS_INJURED), 0)) AS persons_injured,
    SUM(COALESCE(TRY_CONVERT(bigint, NUMBER_OF_PERSONS_KILLED), 0)) AS persons_killed
FROM dbo.nyc_crashes_1m
WHERE NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH))), N'') IS NOT NULL
GROUP BY UPPER(LTRIM(RTRIM(CONVERT(nvarchar(100), BOROUGH))))
ORDER BY persons_injured DESC;
GO

/*=============================================================================
  SECTION 13 — VEHICLE TYPE FREQUENCY ACROSS FIVE VEHICLE SLOTS
=============================================================================*/

WITH vehicle_values AS
(
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(150), [VEHICLE_TYPE_CODE_1]))) AS vehicle_type FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(150), [VEHICLE_TYPE_CODE_2]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(150), [VEHICLE_TYPE_CODE_3]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(150), [VEHICLE_TYPE_CODE_4]))) FROM dbo.nyc_crashes_1m
    UNION ALL
    SELECT LTRIM(RTRIM(CONVERT(nvarchar(150), [VEHICLE_TYPE_CODE_5]))) FROM dbo.nyc_crashes_1m
)
SELECT TOP (15)
    vehicle_type,
    COUNT_BIG(*) AS vehicle_slot_occurrences
FROM vehicle_values
WHERE NULLIF(vehicle_type, N'') IS NOT NULL
GROUP BY vehicle_type
ORDER BY vehicle_slot_occurrences DESC;
GO

/*=============================================================================
  SECTION 14 — CASUALTY DATA QUALITY CHECK

  Purpose: Identify negative or non-convertible casualty values.
=============================================================================*/

SELECT
    SUM(CASE WHEN NUMBER_OF_PERSONS_INJURED IS NOT NULL
                  AND TRY_CONVERT(int, NUMBER_OF_PERSONS_INJURED) IS NULL
             THEN 1 ELSE 0 END) AS invalid_persons_injured,

    SUM(CASE WHEN TRY_CONVERT(int, NUMBER_OF_PERSONS_INJURED) < 0
             THEN 1 ELSE 0 END) AS negative_persons_injured,

    SUM(CASE WHEN NUMBER_OF_PERSONS_KILLED IS NOT NULL
                  AND TRY_CONVERT(int, NUMBER_OF_PERSONS_KILLED) IS NULL
             THEN 1 ELSE 0 END) AS invalid_persons_killed,

    SUM(CASE WHEN TRY_CONVERT(int, NUMBER_OF_PERSONS_KILLED) < 0
             THEN 1 ELSE 0 END) AS negative_persons_killed

FROM dbo.nyc_crashes_1m;
GO

/*=============================================================================
  SECTION 15 — MISSING-VALUE HANDLING FOR POWER BI (NON-DESTRUCTIVE)

  IMPORTANT:
  - This section is added to the ORIGINAL working SQL file.
  - The raw table dbo.nyc_crashes_1m is NOT updated, deleted, or overwritten.
  - A cleaned VIEW is created so Power BI can use standardized values while
    the original imported values remain available for auditing.

  TREATMENT RULES:
  1. BOROUGH:
     Blank / NULL borough -> 'UNKNOWN / UNASSIGNED'.
     Keep these crashes in the dataset; do not delete them.
  2. CONTRIBUTING FACTORS (all five vehicle factor columns):
     Blank, NULL, Unknown, Unspecified, Does Not Apply, Not Reported,
     Not Known, Not Applicable, N/A and NA -> NULL in the cleaned columns.
     These are not counted as reported causes in Top Factor charts.
  3. VEHICLE TYPES (all five vehicle type columns):
     Blank / NULL -> 'UNKNOWN VEHICLE TYPE'.
     Keep the vehicle/crash record.
  4. CASUALTIES:
     Keep missing injury/fatality values as NULL. Do not replace them with 0,
     because missing is not necessarily the same as zero.
  5. DATE / TIME:
     Provide safely converted date/time columns. Invalid values become NULL
     in the cleaned view, not in the raw source.
  6. COORDINATES:
     Values outside legal latitude/longitude ranges become NULL in the cleaned
     view. This does not apply a NYC bounding-box filter or delete records.

  POWER BI:
  Import dbo.vw_nyc_crashes_clean instead of dbo.nyc_crashes_1m when you need
  the standardized columns. Original columns are retained alongside *_clean
  columns for traceability.
=============================================================================*/

CREATE OR ALTER VIEW dbo.vw_nyc_crashes_clean
AS
SELECT
    r.*,

    /* Standardized borough */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(100), r.BOROUGH))), N'') IS NULL
            THEN N'UNKNOWN / UNASSIGNED'
        ELSE UPPER(LTRIM(RTRIM(CONVERT(nvarchar(100), r.BOROUGH))))
    END AS BOROUGH_CLEAN,

    /* Safe date and time conversions */
    TRY_CONVERT(date, r.CRASH_DATE, 101) AS CRASH_DATE_CLEAN,
    TRY_CONVERT(time(0), CONVERT(varchar(30), r.CRASH_TIME)) AS CRASH_TIME_CLEAN,

    /* Coordinates: only impossible global ranges are nulled */
    CASE
        WHEN TRY_CONVERT(float, r.LATITUDE) BETWEEN -90 AND 90
            THEN TRY_CONVERT(float, r.LATITUDE)
        ELSE NULL
    END AS LATITUDE_CLEAN,

    CASE
        WHEN TRY_CONVERT(float, r.LONGITUDE) BETWEEN -180 AND 180
            THEN TRY_CONVERT(float, r.LONGITUDE)
        ELSE NULL
    END AS LONGITUDE_CLEAN,

    /* Contributing factors: exclude blank and placeholder labels from analysis */
    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1))), N'') IS NULL
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%DOES NOT APPLY%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%UNKNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%UNSPECIFIED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%NOT REPORTED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%NOT KNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) LIKE N'%NOT APPLICABLE%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))) IN (N'N/A', N'NA')
            THEN NULL
        ELSE LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_1)))
    END AS CONTRIBUTING_FACTOR_1_CLEAN,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2))), N'') IS NULL
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%DOES NOT APPLY%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%UNKNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%UNSPECIFIED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%NOT REPORTED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%NOT KNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) LIKE N'%NOT APPLICABLE%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))) IN (N'N/A', N'NA')
            THEN NULL
        ELSE LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_2)))
    END AS CONTRIBUTING_FACTOR_2_CLEAN,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3))), N'') IS NULL
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%DOES NOT APPLY%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%UNKNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%UNSPECIFIED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%NOT REPORTED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%NOT KNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) LIKE N'%NOT APPLICABLE%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))) IN (N'N/A', N'NA')
            THEN NULL
        ELSE LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_3)))
    END AS CONTRIBUTING_FACTOR_3_CLEAN,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4))), N'') IS NULL
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%DOES NOT APPLY%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%UNKNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%UNSPECIFIED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%NOT REPORTED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%NOT KNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) LIKE N'%NOT APPLICABLE%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))) IN (N'N/A', N'NA')
            THEN NULL
        ELSE LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_4)))
    END AS CONTRIBUTING_FACTOR_4_CLEAN,

    CASE
        WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5))), N'') IS NULL
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%DOES NOT APPLY%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%UNKNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%UNSPECIFIED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%NOT REPORTED%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%NOT KNOWN%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) LIKE N'%NOT APPLICABLE%'
          OR UPPER(LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))) IN (N'N/A', N'NA')
            THEN NULL
        ELSE LTRIM(RTRIM(CONVERT(nvarchar(255), r.CONTRIBUTING_FACTOR_VEHICLE_5)))
    END AS CONTRIBUTING_FACTOR_5_CLEAN,

    /* Vehicle types: retain rows and label missing types explicitly */
    COALESCE(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(150), r.VEHICLE_TYPE_CODE_1))), N''), N'UNKNOWN VEHICLE TYPE')
        AS VEHICLE_TYPE_1_CLEAN,
    COALESCE(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(150), r.VEHICLE_TYPE_CODE_2))), N''), N'UNKNOWN VEHICLE TYPE')
        AS VEHICLE_TYPE_2_CLEAN,
    COALESCE(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(150), r.VEHICLE_TYPE_CODE_3))), N''), N'UNKNOWN VEHICLE TYPE')
        AS VEHICLE_TYPE_3_CLEAN,
    COALESCE(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(150), r.VEHICLE_TYPE_CODE_4))), N''), N'UNKNOWN VEHICLE TYPE')
        AS VEHICLE_TYPE_4_CLEAN,
    COALESCE(NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(150), r.VEHICLE_TYPE_CODE_5))), N''), N'UNKNOWN VEHICLE TYPE')
        AS VEHICLE_TYPE_5_CLEAN

FROM dbo.nyc_crashes_1m AS r;
GO

/* SECTION 15A — CHECK THE CLEANED VIEW ROW COUNT */
SELECT
    COUNT_BIG(*) AS cleaned_view_rows,
    SUM(CASE WHEN BOROUGH_CLEAN = N'UNKNOWN / UNASSIGNED' THEN 1 ELSE 0 END)
        AS unknown_borough_rows,
    SUM(CASE WHEN CRASH_DATE_CLEAN IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_dates,
    SUM(CASE WHEN CRASH_TIME_CLEAN IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_times,
    SUM(CASE WHEN LATITUDE_CLEAN IS NULL OR LONGITUDE_CLEAN IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_coordinate_pairs
FROM dbo.vw_nyc_crashes_clean;
GO

/* SECTION 15B — REPORTED VS UNREPORTED CONTRIBUTING FACTORS */
SELECT
    SUM(CASE WHEN factor_name IS NOT NULL THEN 1 ELSE 0 END) AS reported_factor_slots,
    SUM(CASE WHEN factor_name IS NULL THEN 1 ELSE 0 END) AS unreported_or_placeholder_slots,
    COUNT_BIG(*) AS total_factor_slots
FROM
(
    SELECT CONTRIBUTING_FACTOR_1_CLEAN AS factor_name FROM dbo.vw_nyc_crashes_clean
    UNION ALL
    SELECT CONTRIBUTING_FACTOR_2_CLEAN FROM dbo.vw_nyc_crashes_clean
    UNION ALL
    SELECT CONTRIBUTING_FACTOR_3_CLEAN FROM dbo.vw_nyc_crashes_clean
    UNION ALL
    SELECT CONTRIBUTING_FACTOR_4_CLEAN FROM dbo.vw_nyc_crashes_clean
    UNION ALL
    SELECT CONTRIBUTING_FACTOR_5_CLEAN FROM dbo.vw_nyc_crashes_clean
) AS factor_slots;
GO

/* END SECTION 15 — Original raw table remains unchanged. */
