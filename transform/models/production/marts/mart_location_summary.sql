with locations as (
    select *
    from {{ ref('stg_locations') }}
)

select
    location_id,
    name,
    type,
    dimension,
    resident_count
from locations
