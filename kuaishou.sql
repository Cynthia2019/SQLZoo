--1. Rank bikes by how heavily they are used for June 2017, by user count, and by trip count
select bike_id,count(1)
from (select bike_id,
            user_id,
            row_number() over(partition by bike_id, user_id order by started_at desc) as rn
from  trips
where status=completed) a
where a.rn = 1
group by bike_id 
order by count(1) desc
--一个user会用一个bike多次，所以要去重user，order user然后选第一个

SELECT bike_id, COUNT(*) FROM trips
GROUP BY bike_id
ORDER BY COUNT(*) DESC

SELECT bike.plate_number as Bike, COUNT(*) FROM trips
JOIN bikes ON bikes.id = trips.bike_id
GROUP BY bike_id
ORDER BY COUNT(*) DESC

--2. Calculate per region aggregated usage stats on a specific promotion named
--‘TestPromo’. How many users, how many trips for each region. And how many
--percentage of the usage are in the first day of the promotion.
--should I use distinct here? 
SELECT region.name, 
COUNT(DISTINCT user_id) as Users, 
COUNT(trips.id) as Trips, 
((SELECT COUNT(coupons.id) FROM coupons WHERE consumed_at = '2017-06-01') * 100 / (SELECT COUNT(*) FROM coupons)) as Percent_Usage, 
FROM region
JOIN trips ON region.id = trips.region_id
JOIN coupons ON coupons.id = trips.coupon_id
WHERE coupon_id IN (
    SELECT id FROM coupons 
    WHERE id IN (
        SELECT id FROM promotions 
        WHERE promotion_name = 'TestPromo'
    )
)
GROUP BY region_id 


select region_id, count(distinct user_id) as Users, count(user_id) as Trips
from trips a
join coupons b
on a.coupon_id = b.id
join (select * from promotions where promotion_name = 'TestPromo') c
on b.promotion_id = c.id
where a.status = 'completed'
group by region_id
--assume the first day of promotion is 01/06/2017 and the datetime is formatted as YYYY-MM-DD

--3. Generate a table to store for each user, what is his/her last used bike, and what is
--his/her last used coupon

CREATE TABLE users_last {
    user_id INT(11) AUTO_INCREMENT PRIMARY KEY,
    bike_last_id INT(11), 
    coupon_last_id INT(11)
}

--4. From trips and users, generate a user daily spent table that has following columns:
--date,user_id, begin_balance, spent_amount_cents, num_trips
--what is the primary key here? 

SELECT users.id, CAST(trips.started_at AS DATE), 

CREATE TABLE user_daily_spent {
    date datetime NOT NULL, 
    user_id INT(11) AUTO_INCREMENT PRIMARY KEY,
    begin_balance INT(11) DEFAULT 0 NOT NULL; 
    spent_amount_cents INT(11) 
}

--5. 