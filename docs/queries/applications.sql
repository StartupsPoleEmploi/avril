select delegates.name as certificateur, certifications.label as certification, users.name, users.email, users.address4, users.postal_code, users.city_label, applications.inserted_at, applications.admissible_at, applications.inadmissible_at
from applications
inner join users on applications.user_id = users.id
inner join certifications on applications.certification_id = certifications.id
inner join delegates on applications.delegate_id = delegates.id
where delegates.administrative='Occitanie'
order by delegates.name, certifications.label, users.name