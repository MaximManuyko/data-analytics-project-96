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

WITH RankedLeads AS (
    SELECT
        Sessions.Visitor_Id,
        TO_CHAR(Visit_Date, 'YYYY-MM-DD') AS Visit_Date,
        Source AS Utm_Source,
        Medium AS Utm_Medium,
        Campaign AS Utm_Campaign,
        Lead_Id,
        Created_At,
        Amount,
        Closing_Reason,
        Status_Id,
        COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
        COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
        COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) as total_cost,
        case when closing_reason = 'Успешная продажа' or status_id = 142 then 1 end as purchases_count,
        ROW_NUMBER() OVER (PARTITION BY Lead_Id ORDER BY Visit_Date DESC) AS Rn
    FROM Sessions
    LEFT JOIN Leads 
    ON Sessions.Visitor_Id = Leads.Visitor_Id
	LEFT JOIN vk_ads ON 
    	sessions.visit_date = vk_ads.campaign_date AND
    	sessions.source = vk_ads.utm_source AND
    	sessions.medium = vk_ads.utm_medium AND 
    	sessions.campaign = vk_ads.utm_campaign and
    	Sessions.content =  vk_ads.utm_content 
	LEFT JOIN ya_ads ON 
    	sessions.visit_date = ya_ads.campaign_date AND
    	sessions.source = ya_ads.utm_source AND
    	sessions.medium = ya_ads.utm_medium AND 
    	sessions.campaign = ya_ads.utm_campaign and
    	Sessions.content = ya_ads.utm_content
    WHERE Sessions.Medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
),
	"RankedLeads_1" as (
		select *
		from RankedLeads
		where Rn = 1
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
FROM "RankedLeads_1"
group by visit_date, utm_source, utm_medium, utm_campaign
order by visit_date, visitors_count desc,utm_source, utm_medium, utm_campaign;

--Создайте напишите для агрегации данных из модели атрибуции Last Paid Click aggregate_last_paid_click.sql
--Сохраните топ-15 записей по purchases_count в aggregate_last_paid_click.csv

WITH RankedLeads AS (
    SELECT
        Sessions.Visitor_Id,
        TO_CHAR(Visit_Date, 'YYYY-MM-DD') AS Visit_Date,
        Source AS Utm_Source,
        Medium AS Utm_Medium,
        Campaign AS Utm_Campaign,
        Lead_Id,
        Created_At,
        Amount,
        Closing_Reason,
        Status_Id,
        COALESCE(vk_ads.daily_spent, 0) AS vk_ads_daily_spent,
        COALESCE(ya_ads.daily_spent, 0) AS ya_ads_daily_spent,
        COALESCE(vk_ads.daily_spent, 0) + COALESCE(ya_ads.daily_spent, 0) as total_cost,
        case when closing_reason = 'Успешная продажа' or status_id = 142 then 1 end as purchases_count,
        ROW_NUMBER() OVER (PARTITION BY Lead_Id ORDER BY Visit_Date DESC) AS Rn
    FROM Sessions
    LEFT JOIN Leads 
    ON Sessions.Visitor_Id = Leads.Visitor_Id
	LEFT JOIN vk_ads ON 
    	sessions.visit_date = vk_ads.campaign_date AND
    	sessions.source = vk_ads.utm_source AND
    	sessions.medium = vk_ads.utm_medium AND 
    	sessions.campaign = vk_ads.utm_campaign and
    	Sessions.content =  vk_ads.utm_content 
	LEFT JOIN ya_ads ON 
    	sessions.visit_date = ya_ads.campaign_date AND
    	sessions.source = ya_ads.utm_source AND
    	sessions.medium = ya_ads.utm_medium AND 
    	sessions.campaign = ya_ads.utm_campaign and
    	Sessions.content = ya_ads.utm_content
    WHERE Sessions.Medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
),
	"RankedLeads_1" as (
		select *
		from RankedLeads
		where Rn = 1
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
FROM "RankedLeads_1"
group by visit_date, utm_source, utm_medium, utm_campaign
ORDER BY purchases_count DESC NULLS last
limit 15;