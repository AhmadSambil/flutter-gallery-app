<?php
header('Content-Type: application/json');

include "db.php";

if (
    !isset($_POST['user_id']) ||
    !isset($_POST['type']) ||
    !isset($_FILES['file'])
) {
    echo json_encode([
        "success" => false,
        "message" => "Missing data"
    ]);
    exit;
}

$user_id = $_POST['user_id'];
$type = $_POST['type'];

$uploadDir = "uploads/";

if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$fileName = time() . "_" . basename($_FILES['file']['name']);
$targetFile = $uploadDir . $fileName;

if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFile)) {

    $stmt = $conn->prepare(
        "INSERT INTO posts (user_id, type, file_name)
         VALUES (?, ?, ?)"
    );

    $stmt->bind_param("iss", $user_id, $type, $fileName);

    if ($stmt->execute()) {

        echo json_encode([
            "success" => true,
            "file_name" => $fileName
        ]);

    } else {

        echo json_encode([
            "success" => false,
            "message" => $stmt->error
        ]);
    }

} else {

    echo json_encode([
        "success" => false,
        "message" => "File upload failed"
    ]);
}
?>