with episodes as (
    select *
    from {{ ref('stg_episodes') }}
)

select
    episode_id,
    episode_code,
    name,
    air_date,
    character_count
from episodes
