with characters as (
    select *
    from {{ ref('stg_characters') }}
)

select
    coalesce(status, 'unknown') as status,
    count(*) as character_count
from characters
group by status
