with episodes as (
    select
        episode_id,
        episode_code,
        character_count,
        created_at
    from {{ ref('stg_episodes') }}
)

select *
from episodes
