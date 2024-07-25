-- Пошук legal_entity_id закладу з контрактом за пакетом 42 у 2024 році
WITH zoz AS (
SELECT legal_entity_id
  FROM analytics.dwh_contract_master_smarttender_view m
       JOIN analytics.dwh_smd_contract_specifications_view as sp on sp.contract_id = m.id
 WHERE specification_id = '42'
	)
-- Відбір персоналу по закладам які знайдени вище
SELECT registration_area, 
       edrpou, 
	   public_name, 
	--   kwd_position, 
	   dv3.description AS посада,
	   dv2.description AS тип_працівника, 
	   dv.description AS спеціальність, 
	   count
  FROM (
SELECT ev.registration_area, le.edrpou, le.public_name, kwd_position, employee_type, speciality ->>'speciality' AS speciality,
       COUNT(*) AS count
  FROM core.dim_rpt_legal_entities AS le
       INNER JOIN core.dim_rpt_employees AS re ON le.id = re.legal_entity_id
	   LEFT JOIN analytics.dwh_legal_entities_edrpou_view AS ev ON ev.edrpou = le.edrpou
	   INNER JOIN core.dim_rpt_parties as par on par.id = re.party_id and par.is_current = 'Y'
       LEFT JOIN core.dim_rpt_employee_roles as role --ролі працівників
       on role.employee_id = re.id and role.is_current = 'Y' and role.is_active and role.status = 'ACTIVE'
 WHERE legal_entity_id IN (SELECT * FROM zoz) 
   AND le.is_current = 'Y'
   AND le.status = 'ACTIVE'
   AND le.kwd_type = 'OUTPATIENT'
   AND re.is_current = 'Y'
   AND re.status = 'APPROVED'
   AND re.is_active
 GROUP BY 1, 2, 3, 4, 5, 6) AS t
       LEFT JOIN core.dim_rpt_dictionary_values AS dv ON t.speciality = dv.code AND is_current = 'Y' 
	        AND dictionary_id = '47e0eb72-780d-445b-a070-12c466ca378d' -- словник для speciality
	   LEFT JOIN core.dim_rpt_dictionary_values AS dv2 ON t.employee_type = dv2.code AND dv2.is_current = 'Y' 
	        AND dv2.dictionary_id = '70f2f040-8fdf-447c-9f76-a582107f534a' -- словник для employee_type		
	   LEFT JOIN core.dim_rpt_dictionary_values AS dv3 ON t.kwd_position = dv3.code	AND dv3.is_current = 'Y'
	        AND dv3.dictionary_id = 'c53c21d9-76ed-45c8-a393-09000186446e' -- словник для kwd_position
 ORDER BY registration_area