<?php

$conn = new mysqli(
    "localhost",
    "root",
    "",
    "flutter_app"
);

if ($conn->connect_error) {
    die("Database connection failed");
}
?>