
<?php
session_start();
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $db = new SQLite3('/var/www/db/app.db');
    $stmt = $db->prepare('SELECT * FROM users WHERE username=:username AND password=:password');
    $stmt->bindValue(':username', $_POST['username'], SQLITE3_TEXT);
    $stmt->bindValue(':password', $_POST['password'], SQLITE3_TEXT);
    $result = $stmt->execute();
    if ($result->fetchArray()) {
        $_SESSION["user"] = $_POST['username'];
        header("Location: /dashboard.php");
    } else {
        echo "Login failed";
    }
}
?>
<form method="post">
  Username: <input type="text" name="username"><br>
  Password: <input type="password" name="password"><br>
  <input type="submit" value="Login">
</form>
