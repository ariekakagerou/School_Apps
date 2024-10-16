<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

define('DB_HOST', 'localhost');
define('DB_USER', 'praktikum_Ojan');
define('DB_PASS', 'daytt123*363#');
define('DB_NAME', 'praktikum_ti_2022_KLPK_Ojan');

$connection = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($connection->connect_error) {
    die(json_encode(["status" => "error", "pesan" => "Koneksi gagal: " . $connection->connect_error]));
}

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        if (isset($_GET['kd_galery'])) {
            $kd_galery = $connection->real_escape_string($_GET['kd_galery']);
            $sql = "SELECT * FROM galery WHERE kd_galery = '$kd_galery'";
            $result = $connection->query($sql);
            $data = $result->fetch_assoc();
        } else {
            $sql = "SELECT * FROM galery";
            $result = $connection->query($sql);
            $data = $result->fetch_all(MYSQLI_ASSOC);
        }
        echo json_encode(["status" => "sukses", "data" => $data]);
        break;

    case 'POST':
        $target_dir = "uploads/";
        $file_extension = pathinfo($_FILES["foto_galery"]["name"], PATHINFO_EXTENSION);
        $new_filename = uniqid() . '.' . $file_extension;
        $target_file = $target_dir . $new_filename;
        $uploadOk = 1;
        $imageFileType = strtolower($file_extension);

        // Cek apakah file gambar adalah gambar sebenarnya atau file palsu
        $check = getimagesize($_FILES["foto_galery"]["tmp_name"]);
        if($check === false) {
            echo json_encode(["status" => "error", "pesan" => "File bukan gambar."]);
            $uploadOk = 0;
        }

        // Cek ukuran file
        if ($_FILES["foto_galery"]["size"] > 500000) {
            echo json_encode(["status" => "error", "pesan" => "File terlalu besar."]);
            $uploadOk = 0;
        }

        // Izinkan hanya format tertentu
        if(!in_array($imageFileType, ['jpg', 'png', 'jpeg', 'gif'])) {
            echo json_encode(["status" => "error", "pesan" => "Hanya file JPG, JPEG, PNG & GIF yang diizinkan."]);
            $uploadOk = 0;
        }

        // Cek apakah $uploadOk diatur ke 0 oleh kesalahan
        if ($uploadOk == 0) {
            echo json_encode(["status" => "error", "pesan" => "File tidak diupload."]);
        } else {
            if (move_uploaded_file($_FILES["foto_galery"]["tmp_name"], $target_file)) {
                $judul_galery = $connection->real_escape_string($_POST['judul_galery']);
                $foto_galery = $connection->real_escape_string($new_filename);
                $isi_galery = $connection->real_escape_string($_POST['isi_galery']);
                $tgl_post_galery = $connection->real_escape_string($_POST['tgl_post_galery']);
                $status_galery = $connection->real_escape_string($_POST['status_galery']);
                $kd_petugas = $connection->real_escape_string($_POST['kd_petugas']);

                if (isset($_POST['action']) && $_POST['action'] == 'edit') {
                    $kd_galery = $connection->real_escape_string($_POST['kd_galery']);
                    $sql = "UPDATE galery SET 
                                judul_galery = '$judul_galery', 
                                foto_galery = '$foto_galery', 
                                isi_galery = '$isi_galery', 
                                tgl_post_galery = '$tgl_post_galery', 
                                status_galery = '$status_galery', 
                                kd_petugas = '$kd_petugas' 
                            WHERE kd_galery = '$kd_galery'";
                    $message = "Data galery berhasil diperbarui";
                } else {
                    $sql = "INSERT INTO galery (judul_galery, foto_galery, isi_galery, tgl_post_galery, status_galery, kd_petugas) 
                            VALUES ('$judul_galery', '$foto_galery', '$isi_galery', '$tgl_post_galery', '$status_galery', '$kd_petugas')";
                    $message = "Data galery berhasil ditambahkan";
                }
                
                if ($connection->query($sql)) {
                    echo json_encode(["status" => "sukses", "pesan" => $message]);
                } else {
                    echo json_encode(["status" => "error", "pesan" => "Gagal memproses data galery: " . $connection->error]);
                }
            } else {
                echo json_encode(["status" => "error", "pesan" => "Gagal mengupload file."]);
            }
        }
        break;

    case 'DELETE':
        if (isset($_GET['kd_galery'])) {
            $kd_galery = $connection->real_escape_string($_GET['kd_galery']);
            $sql = "DELETE FROM galery WHERE kd_galery = '$kd_galery'";

            if ($connection->query($sql)) {
                echo json_encode(["status" => "sukses", "pesan" => "Data galery berhasil dihapus"]);
            } else {
                echo json_encode(["status" => "error", "pesan" => "Gagal menghapus data galery: " . $connection->error]);
            }
        } else {
            echo json_encode(["status" => "error", "pesan" => "kd_galery tidak ditemukan"]);
        }
        break;

    default:
        echo json_encode(["status" => "error", "pesan" => "Metode tidak valid"]);
        break;
}

$connection->close();
?>