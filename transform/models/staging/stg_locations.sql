with source as (
    select *
    from {{ source('rick_and_morty', 'locations') }}
)

select
    id::int as location_id,
    name,
    nullif(type, '') as type,
    dimension,
    url as location_url,
    created::timestamptz as created_at,
    coalesce(jsonb_array_length(residents::jsonb), 0) as resident_count
from source
