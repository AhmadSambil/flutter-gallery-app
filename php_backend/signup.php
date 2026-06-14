<?php
include "db.php";

$username = $_POST['username'];
$email = $_POST['email'];
$password = $_POST['password'];

$check = $conn->query(
    "SELECT * FROM users WHERE email='$email'"
);

if($check->num_rows > 0){
    echo json_encode([
        "success"=>false,
        "message"=>"Email already exists"
    ]);
    exit;
}

$conn->query(
    "INSERT INTO users(username,email,password)
     VALUES('$username','$email','$password')"
);

echo json_encode([
    "success"=>true,
    "message"=>"Signup Successful"
]);