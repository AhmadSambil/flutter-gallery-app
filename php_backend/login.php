<?php
header('Content-Type: application/json');

$conn = new mysqli(
    "localhost",
    "root",
    "",
    "flutter_app"
);

if ($conn->connect_error) {
    echo json_encode([
        "status" => false,
        "message" => "Database connection failed"
    ]);
    exit;
}

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

$stmt = $conn->prepare(
    "SELECT id, username, email FROM users WHERE email=? AND password=?"
);
$stmt->bind_param("ss", $email, $password);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows > 0) {

    $user = $result->fetch_assoc();

    echo json_encode([
        "status" => true,
        "user_id" => $user['id'],
        "username" => $user['username'],
        "email" => $user['email']
    ]);

} else {

    echo json_encode([
        "status" => false,
        "message" => "Invalid email or password"
    ]);
}

$stmt->close();
$conn->close();
?>