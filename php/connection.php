<?php
// Database configuration
define('DB_PATH', '/var/www/db/app.db');
define('DB_TIMEOUT', 5); // Connection timeout in seconds

try {
    // Establish database connection with error handling
    $db = new SQLite3(DB_PATH, SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE, '');
    
    // Set connection parameters
    $db->busyTimeout(DB_TIMEOUT * 1000); // Convert to milliseconds
    $db->enableExceptions(true); // Enable exceptions for better error handling
    
    // Optimize database performance
    $db->exec('PRAGMA journal_mode = WAL');
    $db->exec('PRAGMA synchronous = NORMAL');
    $db->exec('PRAGMA temp_store = MEMORY');
    
    // Verify connection
    if (!$db) {
        throw new Exception('Failed to connect to database');
    }
    
} catch (Exception $e) {
    // Log error securely (don't expose details to users)
    error_log('Database connection error: ' . $e->getMessage());
    
    // Show user-friendly message
    die('System maintenance in progress. Please try again later.');
}

// Register shutdown function to ensure proper connection closing
register_shutdown_function(function() use ($db) {
    if ($db instanceof SQLite3) {
        $db->close();
    }
});
?>