--1. Rank bikes by how heavily they are used for June 2017, by user count, and by trip count
--By user count 
SELECT completed_trips.bike_id, count(1)
FROM (SELECT bike_id,
             user_id,
             row_number() OVER(PARTITION BY bike_id, user_id ORDER BY started_at DESC) AS row_num
      FROM  trips
      WHERE trip.status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6) completed_trips
WHERE completed_trips.row_num = 1
GROUP BY completed_trips.bike_id 
ORDER BY count(1) DESC

--By trip count 
SELECT bike_id, count(1)
FROM trips
WHERE status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6
GROUP BY bike_id
ORDER BY count(1) DESC

--2. Calculate per region aggregated usage stats on a specific promotion named
--‘TestPromo’. How many users, how many trips for each region. And how many
--percentage of the usage are in the first day of the promotion.
CREATE TABLE per_region_aggregated_usage AS
SELECT trips.region_id,
        count(DISTINCT trips.user_id) AS user_num,
        count(trips.user_id) AS trip_num
FROM trips 
JOIN coupons 
ON trips.coupon_id = coupons.id
JOIN (SELECT * FROM promotions WHERE promotion_name = 'TestPromo') test_promo
ON coupons.promotion_id = test_promo.id
WHERE trips.status = 'completed'
GROUP BY trips.region_id

CREATE TABLE pre_region_first_day_usage AS
SELECT trips.region_id,
        count(distinct trips.user_id) AS first_user_num,
        count(trips.user_id) AS first_trip_num
FROM trips 
JOIN coupons 
ON trips.coupon_id = coupons.id
JOIN (SELECT * FROM promotions WHERE promotion_name = 'TestPromo') test_promo
ON coupons.promotion_id = test_promo.id
WHERE trips.status = 'completed' AND trips.completed_at = test_promo.start_at
GROUP BY trips.region_id

CREATE TABLE percent_usage AS 
SELECT region_id,
       first_user_num/user_num AS user_percentage,
	   first_trip_num/trip_num AS trip_percentage
FROM per_region_aggregated_usage a
JOIN pre_region_first_day_usage b 
ON a.region_id = b.region_id

--3. Generate a table to store for each user, what is his/her last used bike, and what is
--his/her last used coupon
SELECT a.user_id, 
       a.bike_id, 
       a.coupon_id
FROM (SELECT users.id AS user_id, trips.bike_id, trips.coupon_id
	   row_number() OVER (PARTITION BY users.id, ORDER BY trips.completed_at DESC) AS row_num 
	 FROM users 
	 JOIN trips 
	 ON users.id = trips.user_id) a
WHERE a.row_num = 1

--4. From trips and users, generate a user daily spent table that has following columns:
--date,user_id, begin_balance, spent_amount_cents, num_trips
CREATE TABLE user_daily_spent(
    user_id INT(11) PRIMARY KEY AUTO_INCREMENT, 
    begin_balance INT(11) DEFAULT 0,
    spent_amount_cents INT(11),
    num_trips INT(11)
)
PARTITION BY (date datetime) 
ROW format delimited fields terminated BY '\1';

--assume today is 2017-06-01, we can modify this date with the real date from machine
INSERT overwrite TABLE user_daily_spent PARTITION (date = 2017-06-01)
SELECT users.user_id,
       sum(cost_amount_cents) AS begin_balance,
	   sum(cost_amount_cents) AS spent_amount_cents,
	   count(1) AS num_trips
FROM users 
JOIN (SELECT * FROM trips WHERE status = 'completed' AND completed_at = 2017-06-01) completed_trips
ON users.id = completed_trips.user_id
GROUP BY users.user_id


--5. how much is gross revenue (sum of all trips completed in that month by cost_amount_cents), 
--net revenue (gross - refund), number of active users, number of trips, number of active bikes.
--one user might complete more than 1 trip in 2017/06, 需要去重
CREATE TABLE active_users AS 
SELECT completed_trips.user_id AS id
FROM (SELECT user_id,
             row_number() OVER(PARTITION BY user_id) AS row_num
      FROM  trips
      WHERE trip.status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6) completed_trips
WHERE completed_trips.row_num = 1
--this is a list of active users --> users who complete at least 1 trip in 2017/06

CREATE TABLE active_bikes AS 
SELECT completed_trips.bike_id AS id
FROM (SELECT bike_id,
             row_number() OVER(PARTITION BY bike_id ORDER BY created_at) AS row_num
      FROM  trips
      WHERE trip.status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6) completed_trips
WHERE completed_trips.row_num = 1

SELECT sum(cost_amount_cents) AS gross_revenue, 
       sum(cost_amount_cents) - sum(refunded_amount_cents) AS net_revenue, 
       count(1) AS trip_num,
       (SELECT count(1) FROM active_users) AS active_users_num, 
       (SELECT count(1) FROM active_bikes) AS active_bikes_num
FROM trips 
RIGHT JOIN active_users 
ON trips.user_id = active_users.id
RIGHT JOIN active_bikes
ON trips.bike_id = active_bikes.id
GROUP BY trips.region_id

--6. four metrics: 
--growth of revenue
--growth of profit 
--growth of bike usage by trip count
--growth of new users
--from 2016/06 to 2017/06 and May to June
--assume we have data for 2016/06

WITH data_17(mm, gross_revenue, net_revenue) AS (
    SELECT month(t.completed_at), 
       sum(t.cost_amount_cents), 
       sum(t.cost_amount_cents) - sum(t.refunded_amount_cents)
    FROM trips t
    WHERE t.status = 'completed' AND year(t.completed_at) = 2017
    GROUP BY month(t.completed_at)
)
SELECT data_17.mm Year, 
       data_17.gross_revenue GrossRevenue_17,
       data_17.net_revenue NetRevenue_17, 
       cast((data_17.gross_revenue - sum(t.cost_amount_cents) / data_17.gross_revenue) AS DECIMAL(3,2)) Percent_Growth_Gross,
       cast((data_17.net_revenue - (sum(t.cost_amount_cents) - sum(t.refunded_amount_cents)) / data_17.net_revenue) AS DECIMAL(3,2)) Percent_Growth_Net,
FROM trips t
JOIN data_17 
ON year(t.completed_at) = 2017 AND month(t.completed_at) = data_17.mm - 1
GROUP BY mm, data_17.gross_revenue, data_17.net_revenue
ORDER BY mm DESC
/* SELECT data_17.mm Year, 
       data_17.gross_revenue GrossRevenue_17,
       data_17.net_revenue NetRevenue_17, 
       sum(prev.cost_amount_cents) GrossRevenue_16, 
       sum(prev.cost_amount_cents) - sum(prev.refunded_amount_cents) NetRevenue_16, 
       cast((data_17.gross_revenue - sum(prev.cost_amount_cents) / data_17.gross_revenue) AS DECIMAL(3,2)) Percent_Growth_Gross, 
       cast((data_17.net_revenue - (sum(prev.cost_amount_cents) - sum(prev.refunded_amount_cents)) / data_17.net_revenue) AS DECIMAL(3,2)) Percent_Growth_Net, 
FROM trips
JOIN data_17 
ON year(trips.completed_at) = 2016 AND month(trips.completed_at) = data_17.mm 
GROUP BY mm
ORDER BY mm DESC */
--generate a monthly report for 2017 


CREATE TABLE data_16_17 AS 
SELECT (SELECT sum(cost_amount_cents) AS gross_revenue_16, 
               sum(cost_amount_cents) - sum(refunded_amount_cents) AS net_revenue_16, 
        FROM trips 
        WHERE status = completed AND year(completed_at) = 2016 AND month(completed_at) = 6),
        (SELECT sum(cost_amount_cents) AS gross_revenue_17, 
               sum(cost_amount_cents) - sum(refunded_amount_cents) AS net_revenue_17, 
        FROM trips 
        WHERE status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6),

       (SELECT sum(a.usage_per_bike) 
        FROM (SELECT count(1) AS usage_per_bike 
                FROM trips
                WHERE status = completed AND year(completed_at) = 2016 AND month(completed_at) = 6
                GROUP BY bike_id) a) AS bike_usage_16, 
        (SELECT sum(a.usage_per_bike) 
        FROM (SELECT count(1) AS usage_per_bike 
                FROM trips
                WHERE status = completed AND year(completed_at) = 2017 AND month(completed_at) = 6
                GROUP BY bike_id) a) AS bike_usage_17, 
        
       (SELECT count(1) 
        FROM users 
        WHERE year(users.created_at) = 2016 AND month(users.created_at) = 6) AS new_users_16, 
        (SELECT count(1) 
        FROM users 
        WHERE year(users.created_at) = 2017 AND month(users.created_at) = 6) AS new_users_17

CREATE TABLE difference_16_17 AS 
SELECT gross_revenue_17 - gross_revenue_16 AS diff_revenue, 
       net_revenue_17 - net_revenue_16 AS diff_profit,
       bike_usage_17 - bike_usage_16 AS diff_bike_usage, 
       new_users_17 - new_users_16 AS diff_new_users
FROM data_16_17

--6.Cohort analysis on users churn rate. 
--cohort: number of trips per day
SELECT year(completed_at) AS 'year',
       month(completed_at) AS 'month',
       day(completed_at) AS 'day',
       count(1) AS trip_num
FROM trips
GROUP BY day(completed_at), month(completed_at), year(completed_at)
ORDER BY 'year' DESC, 'month' DESC, 'day' DESC
