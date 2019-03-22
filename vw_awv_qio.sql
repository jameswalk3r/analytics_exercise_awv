WITH temp_primary_npis AS (
SELECT 
   pcp.practice_pac_id, 
   pcp.practice_type, 
   pcp.organization_legal_name AS practice_group_name, 
   pc.* 
FROM 
   vw_primary_care_practices pcp
JOIN 
   physician_compare pc 
-- Joining on group_practice_pac_id will return NPIs associated with a group
ON pcp.group_practice_pac_id = pc.group_practice_pac_id
UNION
SELECT 
   pcp.practice_pac_id, 
   pcp.practice_type, 
   pcp.organization_legal_name AS practice_group_name, 
   pc.* 
FROM 
   vw_primary_care_practices pcp
JOIN 
-- Joining on pac_id will return only Solo Practices
   physician_compare pc 
ON pcp.pac_id = pc.pac_id
)
SELECT DISTINCT 
   tpn.practice_pac_id, 
   tpn.practice_type,
   tpn.practice_group_name,
   pawv.practice_awv_count,
   tpn.npi,
   tpn.last_name,
   tpn.first_name,
   tpn.credential,
   tpn.primary_specialty,
   awv.total_awv, -- Total AWV performed by NPI
   psa.total_unique_benes, 
   psa.total_medicare_allowed_amt,
   -- Note: AVG COST FOR NPI SPEND ONLY. NOT REPRESENTATIVE OF OVER BENE AVG COST
      --This would be removed to prevent improper use but will leave for exercise
   (psa.total_medicare_allowed_amt/psa.total_unique_benes) AS avg_cost_per_bene,
   psa.beneficiary_average_risk_score,
   (coalesce(awv.total_awv, 0)/coalesce(psa.total_unique_benes, 0)) AS pct_awv,
   avg_average_medicare_payment_amt  --NOTE: Average of averages is never preferred. 
FROM 
   temp_primary_npis tpn 
LEFT JOIN 
( -- Returns AWVs and Average Medicare Payment by NPI
   SELECT 
      npi,
      sum(line_srvc_cnt) AS total_awv,
      --NOTE: Average of averages is never preferred.
      avg(cast(average_medicare_payment_amt AS decimal)) AS avg_average_medicare_payment_amt
   FROM physician_supplier_hcpcs
   WHERE hcpcs_code IN ('G0438','G0439','G0468')
   GROUP BY npi
) awv
ON tpn.npi = awv.npi
LEFT JOIN 
(
   SELECT 
   -- NPIs can be attributed to multiple practices. More info required to narrow to practice level
   -- example: NPI = '1023057106'
      practice_pac_id, 
      practice_type, 
      --hcpcs_code,
      sum(line_srvc_cnt) AS practice_awv_count
   FROM (SELECT distinct practice_pac_id, practice_type, npi FROM temp_primary_npis) tpn
   JOIN physician_supplier_hcpcs psh
   ON tpn.npi = psh.npi
   WHERE hcpcs_code IN ('G0438','G0439','G0468')
   GROUP BY practice_pac_id, 
      practice_type
   ORDER BY sum(line_srvc_cnt) DESC, practice_pac_id
) pawv
ON tpn.practice_pac_id = pawv.practice_pac_id
LEFT JOIN 
   physician_supplier_agg psa
ON tpn.npi = psa.npi
WHERE 
   tpn.primary_specialty IN ( --target PCPs and PA/NP
      'INTERNAL MEDICINE',
      'FAMILY PRACTICE',
      'OBSTETRICS/GYNECOLOGY',
      'GENERAL PRACTICE',
      'GERIATRIC MEDICINE',
      'CLINIC OR GROUP PRACTICE' --None exist in dataset
      'PHYSICIAN/PREVENTIVE',
      'NURSE PRACTITIONER',  --NOTE: Adding NP and PA for engagement
      'PHYSICIAN ASSISTANT')
   AND psa.medicare_participation_indicator = 'Y'  -- Assuming we'll only engage Y NPIs
ORDER BY 
   beneficiary_average_risk_score DESC;

