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
        origin_name,
        origin_url,
        location_name,
        location_url,
        image as image_url,
        url as character_url,
        created::timestamptz as created_at
    from source
)

select *
from renamed
