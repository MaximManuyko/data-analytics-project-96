--Расчёт общего количества визитов
SELECT sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        to_char(date_trunc('day', visit_date), 'YYYY-MM-DD') AS date,
        count(visitor_id),
        count(DISTINCT visitor_id) AS count_distinct
    FROM sessions
    GROUP BY
        3,
        sessions.source,
        sessions.medium
    ORDER BY date) AS virtual_table


--Расчёт количества уникальных визитов
select COUNT(distinct(visitor_id)) as distinct_visitors_count
from sessions

--Ежедневные визиты
SELECT
    date AS date,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        to_char(date_trunc('day', visit_date), 'YYYY-MM-DD') AS date,
        count(visitor_id)
    FROM sessions
    GROUP BY
        3,
        sessions.source,
        sessions.medium
    ORDER BY date) AS virtual_table
GROUP BY date
ORDER BY "SUM(count)" DESC


--Визиты по неделям
SELECT
    monday_date AS monday_date,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        count(visitor_id),
        to_char(date_trunc('week', visit_date), 'YYYY-MM-DD') AS monday_date
    FROM sessions
    GROUP BY
        monday_date,
        sessions.source,
        sessions.medium
    ORDER BY monday_date) AS virtual_table
GROUP BY monday_date
ORDER BY "SUM(count)" DESC


--Визиты по дням недели
SELECT
    day_of_week_combined AS day_of_week_combined,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        count(visitor_id),
        (extract(
            ISODOW
            FROM visit_date
        )::TEXT || '.' || to_char(visit_date, 'Day'
        )) AS day_of_week_combined
    FROM sessions
    GROUP BY
        day_of_week_combined,
        sessions.source,
        sessions.medium
    ORDER BY day_of_week_combined) AS virtual_table
GROUP BY day_of_week_combined
ORDER BY "SUM(count)" DESC


--ТОП 10 Source по количеству визитов
SELECT
    source AS source,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        to_char(date_trunc('day', visit_date), 'YYYY-MM-DD') AS date,
        count(visitor_id),
        count(DISTINCT visitor_id) AS count_distinct
    FROM sessions
    GROUP BY
        3,
        sessions.source,
        sessions.medium
    ORDER BY date) AS virtual_table
GROUP BY source
ORDER BY "SUM(count)" DESC
LIMIT 10


--ТОП 10 medium по количеству визитов
SELECT
    medium AS medium,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        sessions.source,
        sessions.medium,
        to_char(date_trunc('day', visit_date), 'YYYY-MM-DD') AS date,
        count(visitor_id),
        count(DISTINCT visitor_id) AS count_distinct
    FROM sessions
    GROUP BY
        3,
        sessions.source,
        sessions.medium
    ORDER BY date) AS virtual_table
GROUP BY medium
ORDER BY "SUM(count)" DESC


--Количество лидов
SELECT sum(leed) AS "SUM(leed)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table


--Количество Purchases_count
SELECT sum(leed_amount) AS "SUM(leed_amount)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table


--Процент лидов совершивших покупку к общему количеству лидов (Конверсия)
SELECT SUM(leed_amount) * 100 / SUM(leed) AS "SUM(leed_amount)*100/SUM(leed)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        TO_CHAR(DATE_TRUNC('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table


--Доход
SELECT sum(amount) AS "SUM(amount)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table


--Средний чек
SELECT AVG(amount) AS "AVG(amount)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        TO_CHAR(DATE_TRUNC('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table
WHERE amount > 0


--Ежедневные продажи
SELECT
    date AS date,
    sum(amount) AS "SUM(amount)"
FROM
    (SELECT
        1 AS leed,
        amount,
        closing_reason,
        CASE
            WHEN amount > 0 THEN 1
            ELSE 0
        END AS leed_amount,
        to_char(date_trunc('day', created_at), 'YYYY-MM-DD') AS date
    FROM leads
    ORDER BY date) AS virtual_table
GROUP BY date
ORDER BY "SUM(amount)" DESC


--Расходы
SELECT sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table


--Расходы на yandex
SELECT sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
WHERE utm_source IN ('yandex')


--Расходы на vk
SELECT sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
WHERE utm_source IN ('vk')


--Расходы по utm_source
SELECT
    utm_source AS utm_source,
    sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
GROUP BY utm_source
ORDER BY "SUM(total_daily_spent)" DESC


--Расходы по yandex utm_medium
SELECT
    utm_medium AS utm_medium,
    sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
WHERE utm_source IN ('yandex')
GROUP BY utm_medium
ORDER BY "SUM(total_daily_spent)" DESC


--Расходы vk по utm_medium
SELECT
    utm_medium AS utm_medium,
    sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
WHERE utm_source IN ('vk')
GROUP BY utm_medium
ORDER BY "SUM(total_daily_spent)" DESC


--Ежедневные расходы
SELECT
    DATE_TRUNC('day', campaign_date) AS campaign_date,
    SUM(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            SUM(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
GROUP BY DATE_TRUNC('day', campaign_date)
ORDER BY "SUM(total_daily_spent)" DESC


--Расходы по utm_campaign
SELECT
    utm_campaign AS utm_campaign,
    sum(total_daily_spent) AS "SUM(total_daily_spent)"
FROM
    (
        SELECT
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date,
            sum(daily_spent) AS total_daily_spent
        FROM
            (SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM vk_ads
            UNION ALL
            SELECT
                campaign_name,
                utm_source,
                utm_medium,
                utm_campaign,
                utm_content,
                campaign_date,
                daily_spent
            FROM ya_ads) AS combined_ads
        GROUP BY
            campaign_name,
            utm_source,
            utm_medium,
            utm_campaign,
            utm_content,
            campaign_date
    ) AS virtual_table
GROUP BY utm_campaign
ORDER BY "SUM(total_daily_spent)" DESC


--Расходы по utm_content
SELECT
    utm_content AS utm_content,
    total_daily_spent AS total_daily_spent
FROM
    (SELECT
        utm_content,
        SUM(daily_spent) AS total_daily_spent
    FROM
        (SELECT
            utm_content,
            daily_spent
        FROM vk_ads
        UNION ALL
        SELECT
            utm_content,
            daily_spent
        FROM ya_ads) AS combined_ads
    GROUP BY utm_content
    ORDER BY total_daily_spent DESC) AS virtual_table


--Воронка

SELECT
    metric AS metric,
    sum(count) AS "SUM(count)"
FROM
    (SELECT
        'Visits' AS metric,
        count(*) AS count
    FROM sessions
    UNION ALL
    SELECT
        'Leads' AS metric,
        count(*)
    FROM leads
    UNION ALL
    SELECT
        'Positive Leads' AS metric,
        count(*)
    FROM leads
    WHERE amount > 0) AS virtual_table
GROUP BY metric


--Таблица для построения атрибуции  Last Paid Click
with tab as (
    select
        sessions.visitor_id,
        visit_date,
        source,
        medium,
        campaign,
        created_at,
        closing_reason,
        status_id,
        coalesce(amount, 0) as amount,
        case
            when created_at < visit_date then 'delete' else lead_id
        end as lead_id,
        row_number()
            over (partition by sessions.visitor_id order by visit_date desc)
        as rn
    from sessions
    left join leads
        on sessions.visitor_id = leads.visitor_id
    where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

tab2 as (
    select
        tab.visitor_id,
        tab.source as utm_source,
        tab.medium as utm_medium,
        tab.campaign as utm_campaign,
        tab.created_at,
        tab.amount,
        tab.closing_reason,
        tab.status_id,
        date_trunc('day', tab.visit_date) as visit_date,
        case
            when tab.created_at < tab.visit_date then 'delete' else lead_id
        end as lead_id
    from tab
    where (tab.lead_id != 'delete' or tab.lead_id is null) and tab.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from tab2
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

tab4 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from tab4
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

tab5 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
)

select
    TO_CHAR(visit_date, 'YYYY-MM-DD') AS visit_date,
    TO_CHAR(DATE_TRUNC('week', visit_date), 'YYYY-MM-DD') AS monday_date,
    (EXTRACT(ISODOW
                FROM visit_date)::TEXT || '.' || TO_CHAR(visit_date, 'Day')) AS day_of_week_combined,
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(visitors_count, 0)) as visitors_count,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(leads_count, 0)) as leads_count,
    sum(coalesce(purchases_count, 0)) as purchases_count,
    sum(coalesce(revenue, 0)) as revenue
from tab5
group by
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
order by visit_date

--Сводная таблица
with tab as (
    select
        sessions.visitor_id,
        visit_date,
        source,
        medium,
        campaign,
        created_at,
        closing_reason,
        status_id,
        coalesce(amount, 0) as amount,
        case
            when created_at < visit_date then 'delete' else lead_id
        end as lead_id,
        row_number()
            over (partition by sessions.visitor_id order by visit_date desc)
        as rn
    from sessions
    left join leads
        on sessions.visitor_id = leads.visitor_id
    where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

tab2 as (
    select
        tab.visitor_id,
        tab.source as utm_source,
        tab.medium as utm_medium,
        tab.campaign as utm_campaign,
        tab.created_at,
        tab.amount,
        tab.closing_reason,
        tab.status_id,
        date_trunc('day', tab.visit_date) as visit_date,
        case
            when tab.created_at < tab.visit_date then 'delete' else lead_id
        end as lead_id
    from tab
    where (tab.lead_id != 'delete' or tab.lead_id is null) and tab.rn = 1
),

amount as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        count(visitor_id) as visitors_count,
        sum(case when lead_id is not null then 1 else 0 end) as leads_count,
        sum(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        sum(amount) as revenue
    from tab2
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

tab4 as (
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from vk_ads
    union all
    select
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        daily_spent
    from ya_ads
),

cost as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from tab4
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

tab5 as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        null as revenue,
        null as visitors_count,
        null as leads_count,
        null as purchases_count,
        total_cost
    from cost
    union all
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from amount
),
tab6 as (
select
    utm_source,
    utm_medium,
    utm_campaign,
    sum(coalesce(visitors_count, 0)) as visitors_count,
    sum(coalesce(total_cost, 0)) as total_cost,
    sum(coalesce(leads_count, 0)) as leads_count,
    sum(coalesce(purchases_count, 0)) as purchases_count,
    sum(coalesce(revenue, 0)) as revenue
from tab5
group by
    utm_source,
    utm_medium,
    utm_campaign
order by total_cost desc
)
select *,
    CASE WHEN visitors_count = 0 THEN NULL ELSE total_cost / visitors_count END AS cpu,
    CASE WHEN leads_count = 0 THEN NULL ELSE total_cost / leads_count END AS cpl,
    CASE WHEN purchases_count = 0 THEN NULL ELSE total_cost / purchases_count END AS cppu,
    CASE WHEN total_cost = 0 THEN NULL ELSE ((revenue - total_cost) / total_cost) * 100 END AS roi
FROM tab6
order by roi