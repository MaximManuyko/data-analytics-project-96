/*Расчет расходов
Построим витрину со следующими полями:

visit_date — дата визита
utm_source / utm_medium / utm_campaign — метки пользователя
visitors_count — количество визитов в этот день с этими метками
total_cost — затраты на рекламу
leads_count — количество лидов, которые оставили визиты, кликнувшие в этот день с этими метками
purchases_count — количество успешно закрытых лидов (closing_reason = “Успешно реализовано” или status_code = 142)
revenue — деньги с успешно закрытых лидов
Требования
Отсортируйте данные по полям

revenue — от большего к меньшему, null записи идут последними
visit_date — от ранних к поздним
visitors_count — в убывающем порядке
utm_source, utm_medium, utm_campaign — в алфавитном порядке*/

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
    visit_date,
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
order by
    revenue desc,
    visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
