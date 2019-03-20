--NOTE: Due to duplication of rows, if specialties, names, etc. change, it could cause aggregations to be inaccurate.  Ideally, data would be sourced from a cleansed data source with the latest, valid provider record to be used. 


-- Creates a temporary table for each group_practice_pac_id, finding the most frequently occuring primary_specialty.  Assigns that to the group. 
DROP TABLE IF EXISTS temp_group_practices;

CREATE TEMP TABLE temp_group_practices AS
SELECT DISTINCT 
   group_practice_pac_id,
   organization_legal_name,
   primary_specialty, --Note: Primary Specialty is at the NPI level, not at the group level 
   count(distinct pac_id) AS count_providers, --Based on group by, this will show providers by specialty
   ROW_NUMBER () OVER (PARTITION BY group_practice_pac_id ORDER BY count(distinct pac_id) DESC ) AS specialty_prevalence --NOTE: Used to identify the most prevalent occurance of the primary_specialty in the group. GAP: SORTING OF THE SAME NUMBER IS ARBITRARY. FIX.
FROM 
   physician_compare
WHERE
   primary_specialty NOT IN ('NURSE PRACTITIONER',
                            'PHYSICIAN ASSISTANT')
   AND group_practice_pac_id IS NOT NULL  --Note: This removes providers who are not affiliated with a group.  These are added back in later using UNION.
GROUP BY 
   group_practice_pac_id,
   organization_legal_name,
   primary_specialty;
-- ORDER BY --Order Bys unnecessary and expensive unless reviewing results
--    group_practice_pac_id,
--    count(distinct pac_id) DESC;

----------------------------------------------------------------------

DROP TABLE IF EXISTS temp_group_primary_care;

CREATE TEMP TABLE temp_group_primary_care AS
SELECT 
   'Group Practice' AS practice_type,
   NULL AS pac_id,
   NULL AS full_name,
   group_practice_pac_id,
   organization_legal_name,
   primary_specialty
FROM 
   temp_group_practices
WHERE
   specialty_prevalence = 1 -- Targets most prevalent specialty 
   AND primary_specialty IN 
      ('INTERNAL MEDICINE',
      'FAMILY PRACTICE',
      'OBSTETRICS/GYNECOLOGY',
      'GENERAL PRACTICE',
      'GERIATRIC MEDICINE',
      'CLINIC OR GROUP PRACTICE' --None exist in dataset
      'PHYSICIAN/PREVENTIVE' --None exist in dataset
    );
    
----------------------------------------------------------------------
DROP TABLE IF EXISTS temp_solo_primary_care;

CREATE TEMP TABLE temp_solo_primary_care AS
SELECT DISTINCT --Using distinct to remove duplications, though some may exist if differences lie in returned fields. Final aggregations should use COUNT DISTINCT
   'Solo Practice' AS practice_type,
   pac_id,
   last_name || ', ' || first_name AS full_name,
   group_practice_pac_id,
   organization_legal_name,
   primary_specialty
FROM 
   physician_compare pc
WHERE 
   pc.group_practice_pac_id IS NULL  -- Looking for NPIs (assuming physicians) not a part of a group
   -- NOTE: When providers exist both within a group and outside of a group, both are counted as separate practices. 
   AND primary_specialty IN 
      ('INTERNAL MEDICINE',
      'FAMILY PRACTICE',
      'OBSTETRICS/GYNECOLOGY',
      'GENERAL PRACTICE',
      'GERIATRIC MEDICINE',
      'CLINIC OR GROUP PRACTICE' --None exist in dataset
      'PHYSICIAN/PREVENTIVE' --None exist in dataset
    );
    
----------------------------------------------------------------------
DROP TABLE IF EXISTS temp_primary_care;

CREATE TEMP TABLE temp_primary_care AS
SELECT *
FROM temp_group_primary_care
UNION -- No duplicates expected, so either UNION or UNION ALL is fine
SELECT *
FROM temp_solo_primary_care;

----------------------------------------------------------------------
--FINAL RESULTS
SELECT 
   COUNT(DISTINCT COALESCE(pac_id, group_practice_pac_id)) AS count_primary_care_practices --Coalesce IDs to get a count of primary care practices
FROM 
   temp_primary_care
   
-- SELECT * FROM temp_primary_care

----------------------------------------------------------------------
                           
-- Spot check validation
-- select distinct a.pac_id, a.primary_specialty, a.organization_legal_name,  a.group_practice_pac_id
-- from physician_compare a
-- join temp_primary_care b 
-- on a.group_practice_pac_id = b.group_practice_pac_id 
-- order by a.group_practice_pac_id


