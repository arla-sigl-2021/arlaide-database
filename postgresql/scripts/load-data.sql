COPY users(username)
FROM '/tmp/data/usernames.csv' DELIMITER ',' CSV HEADER;

COPY locations(city,country)
FROM '/tmp/data/locations.csv' DELIMITER ',' CSV HEADER;

COPY help_requests(location_id,created_at,user_id,title,details)
FROM '/tmp/data/help_requests.csv' DELIMITER ';' CSV HEADER;

COPY skills(name,details)
FROM '/tmp/data/skills.csv' DELIMITER ',' CSV HEADER;

COPY rewards(name,currency)
FROM '/tmp/data/rewards.csv' DELIMITER ',' CSV HEADER;

COPY hr_has_rewards(help_request_id,amount,reward_id)
FROM '/tmp/data/has_arlaide_coin_reward.csv' DELIMITER ';' CSV HEADER;

COPY hr_has_rewards(help_request_id,amount,reward_id)
FROM '/tmp/data/has_dollars_reward.csv' DELIMITER ';' CSV HEADER;

COPY user_has_skills(user_id, skill_id)
FROM '/tmp/data/user_has_skills.csv' DELIMITER ';' CSV HEADER;

COPY user_has_skills(user_id,skill_id)
FROM '/tmp/data/user_has_skills_2.csv' DELIMITER ';' CSV HEADER;

COPY user_can_work_in(user_id,location_id)
FROM '/tmp/data/user_can_work_in.csv' DELIMITER ';' CSV HEADER;

COPY user_can_work_in(user_id,location_id)
FROM '/tmp/data/user_can_work_in_2.csv' DELIMITER ';' CSV HEADER;

COPY user_applies_to(user_id,help_request_id,applied_at)
FROM '/tmp/data/user_applies_to.csv' DELIMITER ';' CSV HEADER;

COPY user_applies_to(user_id,help_request_id,applied_at)
FROM '/tmp/data/user_applies_to_2.csv' DELIMITER ';' CSV HEADER;
