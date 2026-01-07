#Project: OTT Merger Analysis
#Author: Gitanjali

# 1. Content Library Comparison

SELECT 
	platform,
    content_type,
    language,
    count(distinct content_id) as total_no_of_contents
    FROM ott_merger_db.contents
    group by platform, content_type, language;
    
# 2. Revenue Analysis

with subscription_timeline as
(select
	s.user_id,
    s.platform,
    s.subscription_plan as plan,
    s.subscription_date,
    case
		when s.plan_change_date is not null and s.plan_change_date <= '2024-11-30'
        then date_sub(s.plan_change_date, interval 1 day)
        else '2024-11-30'
	end as plan_end_date
	from subscribers s),
    
original_plan as
(select
	t.platform,
    t.user_id,
    t.plan,
    timestampdiff(
		month,
        t.subscription_date,
        t.plan_end_date) + 1 as active_months,
	p.monthly_price_inr as monthly_price
from subscription_timeline t
join monthly_subscription_prices p
	on t.platform = p.platform and
		t.plan = p.subscription_plan),
        
new_plan as
(select	
	s.platform,
    s.user_id,
    s.new_subscription_plan as plan,
    timestampdiff(
		month,
        least(s.plan_change_date, '2024-11-30'),
        '2024-11-30') + 1 as active_months,
	p.monthly_price_inr as monthy_price
from subscribers s
join monthly_subscription_prices p
	on s.platform = p.platform and
		s.new_subscription_plan = p.subscription_plan
where s.new_subscription_plan is not null) 
        
select
	user_id,
	platform,
    plan,
    active_months,
    monthly_price,
    monthly_price * active_months as revenue
from
	(
    select * from original_plan
    union all
    select * from new_plan
    ) u;
    
# 3. User Status

select 
	user_id,
	platform,
    age_group,
    city_tier,
    subscription_plan,
	case
		when last_active_date is null then 'Active' 
        when last_active_date<='2024-11-30' then 'Inactive'
        else 'Exclude'
	end as user_status
	from subscribers;
    
# 4. User Plan Distribution

select
	user_id,
    platform,
    case
		when platform = 'jotstar' and
        subscription_plan in ('VIP', 'Premium') then 'Paid'
        when platform = 'liocinema' and
        subscription_plan in ('Basic', 'Premium') then 'Paid'
        else 'Free'
	end as user_category
from subscribers;

# 5. Top City, Age, Plan by Revenue

with cte1 as (select 
	r.platform,
    r.plan,
    s.age_group,
    s.city_tier,
    r.revenue
    from revenue_per_user r
    join subscribers s
    on r.user_id = s.user_id)

select 
	plan,
    sum(revenue),
    rank() over (order by sum(revenue) desc) as rnk
    from cte1
    group by plan