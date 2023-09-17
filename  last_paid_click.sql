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
--social

--Требования
--Отсортируйте данные по полям

--amount — от большего к меньшему, null записи идут последними
--visit_date — от ранних к поздним
--utm_source, utm_medium, utm_campaign — в алфавитном порядке

--Код удаляет delete через создание WITH
with tab as (
    select
        sessions.visitor_id,
        visit_date,
        source,
        medium,
        campaign,
        created_at,
        amount,
        closing_reason,
        status_id,
        case
            when created_at < visit_date then 'delete' else lead_id
        end as lead_id,
        ROW_NUMBER()
            over (partition by sessions.visitor_id order by visit_date desc)
        as rn
    from sessions
    left join leads
        on sessions.visitor_id = leads.visitor_id
    where medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
)

select
    tab.visitor_id,
    tab.visit_date,
    tab.source as utm_source,
    tab.medium as utm_medium,
    tab.campaign as utm_campaign,
    case
        when tab.created_at < tab.visit_date then 'delete' else lead_id
    end as lead_id,
    tab.created_at,
    tab.amount,
    tab.closing_reason,
    tab.status_id
from tab
where (tab.lead_id != 'delete' or tab.lead_id is null) and tab.rn = 1
order by
    tab.amount desc nulls last,
    tab.visit_date asc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
    

