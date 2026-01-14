-- Migration script to transform old schema to new schema
-- This will migrate from task column to title/description columns
USE task_management;

-- Add title column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'title');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN title VARCHAR(255) NOT NULL DEFAULT ''Task'' AFTER user_id',
    'SELECT "title column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add description column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'description');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN description TEXT AFTER title',
    'SELECT "description column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add priority column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'priority');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN priority ENUM(''low'', ''medium'', ''high'') DEFAULT ''medium'' AFTER description',
    'SELECT "priority column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add status column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'status');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN status ENUM(''pending'', ''completed'') DEFAULT ''pending'' AFTER priority',
    'SELECT "status column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migrate data from old 'task' column to new 'title' column (only if task column exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'task');

SET @query = IF(@col_exists = 1,
    'UPDATE tasks SET title = task WHERE task IS NOT NULL AND title = ''Task''',
    'SELECT "task column does not exist, skipping data migration" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migrate completed status from old completed column to new status column (only if completed column exists)
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'completed');

SET @query = IF(@col_exists = 1,
    'UPDATE tasks SET status = IF(completed = 1, ''completed'', ''pending'') WHERE completed IS NOT NULL',
    'SELECT "completed column does not exist, skipping status migration" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Set description to empty string where null
UPDATE tasks SET description = '' WHERE description IS NULL;

-- Add created_at column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'created_at');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER due_date',
    'SELECT "created_at column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add updated_at column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'updated_at');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE tasks ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    'SELECT "updated_at column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop old columns after migration
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'task');

SET @query = IF(@col_exists = 1,
    'ALTER TABLE tasks DROP COLUMN task',
    'SELECT "task column already dropped" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop completed column
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'tasks' 
                   AND COLUMN_NAME = 'completed');

SET @query = IF(@col_exists = 1,
    'ALTER TABLE tasks DROP COLUMN completed',
    'SELECT "completed column already dropped" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add indexes for better performance (ignore errors if they exist)
SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = 'task_management' 
                     AND TABLE_NAME = 'tasks' 
                     AND INDEX_NAME = 'idx_user_tasks');

SET @query = IF(@index_exists = 0,
    'CREATE INDEX idx_user_tasks ON tasks(user_id, created_at)',
    'SELECT "idx_user_tasks already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = 'task_management' 
                     AND TABLE_NAME = 'tasks' 
                     AND INDEX_NAME = 'idx_user_status');

SET @query = IF(@index_exists = 0,
    'CREATE INDEX idx_user_status ON tasks(user_id, status)',
    'SELECT "idx_user_status already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = 'task_management' 
                     AND TABLE_NAME = 'tasks' 
                     AND INDEX_NAME = 'idx_user_priority');

SET @query = IF(@index_exists = 0,
    'CREATE INDEX idx_user_priority ON tasks(user_id, priority)',
    'SELECT "idx_user_priority already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = 'task_management' 
                     AND TABLE_NAME = 'tasks' 
                     AND INDEX_NAME = 'idx_due_date');

SET @query = IF(@index_exists = 0,
    'CREATE INDEX idx_due_date ON tasks(due_date)',
    'SELECT "idx_due_date already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update users table - add created_at column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'users' 
                   AND COLUMN_NAME = 'created_at');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER email',
    'SELECT "created_at column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update users table - add email column if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'users' 
                   AND COLUMN_NAME = 'email');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN email VARCHAR(100) AFTER password',
    'SELECT "email column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add updated_at to users table if it doesn't exist
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'task_management' 
                   AND TABLE_NAME = 'users' 
                   AND COLUMN_NAME = 'updated_at');

SET @query = IF(@col_exists = 0,
    'ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER created_at',
    'SELECT "updated_at column already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index to users table
SET @index_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS 
                     WHERE TABLE_SCHEMA = 'task_management' 
                     AND TABLE_NAME = 'users' 
                     AND INDEX_NAME = 'idx_username');

SET @query = IF(@index_exists = 0,
    'CREATE INDEX idx_username ON users(username)',
    'SELECT "idx_username already exists" as status');

PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Migration completed successfully!' as status;
