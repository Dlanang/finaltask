<?php
session_start();

// Redirect to login if not authenticated
if (!isset($_SESSION["user"])) {
    header("Location: /login.php");
    exit();
}

// Security headers
header("X-Frame-Options: SAMEORIGIN");
header("X-Content-Type-Options: nosniff");
header("Referrer-Policy: strict-origin-when-cross-origin");

// Auto-logout after 30 minutes of inactivity
$inactive = 1800; // 30 minutes in seconds
if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > $inactive)) {
    session_unset();
    session_destroy();
    header("Location: /login.php?timeout=1");
    exit();
}
$_SESSION['last_activity'] = time();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monitoring Dashboard | <?php echo htmlspecialchars($_SESSION["user"]); ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --primary-color: #4361ee;
            --secondary-color: #3f37c9;
            --accent-color: #4cc9f0;
            --dark-color: #1a1a2e;
            --light-color: #f8f9fa;
            --success-color: #4bb543;
            --warning-color: #fca311;
            --danger-color: #e63946;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f5f7fa;
            color: #333;
        }
        
        .dashboard-container {
            display: grid;
            grid-template-rows: auto 1fr;
            min-height: 100vh;
        }
        
        .navbar {
            background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
            color: white;
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        
        .navbar-brand {
            font-size: 1.5rem;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .user-menu {
            display: flex;
            align-items: center;
            gap: 20px;
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background-color: var(--accent-color);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }
        
        .logout-btn {
            background-color: var(--danger-color);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s;
        }
        
        .logout-btn:hover {
            background-color: #c1121f;
        }
        
        .main-content {
            padding: 2rem;
        }
        
        .dashboard-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
        }
        
        .dashboard-title {
            font-size: 1.8rem;
            color: var(--dark-color);
            margin: 0;
        }
        
        .streamlit-container {
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
            background: white;
            height: calc(100vh - 200px);
        }
        
        .streamlit-container iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
        
        .status-bar {
            display: flex;
            justify-content: space-between;
            margin-top: 1rem;
            font-size: 0.9rem;
            color: #666;
        }
        
        @media (max-width: 768px) {
            .navbar {
                flex-direction: column;
                padding: 1rem;
                gap: 10px;
            }
            
            .dashboard-header {
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="dashboard-container">
        <nav class="navbar">
            <div class="navbar-brand">
                <i class="fas fa-chart-line"></i>
                <span>Monitoring Dashboard</span>
            </div>
            <div class="user-menu">
                <div class="user-info">
                    <div class="avatar"><?php echo strtoupper(substr($_SESSION["user"], 0, 1)); ?></div>
                    <span><?php echo htmlspecialchars($_SESSION["user"]); ?></span>
                </div>
                <a href="/logout.php" class="logout-btn">
                    <i class="fas fa-sign-out-alt"></i> Logout
                </a>
            </div>
        </nav>
        
        <div class="main-content">
            <div class="dashboard-header">
                <h1 class="dashboard-title">Real-time Monitoring</h1>
                <div class="last-update">Last refreshed: <?php echo date("Y-m-d H:i:s"); ?></div>
            </div>
            
            <div class="streamlit-container">
                <iframe src="http://localhost:8501" title="Streamlit Application"></iframe>
            </div>
            
            <div class="status-bar">
                <div class="session-info">
                    Session active since: <?php echo date("Y-m-d H:i:s", $_SESSION['last_activity']); ?>
                </div>
                <div class="system-status">
                    <i class="fas fa-circle" style="color: var(--success-color);"></i>
                    System status: Operational
                </div>
            </div>
        </div>
    </div>
</body>
</html>