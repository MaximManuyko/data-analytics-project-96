--Построим витрину со следующими полями:

--visit_date — дата визита
--utm_source / utm_medium / utm_campaign — метки пользователя
--visitors_count — количество визитов в этот день с этими метками
--total_cost — затраты на рекламу
--leads_count — количество лидов, которые оставили визиты, кликнувшие в этот день с этими метками
--purchases_count — количество успешно закрытых лидов (closing_reason = “Успешно реализовано” или status_code = 142)
--revenue — деньги с успешно закрытых лидов
--Требования
--Отсортируйте данные по полям

--visit_date — от ранних к поздним
--visitors_count — в убывающем порядке
--utm_source, utm_medium, utm_campaign — в алфавитном порядке

with tab as (
SELECT
    sessions.visitor_id,
    TO_CHAR(visit_date, 'YYYY-MM-DD') AS visit_date,
    source AS utm_source,
    medium AS utm_medium,
    campaign AS utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id,
    COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
    COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
    COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) as total_cost,
    case when closing_reason = 'Успешная продажа' or status_id = 142 then 1 end as purchases_count 
FROM sessions
LEFT JOIN leads ON leads.visitor_id = sessions.visitor_id
LEFT JOIN vk_ads ON 
    sessions.visit_date = vk_ads.campaign_date AND
    sessions.source = vk_ads.utm_source AND
    sessions.medium = vk_ads.utm_medium AND 
    sessions.campaign = vk_ads.utm_campaign
LEFT JOIN ya_ads ON 
    sessions.visit_date = ya_ads.campaign_date AND
    sessions.source = ya_ads.utm_source AND
    sessions.medium = ya_ads.utm_medium AND 
    sessions.campaign = ya_ads.utm_campaign
    )
    select
	visit_date,
	utm_source,
    utm_medium,
    utm_campaign,
    COUNT(visitor_id) as visitors_count,
    SUM(total_cost) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(amount) as revenue
from tab
group by visit_date, utm_source, utm_medium, utm_campaign
order by visit_date, visitors_count desc,utm_source, utm_medium, utm_campaign

--Убрал NULL

with tab as (
    SELECT
        sessions.visitor_id,
        TO_CHAR(visit_date, 'YYYY-MM-DD') AS visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        lead_id,
        created_at,
        COALESCE(amount, 0) AS amount,  -- Заменяем NULL на ноль для столбца amount
        closing_reason,
        status_id,
        COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
        COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
        COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) as total_cost,
        COALESCE(CASE WHEN closing_reason = 'Успешная продажа' OR status_id = 142 THEN 1 ELSE 0 END, 0) as purchases_count  -- Заменяем NULL на ноль для столбца purchases_count
    FROM sessions
    LEFT JOIN leads ON leads.visitor_id = sessions.visitor_id
    LEFT JOIN vk_ads ON 
        sessions.visit_date = vk_ads.campaign_date AND
        sessions.source = vk_ads.utm_source AND
        sessions.medium = vk_ads.utm_medium AND 
        sessions.campaign = vk_ads.utm_campaign
    LEFT JOIN ya_ads ON 
        sessions.visit_date = ya_ads.campaign_date AND
        sessions.source = ya_ads.utm_source AND
        sessions.medium = ya_ads.utm_medium AND 
        sessions.campaign = ya_ads.utm_campaign
)
SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COUNT(visitor_id) as visitors_count,
    SUM(total_cost) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(amount) as revenue
FROM tab
WHERE utm_medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
GROUP BY visit_date, utm_source, utm_medium, utm_campaign
ORDER BY visit_date, visitors_count DESC, utm_source, utm_medium, utm_campaign;



--Взял условие платного клика из предыдущего шага:
--Клик считается платным для следующих рекламных компаний:

--cpc
--cpm
--cpa
--youtube
--cpp
--tg


with tab as (
SELECT
    sessions.visitor_id,
    TO_CHAR(visit_date, 'YYYY-MM-DD') AS visit_date,
    source AS utm_source,
    medium AS utm_medium,
    campaign AS utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id,
    COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
    COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
    COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) as total_cost,
    case when closing_reason = 'Успешная продажа' or status_id = 142 then 1 end as purchases_count 
FROM sessions
LEFT JOIN leads ON leads.visitor_id = sessions.visitor_id
LEFT JOIN vk_ads ON 
    sessions.visit_date = vk_ads.campaign_date AND
    sessions.source = vk_ads.utm_source AND
    sessions.medium = vk_ads.utm_medium AND 
    sessions.campaign = vk_ads.utm_campaign
LEFT JOIN ya_ads ON 
    sessions.visit_date = ya_ads.campaign_date AND
    sessions.source = ya_ads.utm_source AND
    sessions.medium = ya_ads.utm_medium AND 
    sessions.campaign = ya_ads.utm_campaign
    )
    select
	visit_date,
	utm_source,
    utm_medium,
    utm_campaign,
    COUNT(visitor_id) as visitors_count,
    SUM(total_cost) as total_cost,
    COUNT(lead_id) as leads_count,
    SUM(purchases_count) as purchases_count,
    SUM(amount) as revenue
from tab
where utm_medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
group by visit_date, utm_source, utm_medium, utm_campaign
order by visit_date, visitors_count desc,utm_source, utm_medium, utm_campaign

--Сохраните топ-15 записей по purchases_count в aggregate_last_paid_click.csv

WITH tab AS (
    SELECT
        sessions.visitor_id,
        TO_CHAR(visit_date, 'YYYY-MM-DD') AS visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign,
        lead_id,
        created_at,
        amount,
        closing_reason,
        status_id,
        COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
        COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
        COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) AS total_cost,
        CASE WHEN closing_reason = 'Успешная продажа' OR status_id = 142 THEN 1 ELSE 0 END AS purchases_count 
    FROM sessions
    LEFT JOIN leads ON leads.visitor_id = sessions.visitor_id
    LEFT JOIN vk_ads ON 
        sessions.visit_date = vk_ads.campaign_date AND
        sessions.source = vk_ads.utm_source AND
        sessions.medium = vk_ads.utm_medium AND 
        sessions.campaign = vk_ads.utm_campaign
    LEFT JOIN ya_ads ON 
        sessions.visit_date = ya_ads.campaign_date AND
        sessions.source = ya_ads.utm_source AND
        sessions.medium = ya_ads.utm_medium AND 
        sessions.campaign = ya_ads.utm_campaign
)

SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COUNT(visitor_id) AS visitors_count,
    SUM(total_cost) AS total_cost,
    COUNT(lead_id) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(amount) AS revenue
FROM tab
WHERE utm_medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
GROUP BY visit_date, utm_source, utm_medium, utm_campaign
ORDER BY purchases_count DESC
LIMIT 15;