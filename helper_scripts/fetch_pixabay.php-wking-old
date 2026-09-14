<?php

//Versioon 1.0

// CORS Headers (Allows web browsers and Godot HTML5 exports to read the JSON)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, User-Agent, X-Requested-With");

// Handle browser preflight OPTIONS requests immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

header("Content-Type: application/json");

// CRITICAL: Allow script to keep running in the background after Godot disconnects
ignore_user_abort(true);
set_time_limit(300);

// 1. CONFIGURATION
$pixabay_api_key = "25066829-e19f4bd20795e793e3349ffe7";
$passcode = "Topp3r@19511969!";
$base_dir = __DIR__ . "/category/"; // <--- Fixed local filesystem path
$max_images_per_category = 200; // <--- Hard limit: Stops fetching new ones once this cap is reached
$page_number=1;

// Read input safely whether sent via POST, GET, or JSON body from Godot Web
$input_data = [];
$content_type = $_SERVER['CONTENT_TYPE'] ?? '';
if (strpos($content_type, 'application/json') !== false) {
    $input_data = json_decode(file_get_contents('php://input'), true) ?? [];
}

// 2. PASSCODE HANDSHAKE (Checks POST, GET, and JSON body)
$input_passcode = $_POST['passcode'] ?? $_GET['passcode'] ?? $input_data['passcode'] ?? '';
if (empty($input_passcode) || $input_passcode !== $passcode) {
    echo json_encode(array("status" => "error", "message" => "Sorry, incorrect passcode."));
    exit;
}

// 3. GET & SANITIZE CATEGORY (Checks POST, GET, and JSON body)
$category = $_POST['category'] ?? $_GET['category'] ?? $input_data['category'] ?? '';
$category = trim($category);
if (empty($category)) {
    echo json_encode(array("status" => "error", "message" => "No category provided."));
    exit;
}

$category_clean = preg_replace('/[^a-zA-Z0-9_-]/', '', $category);
if (empty($category_clean)) {
    $category_clean = "default";
}

$target_dir = $base_dir . $category_clean . "/";
$metadata_file = $target_dir . "metadata.json";

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
    imagejpeg($dst_image, null, 85); // 85% JPEG quality
    $resized_bytes = ob_get_clean();

    imagedestroy($src_image);
    imagedestroy($dst_image);

    return $resized_bytes;
}

// Load metadata
$metadata = [];
if (file_exists($metadata_file)) {
    $meta_content = file_get_contents($metadata_file);
    $metadata = json_decode($meta_content, true) ?: [];
}

if (!is_dir($target_dir)) {
    mkdir($target_dir, 0775, true);
}

// 4. CHECK LOCAL CACHE & CAP STATUS
$local_images = glob($target_dir . "pixabay_*.jpg");
$local_count = count($local_images);

$should_fetch_pixabay = false;

if ($local_count < 5) {
    // If we have almost nothing, we must fetch
    $should_fetch_pixabay = true;
} else if ($local_count < $max_images_per_category) {
    // If we haven't hit the cap yet, use a 20% chance to gradually grow the pool
    if (mt_rand(1, 5) === 1) {
        $should_fetch_pixabay = true;
    }
} else {
    // CAP REACHED! Never hit Pixabay again for this category.
    $should_fetch_pixabay = false;
}

$random_filename = "";
$photographer = "Photos Provided By Pixabay.com ";

if (!$should_fetch_pixabay && $local_count > 0) {
    // FAST PATH: Serve directly from local cache instantly (0 API calls)
    $random_image_path = $local_images[array_rand($local_images)];
    $random_filename = basename($random_image_path);
    $photographer = $metadata[$random_filename] ?? "Lynn Wilson Art";
} else {
	 $page_number = intdiv($local_count,20);// number pages thay have been downloaded so far
	 $page_number += 1; // Increment to next page
    // API PATH: Query Pixabay for a fresh batch
    $search_query = urlencode($category);
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

    // Fallback if API failed but we already have local files
    if (empty($random_filename) && !empty($local_images)) {
        $random_image_path = $local_images[array_rand($local_images)];
        $random_filename = basename($random_image_path);
        $photographer = $metadata[$random_filename] ?? "Image Provided By pixabay.com";
    }
}

if (empty($random_filename)) {
    echo json_encode(array("status" => "error", "message" => "No images available for category: " . $category));
    exit;
}

// Build and send response to Godot immediately
$public_image_url = "https://images.lynnwilsonart.com/category/" . $category_clean . "/" . $random_filename;

echo json_encode(array(
    "status" => "success",
    "category" => $category_clean,
    "image_url" => $public_image_url,
    "photographer" => $photographer
));

if (function_exists('fastcgi_finish_request')) {
    fastcgi_finish_request();
} else {
    flush();
}

// 5. BACKGROUND TASK: DOWNLOAD NEW IMAGES UNTIL THE CAP IS MET
if (isset($data['hits'])) {
    foreach ($data['hits'] as $hit) {
        // Re-check current count before downloading each image to respect the hard cap
        $current_count = count(glob($target_dir . "pixabay_*.jpg"));
        if ($current_count >= $max_images_per_category) {
            break; // Stop downloading if we've reached the maximum limit
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
    file_put_contents($metadata_file, json_encode($metadata));
}
exit;
?>