
<?php
session_start();
if (!isset($_SESSION["user"])) {
    header("Location: /login.php");
    exit();
}
echo "<h1>Welcome " . $_SESSION["user"] . "</h1>";
echo "<div id='streamlit'></div>";
?>
<iframe src="http://localhost:8501" width="100%" height="600"></iframe>
