<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, User-Agent, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

header("Content-Type: application/json");
ignore_user_abort(true);
set_time_limit(300);

//$pixabay_api_key = "25066829-e19f4bd20795e793e3349ffe7";
//$passcode = "Topp3r@19511969!";
// __DIR__ is /var/www/html/images
// /../ goes up one level to /var/www/html/config.php
$config = require __DIR__ . '/../config.php';

$pixabay_api_key = $config['pixabay_api_key'];
$passcode        = $config['passcode'];

$base_dir = __DIR__ . "/category/";
$max_images_per_category = 200;

// Read input safely whether sent via POST, GET, or JSON body from Godot Web
$input_data = [];
$content_type = $_SERVER['CONTENT_TYPE'] ?? '';
if (strpos($content_type, 'application/json') !== false) {
    $input_data = json_decode(file_get_contents('php://input'), true) ?? [];
}

$input_passcode = $_POST['passcode'] ?? $_GET['passcode'] ?? $input_data['passcode'] ?? '';
if (empty($input_passcode) || $input_passcode !== $passcode) {
    echo json_encode(array("status" => "error", "message" => "Sorry, incorrect passcode."));
    exit;
}

$category = $_POST['category'] ?? $_GET['category'] ?? $input_data['category'] ?? '';
$category = trim($category);
$category_clean = preg_replace('/[^a-zA-Z0-9_-]/', '', $category);
if (empty($category_clean)) {
    $category_clean = "default";
}

$target_dir = $base_dir . $category_clean . "/";
$page_file = $target_dir . "page.json";
$metadata_file = $target_dir . "metadata.json";

// Create directory if it doesn't exist
if (!is_dir($target_dir)) {
    mkdir($target_dir, 0775, true);
}

// Load current page number
$page_number = 1;
if (file_exists($page_file)) {
    $page_content = file_get_contents($page_file);
    $page_data = json_decode($page_content, true);
    if (isset($page_data['page_number'])) {
        $page_number = (int)$page_data['page_number'];
    }
}

// Load metadata
$metadata = [];
if (file_exists($metadata_file)) {
    $meta_content = file_get_contents($metadata_file);
    $metadata = json_decode($meta_content, true) ?: [];
}

// Check local cache
$local_images = glob($target_dir . "pixabay_*.jpg");
$local_count = count($local_images);

// Fetch trigger: fetch if directory is empty OR randomly triggered if below max images
$should_fetch_pixabay = ($local_count < $max_images_per_category) && ($local_count === 0 || mt_rand(1, 5) === 1);

// Helper function to crop and resize image to exact 1152x648 dimensions
function resize_image_to_fit($image_data, $target_width = 1152, $target_height = 648) {
    $src_image = @imagecreatefromstring($image_data);
    if (!$src_image) {
        return false;
    }
    $orig_w = imagesx($src_image);
    $orig_h = imagesy($src_image);
    $src_aspect = $orig_w / $orig_h;
    $target_aspect = $target_width / $target_height;
    
    if ($src_aspect > $target_aspect) {
        $crop_h = $orig_h;
        $crop_w = (int)($orig_h * $target_aspect);
        $crop_x = (int)(($orig_w - $crop_w) / 2);
        $crop_y = 0;
    } else {
        $crop_w = $orig_w;
        $crop_h = (int)($orig_w / $target_aspect);
        $crop_x = 0;
        $crop_y = (int)(($orig_h - $crop_h) / 2);
    }
    
    $dst_image = imagecreatetruecolor($target_width, $target_height);
    imagealphablending($dst_image, true);
    imagesavealpha($dst_image, true);
    imagecopyresampled(
        $dst_image, $src_image,
        0, 0, $crop_x, $crop_y,
        $target_width, $target_height,
        $crop_w, $crop_h
    );
    
    ob_start();
    imagejpeg($dst_image, null, 85);
    $resized_bytes = ob_get_clean();
    
    imagedestroy($src_image);
    imagedestroy($dst_image);
    return $resized_bytes;
}

if ($should_fetch_pixabay) {
    $search_query = urlencode($category);
    // Fetch 20 images per page using current $page_number
    $pixabay_url = "https://pixabay.com/api/?key={$pixabay_api_key}&q={$search_query}&image_type=photo&safesearch=true&page={$page_number}&per_page=20";
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $pixabay_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0');
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_code === 200 && $response) {
        $data = json_decode($response, true);
        if (isset($data['hits']) && count($data['hits']) > 0) {
            // Process 1 image immediately so client gets a quick response
            $random_hit = $data['hits'][array_rand($data['hits'])];
            $random_filename = "pixabay_" . $random_hit['id'] . ".jpg";
            $photographer = $random_hit['user'] ?? "Unknown";
            $metadata[$random_filename] = $photographer;

            $first_file_path = $target_dir . $random_filename;
            if (!file_exists($first_file_path)) {
                $image_bytes = @file_get_contents($random_hit['largeImageURL'] ?? $random_hit['webformatURL']);
                if ($image_bytes !== false) {
                    $resized_bytes = resize_image_to_fit($image_bytes, 1152, 648);
                    if ($resized_bytes !== false) {
                        file_put_contents($first_file_path, $resized_bytes);
                    }
                }
            }
            file_put_contents($metadata_file, json_encode($metadata));
        }
    }
}

// Select filename to return to client
if (!isset($random_filename)) {
    if (!empty($local_images)) {
        $random_path = $local_images[array_rand($local_images)];
        $random_filename = basename($random_path);
    } else {
        echo json_encode(array("status" => "error", "message" => "No images available for this category yet."));
        exit;
    }
}

// Send JSON response to client immediately
$public_image_url = "https://images.lynnwilsonart.com/category/" . $category_clean . "/" . $random_filename;
$response_body = json_encode(array(
    "status" => "success",
    "category" => $category_clean,
    "image_url" => $public_image_url,
    "photographer" => $metadata[$random_filename] ?? "Unknown"
));

header("Content-Length: " . strlen($response_body));
header("Connection: close");
echo $response_body;

if (function_exists('fastcgi_finish_request')) {
    fastcgi_finish_request();
} else {
    @ob_end_flush();
    flush();
}

// Background task: Loop through and download the remaining 20 images from this page
if (isset($data) && isset($data['hits']) && count($data['hits']) > 0) {
    foreach ($data['hits'] as $hit) {
        $current_count = count(glob($target_dir . "pixabay_*.jpg"));
        if ($current_count >= $max_images_per_category) {
            break;
        }

        $pixabay_id = $hit['id'];
        $filename = "pixabay_" . $pixabay_id . ".jpg";
        $local_file_path = $target_dir . $filename;

        $metadata[$filename] = $hit['user'] ?? "Unknown";
        if (!file_exists($local_file_path)) {
            $image_bytes = @file_get_contents($hit['largeImageURL'] ?? $hit['webformatURL']);
            if ($image_bytes !== false) {
                $resized_bytes = resize_image_to_fit($image_bytes, 1152, 648);
                if ($resized_bytes !== false) {
                    file_put_contents($local_file_path, $resized_bytes);
                }
            }
            usleep(mt_rand(600000, 2000000));
        }
    }

    // Save updated metadata file
    file_put_contents($metadata_file, json_encode($metadata));

    // NOW that all 20 images from this page are processed, increment page_number
    $page_number++;
    file_put_contents($page_file, json_encode(['page_number' => $page_number]));
}

exit;
?>