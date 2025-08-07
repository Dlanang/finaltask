<?php
session_start();
if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit;
}
echo "<h1>Welcome, " . htmlspecialchars($_SESSION['user']) . "</h1>";
echo "<iframe src='http://localhost:8501' width='100%' height='800px'></iframe>";
?>
