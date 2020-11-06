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
DROP TABLE IF EXISTS can_work_in CASCADE;
DROP TABLE IF EXISTS create_request CASCADE;
DROP TABLE IF EXISTS applies_to CASCADE;
DROP TABLE IF EXISTS has_skills CASCADE;
DROP TABLE IF EXISTS has_reward CASCADE;
/**
 *
 * Create all tables with their attributes
 *
 */

CREATE TABLE locations (
    id INT PRIMARY KEY,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL
);
CREATE TABLE help_requests (
    id INT PRIMARY KEY,
    title TEXT NOT NULL,
    details TEXT NOT NULL,
    location_id INT REFERENCES locations(id) ON DELETE NO ACTION
);
CREATE TABLE users (id INT PRIMARY KEY, username TEXT NOT NULL);
CREATE TABLE rewards (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    currency TEXT NOT NULL
);
CREATE TABLE skills (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    details TEXT NOT NULL
);
CREATE TABLE can_work_in (
    user_id INT REFERENCES users(id) ON DELETE NO ACTION,
    location_id INT REFERENCES locations(id) ON DELETE NO ACTION,
    PRIMARY KEY (user_id, location_id)
);
CREATE TABLE create_request (
    user_id INT REFERENCES users(id),
    help_request_id INT REFERENCES help_requests(id),
    timestamp BIGINT NOT NULL CHECK (timestamp >= 0),
    PRIMARY KEY (user_id, help_request_id)
);
CREATE TABLE applies_to (
    user_id INT REFERENCES users(id),
    help_request_id INT REFERENCES help_requests(id),
    timestamp BIGINT NOT NULL CHECK (timestamp >= 0),
    PRIMARY KEY (user_id, help_request_id)
);
CREATE TABLE has_skills (
    user_id INT REFERENCES users(id),
    skill_id INT REFERENCES skills(id),
    PRIMARY KEY (user_id, skill_id)
);
CREATE TABLE has_reward (
    help_request_id INT REFERENCES help_requests(id),
    reward_id INT REFERENCES rewards(id),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    PRIMARY KEY (help_request_id, reward_id)
)