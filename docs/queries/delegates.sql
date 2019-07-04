
select
  q.certifier_name,
  q.delegate_name,
  q.total,
  q.submitted,
  (100 * q.submitted / NULLIF(total, 0)) as submitted_percent,
  q.admissible,
  q.inadmissible,
  (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) as responded_percent,
  q.admissible * 100 / NULLIF(q.admissible + q.inadmissible, 0) as admissible_percent
from (
  select certifiers.name as certifier_name, delegates.name as delegate_name,
  (select count(*) from applications where applications.delegate_id = delegates.id) as total,
  (select count(*) from applications where applications.delegate_id = delegates.id  and applications.submitted_at IS NOT NULL) as submitted,
  (select count(*) from applications where applications.delegate_id = delegates.id  and applications.admissible_at IS NOT NULL) as admissible,
  (select count(*) from applications where applications.delegate_id = delegates.id  and applications.inadmissible_at IS NOT NULL) as inadmissible
  from delegates
  inner join certifiers_delegates on delegates.id = certifiers_delegates.delegate_id
  inner join certifiers on certifiers_delegates.certifier_id = certifiers.id
) q
order by admissible_percent desc NULLS LAST, total desc
