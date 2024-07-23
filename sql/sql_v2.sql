-- Пошук edrpou закладу з контрактом за пакетом 42 у 2024 році
WITH owners AS (
SELECT DISTINCT b.owner_undog AS ow
  FROM analytics.dwh_smd_contracts_view AS b
	   INNER JOIN (
		   SELECT contract_id
			 FROM analytics.dwh_smd_contract_specifications_view
			WHERE specification_id = '42' -- номер пакету
				  ) AS sp
		ON sp.contract_id = b.id
	),
numbered_rows AS (
SELECT edrpou, id, undog, parent_undog, owner_undog, contract_number, 
       kwd_type,
	   ROW_NUMBER() OVER (PARTITION BY owner_undog ORDER BY parent_undog)
  FROM analytics.dwh_smd_contracts_view 
 WHERE owner_undog IN (SELECT ow FROM owners)
   AND (contract_start_date BETWEEN '2024-01-01' AND '2024-12-31')
   AND status_sign = 'Подписан'
),
edrpou AS (
SELECT nr.edrpou 
	   -- , nr.contract_number, 
       -- lev.kwd_name, lev.registration_area
  FROM numbered_rows AS nr
	   LEFT JOIN analytics.dwh_legal_entities_edrpou_view AS lev
			USING (edrpou)
 WHERE row_number = 1 
   AND lev.registration_area IN ('ЗАПОРІЗЬКА', 'ХЕРСОНСЬКА')
	)
-- Відбір персоналу по закладам які знайдени вище
SELECT edrpou, public_name, dv2.description AS тип_працівника, dv.description AS спеціальність, count
  FROM (
SELECT edrpou, public_name, employee_type, speciality ->>'speciality' AS speciality,
       COUNT(*) AS count
  FROM core.dim_rpt_legal_entities AS le
       INNER JOIN core.dim_rpt_employees AS re ON le.id = re.legal_entity_id
 WHERE edrpou IN (SELECT * FROM edrpou) 
   AND le.is_current = 'Y'
   AND le.status = 'ACTIVE'
   AND le.kwd_type = 'OUTPATIENT'
   AND re.is_current = 'Y'
   AND re.status = 'APPROVED'
   AND re.is_active
 GROUP BY 1, 2, 3, 4) AS t
       LEFT JOIN core.dim_rpt_dictionary_values AS dv ON t.speciality = dv.code AND is_current = 'Y' 
	        AND dictionary_id = '47e0eb72-780d-445b-a070-12c466ca378d' -- словник для speciality
	   LEFT JOIN core.dim_rpt_dictionary_values AS dv2 ON t.employee_type = dv2.code AND dv2.is_current = 'Y' 
	        AND dv2.dictionary_id = '70f2f040-8fdf-447c-9f76-a582107f534a' -- словник для employee_type		
 ORDER BY edrpou