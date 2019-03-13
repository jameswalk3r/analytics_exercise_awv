DROP TABLE IF EXISTS temp_primary_npis;

-- Creating a row for each NPI by practice
CREATE TEMP TABLE temp_primary_npis AS
SELECT 
   pcp.practice_pac_id, 
   pcp.practice_type, 
   pc.* 
FROM 
   vw_primary_care_practices pcp
JOIN 
   physician_compare pc 
-- Joining on group_practice_pac_id will return NPIs associated with a group
ON pcp.group_practice_pac_id = pc.group_practice_pac_id
UNION
SELECT 
   pcp.practice_pac_id, pcp.practice_type, pc.* 
FROM 
   vw_primary_care_practices pcp
JOIN 
   physician_compare pc 
-- Joining on pac_id will return only Solo Practices
ON pcp.pac_id = pc.pac_id;

SELECT 
-- NOTE: NPIs can be attributed to multiple practices. More info required to narrow to practice level
-- example: NPI = '1023057106'
   practice_pac_id, 
   practice_type, 
   sum(line_srvc_cnt) AS count_awv
FROM (
      -- Joining to subquery to remove row duplication originating in physician_compare
      SELECT DISTINCT practice_pac_id, practice_type, npi 
      FROM temp_primary_npis) tpn
JOIN 
   physician_supplier_hcpcs psh
ON tpn.npi = psh.npi
WHERE 
   hcpcs_code IN ('G0438','G0439','G0468')  -- Annual Wellness Visit HCPCS codes
GROUP BY 
   practice_pac_id, 
   practice_type
ORDER BY 
   sum(line_srvc_cnt) DESC, 
   practice_pac_id;

-- Pressed for time, so simply pulling org name
SELECT DISTINCT organization_legal_name 
FROM physician_compare 
WHERE group_practice_pac_id = '5496744864'

-- Simple Validations
-- SELECT * FROM (SELECT distinct practice_pac_id, practice_type, npi FROM temp_primary_npis) tpn
-- JOIN physician_supplier_hcpcs psh
-- ON tpn.npi = psh.npi
-- WHERE tpn.practice_pac_id = '5496744864'
-- and hcpcs_code in ('G0438','G0439','G0468')