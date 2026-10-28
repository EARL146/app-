<?php
// Router for serving Flutter Web SPA on development server
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$webRoot = realpath(__DIR__ . '/../../build/web');
$filePath = $webRoot . $uri;

if ($uri !== '/' && file_exists($filePath) && !is_dir($filePath)) {
    // Serve static asset with appropriate MIME type
    $ext = pathinfo($filePath, PATHINFO_EXTENSION);
    $mimes = [
        'js' => 'application/javascript',
        'json' => 'application/json',
        'wasm' => 'application/wasm',
        'css' => 'text/css',
        'html' => 'text/html',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'svg' => 'image/svg+xml',
        'webp' => 'image/webp',
        'ttf' => 'font/ttf',
        'otf' => 'font/otf',
        'woff' => 'font/woff',
        'woff2' => 'font/woff2',
    ];
    if (isset($mimes[$ext])) {
        header('Content-Type: ' . $mimes[$ext]);
    }
    header('Access-Control-Allow-Origin: *');
    readfile($filePath);
    return true;
}

// Fallback to index.html for Single-Page Application (Flutter Web Router)
header('Content-Type: text/html; charset=utf-8');
header('Access-Control-Allow-Origin: *');
readfile($webRoot . '/index.html');
return true;
