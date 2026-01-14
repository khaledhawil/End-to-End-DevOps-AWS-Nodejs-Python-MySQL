-- Migration script to update existing database schema
-- Run this if you already have the database set up

USE task_manager;

-- Add title column if it doesn't exist (CRITICAL FIX)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_manager' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'title');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN title VARCHAR(255) NOT NULL AFTER user_id',
    'SELECT "title column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add priority column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_manager' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'priority');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN priority ENUM(''low'', ''medium'', ''high'') DEFAULT ''medium'' AFTER description',
    'SELECT "priority column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add due_date column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_manager' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'due_date');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN due_date DATE AFTER status',
    'SELECT "due_date column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add updated_at to users table if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_manager' 
                   AND TABLE_NAME = 'users' 
                   AND COLUMN_NAME = 'updated_at');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    'SELECT "updated_at column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add email column to users if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_manager' 
                   AND TABLE_NAME = 'users' 
                   AND COLUMN_NAME = 'email');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN email VARCHAR(100) AFTER password',
    'SELECT "email column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add indexes for better performance (they won't be created if they exist)
CREATE INDEX IF NOT EXISTS idx_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_user_status ON tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_user_priority ON tasks(user_id, priority);
CREATE INDEX IF NOT EXISTS idx_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_user_tasks ON tasks(user_id, created_at);

SELECT 'Migration completed successfully!' as status;
