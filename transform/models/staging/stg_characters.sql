with source as (
    select *
    from {{ source('rick_and_morty', 'characters') }}
),

renamed as (
    select
        id::int as character_id,
        name,
        status,
        species,
        nullif(type, '') as type,
        gender,
        origin ->> 'name' as origin_name,
        location ->> 'name' as location_name,
        image as image_url,
        url as character_url,
        created::timestamptz as created_at
    from source
)

select *
from renamed
