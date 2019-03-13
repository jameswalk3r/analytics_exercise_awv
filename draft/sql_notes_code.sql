select distinct state from physician_compare
where group_practice_pac_id is null

--Looking at all distinct primary_specialty by count
select primary_specialty, count(distinct pac_id)
from physician_compare
group by primary_specialty
order by count(distinct pac_id) desc

--Looking at distribution of specialties within all group practices
select distinct group_practice_pac_id,
organization_legal_name,
-- pac_id,
-- last_name,
-- first_name,
primary_specialty,
count(distinct pac_id) as count_providers
-- all_secondary_specialties
from physician_compare
group by 
group_practice_pac_id,
organization_legal_name,
primary_specialty
order by group_practice_pac_id,
count(distinct pac_id) desc

CLINIC OR GROUP PRACTICE
PHYSICIAN/PREVENTIVE

select primary_specialty, count(distinct pac_id)
from physician_compare
WHERE primary_specialty like ('%Preventive%')
group by primary_specialty
order by count(distinct pac_id) desc

select group_practice_pac_id, 
number_of_group_practice_members,
count(distinct pac_id) as count_pac_id,
(number_of_group_practice_members - count(distinct pac_id)) as diff
from physician_compare
-- where total_services = 16214.3
group by group_practice_pac_id, number_of_group_practice_members
order by (number_of_group_practice_members - count(distinct pac_id)) desc
limit 1000
                                                   
select * 
from physician_compare
where group_practice_pac_id is null
                                                   
SELECT * FROM 
   physician_compare pc
WHERE 
   pac_id = '2668450024'
   AND group_practice_pac_id IS NULL
   AND NOT EXISTS (
      SELECT *
      FROM physician_compare pc2
      WHERE pc.pac_id = pc2.pac_id
         --AND pc.physician_compare_id <> pc2.physician_compare_id --NOT NEEDED SINCE LOOKING AT ANY CASE, EVEN IF SAME ROW
         AND pc2.group_practice_pac_id IS NOT NULL) 
                                                   
select * from physician_compare where group_practice_pac_id IS  NULL
                                                   
SELECT a.group_practice_pac_id, b.group_practice_pac_id, * FROM physician_compare a 
join physician_compare b 
on a.pac_id = b.pac_id and a.physician_compare_id <> b.physician_compare_id
WHERE a.group_practice_pac_id is null and b.group_practice_pac_id is not null
                                                   
select * from physician_supplier_hcpcs order by npi limit 1000
                                                   

SELECT primary_specialty, group_practice_pac_id, * FROM physician_compare where group_practice_pac_id = '5496744864'