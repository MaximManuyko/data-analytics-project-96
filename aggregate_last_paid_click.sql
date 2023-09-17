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
utm_source, utm_medium, utm_campaign — в алфавитном порядке
Задачи
Посчитайте расходы на рекламу по модели атрибуции Last Paid Click
Создайте и напишите для агрегации данных из модели атрибуции Last Paid Click aggregate_last_paid_click.sql
Сохраните топ-15 записей в aggregate_last_paid_click.csv согласно требованиям по сортировке*/


with sessions_leads as (
    select
        sessions.visitor_id,
        visit_date,
        source as utm_source,
        medium as utm_medium,
        campaign as utm_campaign,
        created_at,
        amount,
        closing_reason,
        status_id,
        lead_id,
        ROW_NUMBER()
            over (partition by sessions.visitor_id order by visit_date desc)
        as rn
    from sessions
    left join leads
        on
            sessions.visitor_id = leads.visitor_id
            and visit_date <= created_at
    where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
),

revenue as (
    select
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(visitor_id) as visitors_count,
        SUM(case when lead_id is not null then 1 else 0 end) as leads_count,
        SUM(
            case
                when
                    closing_reason = 'Успешная продажа' or status_id = 142
                    then 1
                else 0
            end
        ) as purchases_count,
        SUM(amount) as revenue
    from sessions_leads
    where sessions_leads.rn = 1
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

vk_ads_ya_ads as (
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) as total_cost
    from vk_ads
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
    union all
    select
        campaign_date as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) as total_cost
    from ya_ads
    group by
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

total_cost_revenue as (
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
    from vk_ads_ya_ads
    union all
    select
        DATE_TRUNC('day', visit_date) as visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        revenue,
        visitors_count,
        leads_count,
        purchases_count,
        null as total_cost
    from revenue
)

select
	TO_CHAR(visit_date, 'YYYY-MM-DD') as visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    SUM(visitors_count) as visitors_count,
    SUM(total_cost) as total_cost,
    SUM(leads_count) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(revenue) as revenue
from total_cost_revenue
group by
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc