<?php
$admin_url = rtrim("http://$_SERVER[HTTP_HOST]$_SERVER[REQUEST_URI]", "/");

require_once "actvps/UserManager.php";
require_once "actvps/UserController.php";
require_once "actvps/Firewall.php";
require_once "actvps/FileManager.php";
require_once "actvps/SQLManager.php";

$config = require "actvps/config.php";
$userManager = new UserManager($config['files']['users']);
$firewall = new Firewall();

if (!$firewall->isAutenticated()) {
	header("HTTP/1.1 401 Authorization Required");
	header('WWW-Authenticate: Basic realm="Please login"');
	die();
}

if (!isset($_GET['action']))
	$_GET['action'] = '';

switch($_GET['action']) {

	case 'updatePassword':
		$controller = new UserController();
		$controller->updatePassword();
		break;

	case 'changePassword':
		$controller = new UserController();
		$controller->editPassword();
		break;

	case 'listUsers':
	default:
		$controller = new UserController();
		$controller->index();
}