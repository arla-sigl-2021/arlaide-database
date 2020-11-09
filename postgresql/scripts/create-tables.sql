/**
 * CREATES ARLAIDE DATABASE TABLES
 * 
 */
/**
 * DROP TABLES, if exists to start fresh on every script exec.
 */
DROP TABLE IF EXISTS help_requests CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS locations CASCADE;
DROP TABLE IF EXISTS rewards CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS user_can_work_in CASCADE;
DROP TABLE IF EXISTS user_applies_to CASCADE;
DROP TABLE IF EXISTS user_has_skills CASCADE;
DROP TABLE IF EXISTS hr_has_rewards CASCADE;
/**
 *
 * Create all tables with their attributes
 *
 */

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    city TEXT NOT NULL,
    country TEXT NOT NULL
);

CREATE TABLE users (id SERIAL PRIMARY KEY, username TEXT NOT NULL);

CREATE TABLE help_requests (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    details TEXT,
    location_id INT REFERENCES locations(id) ON DELETE NO ACTION,
    user_id INT REFERENCES users(id) ON DELETE NO ACTION,
    created_at BIGINT NOT NULL CHECK (created_at >= 0)
);

CREATE TABLE rewards (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    currency TEXT NOT NULL
);

CREATE TABLE skills (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    details TEXT NOT NULL
);

CREATE TABLE user_can_work_in (
    user_id INT REFERENCES users(id) ON DELETE NO ACTION,
    location_id INT REFERENCES locations(id) ON DELETE NO ACTION,
    PRIMARY KEY (user_id, location_id)
);

CREATE TABLE user_applies_to (
    user_id INT REFERENCES users(id),
    help_request_id INT REFERENCES help_requests(id),
    applied_at BIGINT NOT NULL CHECK (applied_at >= 0),
    PRIMARY KEY (user_id, help_request_id)
);

CREATE TABLE user_has_skills (
    user_id INT REFERENCES users(id),
    skill_id INT REFERENCES skills(id),
    PRIMARY KEY (user_id, skill_id)
);

CREATE TABLE hr_has_rewards (
    help_request_id INT REFERENCES help_requests(id),
    reward_id INT REFERENCES rewards(id),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    PRIMARY KEY (help_request_id, reward_id)
)