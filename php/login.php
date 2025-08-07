<?php
session_start();

// Define constants for configuration
define('MAX_LOGIN_ATTEMPTS', 5);
define('LOGIN_LOCKOUT_TIME', 300); // 5 minutes in seconds

// Handle login attempt
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        $db = new SQLite3('/var/www/db/app.db');
        
        // Check for brute force attempts
        if (!empty($_SESSION['login_attempts']) && $_SESSION['login_attempts'] >= MAX_LOGIN_ATTEMPTS) {
            $lockout_remaining = LOGIN_LOCKOUT_TIME - (time() - $_SESSION['last_login_attempt']);
            
            if ($lockout_remaining > 0) {
                $error = sprintf(
                    "Too many failed attempts. Please try again in %d minutes.", 
                    ceil($lockout_remaining / 60)
                );
            } else {
                // Reset attempt counter after lockout period expires
                $_SESSION['login_attempts'] = 0;
            }
        }

        if (!isset($error)) {
            $stmt = $db->prepare('SELECT * FROM users WHERE username = :username');
            $stmt->bindValue(':username', trim($_POST['username']), SQLITE3_TEXT);
            $result = $stmt->execute();
            $user = $result->fetchArray(SQLITE3_ASSOC);

            if ($user && password_verify($_POST['password'], $user['password'])) {
                // Successful login
                session_regenerate_id(true); // Prevent session fixation
                $_SESSION["user"] = $user['username'];
                $_SESSION["last_activity"] = time();
                
                // Reset login attempts on success
                unset($_SESSION['login_attempts']);
                unset($_SESSION['last_login_attempt']);
                
                header("Location: /dashboard.php");
                exit();
            } else {
                // Failed login
                $_SESSION['login_attempts'] = isset($_SESSION['login_attempts']) ? $_SESSION['login_attempts'] + 1 : 1;
                $_SESSION['last_login_attempt'] = time();
                $error = "Invalid username or password";
            }
        }
    } catch (Exception $e) {
        error_log("Login error: " . $e->getMessage());
        $error = "A system error occurred. Please try again later.";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .login-container {
            background-color: white;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 400px;
        }
        .login-container h2 {
            text-align: center;
            margin-bottom: 1.5rem;
            color: #333;
        }
        .form-group {
            margin-bottom: 1rem;
        }
        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: bold;
        }
        .form-group input {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }
        .form-group input:focus {
            border-color: #007bff;
            outline: none;
        }
        .btn {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 4px;
            cursor: pointer;
            width: 100%;
            font-size: 1rem;
        }
        .btn:hover {
            background-color: #0056b3;
        }
        .error-message {
            color: #dc3545;
            margin-bottom: 1rem;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <h2>Login</h2>
        
        <?php if (isset($error)): ?>
            <div class="error-message"><?php echo htmlspecialchars($error); ?></div>
        <?php endif; ?>
        
        <form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>">
            <div class="form-group">
                <label for="username">Username</label>
                <input type="text" id="username" name="username" required autocomplete="username">
            </div>
            
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" id="password" name="password" required autocomplete="current-password">
            </div>
            
            <button type="submit" class="btn">Login</button>
        </form>
    </div>
</body>
</html>