#Project: OTT Merger Analysis
#Author: Gitanjali

#Creating a single database for both platforms

create database ott_merger_db;
use ott_merger_db;

create table ott_merger_db.jotstar_content_consumption
select * from jotstar_db.jotstar_content_consumption;

create table ott_merger_db.jotstar_contents
select * from jotstar_db.jotstar_contents;

create table ott_merger_db.jotstar_subscribers
select * from jotstar_db.jotstar_subscribers;

create table ott_merger_db.lio_content_consumption
select * from liocinema_db.content_consumption;

create table ott_merger_db.lio_contents
select * from liocinema_db.contents;

create table ott_merger_db.lio_subscribers
select * from liocinema_db.subscribers;

#basic data validation

select count(*) from jotstar_content_consumption;
select count(*) from lio_content_consumption;
select count(distinct user_id) from jotstar_subscribers;
select count(distinct user_id) from lio_subscribers;
select distinct content_type from jotstar_contents;
select distinct content_type from lio_contents;
select distinct genre from jotstar_contents;
select distinct genre from lio_contents;
select min(subscription_date), max(subscription_date)
from jotstar_subscribers;
select min(subscription_date), max(subscription_date)
from lio_subscribers;

#unified view

select *, 'jotstar' as platform from jotstar_subscribers
union
select *, 'liocinema' as platform from lio_subscribers;