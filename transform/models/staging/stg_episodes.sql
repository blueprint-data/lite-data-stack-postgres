with source as (
    select *
    from {{ source('rick_and_morty', 'episodes') }}
)

select
    id::int as episode_id,
    name,
    air_date,
    episode as episode_code,
    url as episode_url,
    created::timestamptz as created_at,
    coalesce(jsonb_array_length(characters::jsonb), 0) as character_count
from source
