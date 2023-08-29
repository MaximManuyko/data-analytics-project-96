-- Создание витрины
--В этом задании построим витрину для модели атрибуции Last Paid Click. Витрина должна содержать следующие данные

--visitor_id — уникальный человек на сайте
--visit_date — время визита
--utm_source / utm_medium / utm_campaign — метки c учетом модели атрибуции
--lead_id — идентификатор лида, если пользователь сконвертился в лид после(во время) визита, NULL — если пользователь не оставил лид
--created_at — время создания лида, NULL — если пользователь не оставил лид
--amount — сумма лида (в деньгах), NULL — если пользователь не оставил лид
--closing_reason — причина закрытия, NULL — если пользователь не оставил лид
--status_id — код причины закрытия, NULL — если пользователь не оставил лид
--Клик считается платным для следующих рекламных компаний:

--cpc
--cpm
--cpa
--youtube
--cpp
--tg
--Требования
--Отсортируйте данные по полям

--visit_date — от ранних к поздним
--utm_source, utm_medium, utm_campaign — в алфавитном порядке

select
	sessions.visitor_id,
	visit_date,
	source AS utm_source,
	medium as utm_medium,
	campaign as utm_campaign,
	lead_id,
	created_at,
	amount,
	closing_reason,
	status_id
from sessions
left join leads
on leads.visitor_id = sessions.visitor_id
where sessions.medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
order by visit_date, source, medium, campaign

-------------

--Напишите запрос для атрибуции лидов по модели Last Paid Click

WITH RankedLeads AS (
    SELECT
        Sessions.Visitor_Id,
        Visit_Date,
        Source AS Utm_Source,
        Medium AS Utm_Medium,
        Campaign AS Utm_Campaign,
        Lead_Id,
        Created_At,
        Amount,
        Closing_Reason,
        Status_Id,
        ROW_NUMBER() OVER (PARTITION BY Lead_Id ORDER BY Visit_Date DESC) AS Rn
    FROM Sessions
    LEFT JOIN Leads ON Sessions.Visitor_Id = Leads.Visitor_Id
    WHERE Sessions.Medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
)
SELECT
    Visitor_Id,
    Visit_Date,
    Utm_Source,
    Utm_Medium,
    Utm_Campaign,
    Lead_Id,
    Created_At,
    Amount,
    Closing_Reason,
    Status_Id
FROM RankedLeads
WHERE Rn = 1;

--Сохраните на Github в файл last_paid_click.csv топ-10 записей по amount
WITH RankedLeads AS (
    SELECT
        Sessions.Visitor_Id,
        Visit_Date,
        Source AS Utm_Source,
        Medium AS Utm_Medium,
        Campaign AS Utm_Campaign,
        Lead_Id,
        Created_At,
        Amount,
        Closing_Reason,
        Status_Id,
        ROW_NUMBER() OVER (PARTITION BY Lead_Id ORDER BY Visit_Date DESC) AS Rn
    FROM Sessions
    LEFT JOIN Leads ON Sessions.Visitor_Id = Leads.Visitor_Id
    WHERE Sessions.Medium IN ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg')
)
SELECT
    Visitor_Id,
    Visit_Date,
    Utm_Source,
    Utm_Medium,
    Utm_Campaign,
    Lead_Id,
    Created_At,
    Amount,
    Closing_Reason,
    Status_Id
FROM RankedLeads
WHERE Rn = 1 AND Amount IS NOT NULL
ORDER BY Amount DESC
LIMIT 10;



