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

--запрос на расчет времени закрытия 90% лидов.
WITH tab AS (
    SELECT
        sessions.visitor_id,
        visit_date,
        source,
        medium,
        campaign,
        created_at,
        closing_reason,
        status_id,
        lead_id,
        COALESCE(amount, 0) AS amount,
        ROW_NUMBER()
            OVER (PARTITION BY sessions.visitor_id ORDER BY visit_date DESC)
        AS rn
    FROM sessions
    LEFT JOIN leads
        ON
            sessions.visitor_id = leads.visitor_id
            AND visit_date <= created_at
    WHERE medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)

SELECT
    tab.visit_date,
    tab.created_at,
    tab.lead_id,
    tab.created_at - tab.visit_date AS day,
    (
        SELECT
            PERCENTILE_DISC(0.9) WITHIN GROUP (
                ORDER BY created_at - visit_date
            ) AS percentile_90
        FROM tab
        WHERE tab.rn = 1 AND status_id = 142
    ) AS "90th Percentile"
FROM tab
WHERE tab.rn = 1 AND tab.status_id = 142
ORDER BY day;
--запрос на расчет времени закрытия 90% лидов(Версия 2).
WITH tab AS (
    SELECT
        sessions.visitor_id,
        visit_date,
        source,
        medium,
        campaign,
        created_at,
        closing_reason,
        status_id,
        lead_id,
        COALESCE(amount, 0) AS amount,
        ROW_NUMBER()
            OVER (PARTITION BY sessions.visitor_id ORDER BY visit_date DESC)
        AS rn,
        created_at - visit_date AS day
    FROM sessions
    LEFT JOIN leads
        ON
            sessions.visitor_id = leads.visitor_id
            AND visit_date <= created_at
    WHERE medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)

SELECT
    tab.visit_date,
    tab.created_at,
    tab.lead_id,
    tab.day,
    NTILE(10) OVER (ORDER BY tab.day) AS group_num
FROM tab
WHERE
    tab.rn = 1
    AND tab.status_id = 142
ORDER BY tab.day;