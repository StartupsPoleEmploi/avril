select
  q.name,
  q.acronym,
  q.label,
  q.total,
  q.submitted,
  (100 * q.submitted / NULLIF(total, 0)) as submitted_percent,
  q.admissible,
  q.inadmissible,
  (q.admissible + q.inadmissible) * 100 / NULLIF(q.submitted, 0) as responded_percent,
  (100 * q.admissible / NULLIF(q.admissible + q.inadmissible, 0)) as admissible_percent
from (
  select certifiers.name, certifications.acronym, certifications.label,
  (select count(*) from applications where applications.certification_id = certifications.id) as total,
  (select count(*) from applications where applications.certification_id = certifications.id  and applications.submitted_at IS NOT NULL) as submitted,
  (select count(*) from applications where applications.certification_id = certifications.id  and applications.admissible_at IS NOT NULL) as admissible,
  (select count(*) from applications where applications.certification_id = certifications.id  and applications.inadmissible_at IS NOT NULL) as inadmissible
  from certifications
  inner join certifier_certifications on certifications.id = certifier_certifications.certification_id
  inner join certifiers on certifier_certifications.certifier_id = certifiers.id
) q
order by admissible_percent desc NULLS LAST, total desc