#Project: OTT Merger Analysis
#Author: Gitanjali

# 1. Total Users & Growth Trends

select platform, count(distinct user_id) as total_users 
from subscribers
group by platform;

with cte1 as 
(select 
	platform,
    month(subscription_date) as month,
    count(distinct user_id) as new_users
from subscribers
group by platform, month)

select
	platform,
    month,
    new_users,
    sum(new_users) over (partition by platform order by month) as cumulative_users
from cte1;

#validation
SELECT 
    platform,
    user_id,
    COUNT(DISTINCT subscription_date) AS date_count
FROM subscribers
GROUP BY platform, user_id
HAVING COUNT(DISTINCT subscription_date) > 1;

SELECT *
FROM subscribers
WHERE last_active_date IS NOT NULL
  AND subscription_date > last_active_date;
  
  
# 2. User Demographics

select
	platform,
    age_group,
    city_tier,
    subscription_plan,
    count(distinct user_id) as total_users
from subscribers
group by platform,
    age_group,
    city_tier,
    subscription_plan;
    
# 3. Active vs Inactive Users

with cte1 as
(select 
	user_id,
	platform,
    age_group,
    subscription_plan,
	case
		when last_active_date is null then 'Active' 
        when last_active_date<='2024-11-30' then 'Inactive'
        else 'Exclude'
	end as user_status
	from subscribers
)    
select 
		platform,
		age_group,
		subscription_plan,
        round(count(distinct case when user_status = 'Active' then user_id end)*100/
        count(distinct case when user_status in ('Active','Inactive') then user_id end),2) as active_users_pct,
        
		round(count(distinct case when user_status = 'Inactive' then user_id end)*100/
        count(distinct case when user_status in ('Active','Inactive') then user_id end),2) as inactive_users_pct
from cte1
    where user_status <> 'Exclude'
    group by platform, age_group, subscription_plan;
    
# 4. Watch Time Analysis

select
	cc.platform,
    s.city_tier,
    cc.device_type,
    round(sum(total_watch_time_mins)/count(distinct cc.user_id),2) as avg_watch_time_per_user_mins
from content_consumption cc
join subscribers s
on cc.user_id = s.user_id
where s.last_active_date<='2024-11-30' or s.last_active_date is null 
group by cc.platform, s.city_tier, cc.device_type;

# 5. Inactivity Correlation

with cte1 as
(select
	cc.user_id,
    cc.platform,
    sum(total_watch_time_mins) as total_watch_time_mins,
    max(last_active_date) as last_active_date
from content_consumption cc
join subscribers s
	on s.user_id = cc.user_id
group by cc.platform, cc.user_id),

cte2 as
(select
	user_id,
    platform,
    total_watch_time_mins,
	case
		when last_active_date is null then 'Active' 
        when last_active_date<='2024-11-30' then 'Inactive'
        else 'Exclude'
	end as activity_status
from cte1)

select *
from cte2 
where activity_status <> 'Exclude'
order by total_watch_time_mins;

# 6. Downgrade Trends

with cte1 as
(select
	platform,
    user_id,
    subscription_plan,
    new_subscription_plan,
    case
		when platform='jotstar' and subscription_plan='Free' then 1
        when platform='jotstar' and subscription_plan='VIP' then 2
        when platform='jotstar' and subscription_plan='Premium' then 3
        when platform='liocinema' and subscription_plan='Free' then 1
        when platform='liocinema' and subscription_plan='Basic' then 2
        when platform='liocinema' and subscription_plan='Premium' then 3
	end as old_rank,
    case
		when platform='jotstar' and new_subscription_plan='Free' then 1
        when platform='jotstar' and new_subscription_plan='VIP' then 2
        when platform='jotstar' and new_subscription_plan='Premium' then 3
        when platform='liocinema' and new_subscription_plan='Free' then 1
        when platform='liocinema' and new_subscription_plan='Basic' then 2
        when platform='liocinema' and new_subscription_plan='Premium' then 3
	end as new_rank
    from subscribers
    where new_subscription_plan is not null)

select
platform,
case
	when new_rank < old_rank then 'downgrade'
    else 'upgrade'
end as subscription_trend,
count(distinct user_id) as users
from cte1
group by platform, subscription_trend;

# 7. Upgrade Patterns

with cte1 as
(select
	platform,
    user_id,
    subscription_plan,
    new_subscription_plan,
    case
		when platform='jotstar' and subscription_plan='Free' and
        new_subscription_plan='VIP' then 'Free_to_VIP'
        when platform='jotstar' and subscription_plan='Free' and
        new_subscription_plan='Premium' then 'Free_to_Premium'
        when platform='jotstar' and subscription_plan='VIP' and
        new_subscription_plan='Premium' then 'VIP_to_Premium'
        when platform='liocinema' and subscription_plan='Free' and
        new_subscription_plan='Basic' then 'Free_to_Basic'
        when platform='liocinema' and subscription_plan='Free' and
        new_subscription_plan='Premium' then 'Free_to_Premium'
        when platform='liocinema' and subscription_plan='Basic' and
        new_subscription_plan='Premium' then 'Basic_to_Premium'
	else 'downgrade'
	end as subscription_trend
    from subscribers
    where new_subscription_plan is not null)

select
	platform,
    subscription_trend,
    count(distinct user_id) as users
from cte1
where subscription_trend <> 'downgrade'
group by platform, subscription_trend
order by platform, users;

# 8. Paid Users Distribution

with cte1 as 
(select
	user_id,
    platform,
    city_tier,
    case
		when platform = 'jotstar' and
        subscription_plan in ('VIP', 'Premium') then 'Paid'
        when platform = 'liocinema' and
        subscription_plan in ('Basic', 'Premium') then 'Paid'
        else 'Free'
	end as user_category
from subscribers)

select
	platform,
    city_tier,
    round(count(distinct case when user_category = 'Paid' then user_id end)*100/
    count(distinct user_id),2) as paid_user_pct,
    round(count(distinct case when user_category = 'Free' then user_id end)*100/
    count(distinct user_id),2) as free_user_pct
from cte1
group by platform, city_tier
order by platform, city_tier;
