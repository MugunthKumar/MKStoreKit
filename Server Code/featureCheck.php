<?php
	$dbname = "mugunth1_udid";
	$user = "mugunth1_udid";
	$password = "wrong password";
	
	header('Content-Type: text/plain'); 
	$prod = filter_input(INPUT_POST,'productid',FILTER_SANITIZE_STRING); // varchar(255)
	$udid = filter_input(INPUT_POST,'udid',FILTER_SANITIZE_STRING); // varchar(255)
	
	// Connect to database server
	$hd = mysql_connect("localhost", $user, $password) or die ("Unable to connect");

	// Select database
	mysql_select_db ($dbname, $hd) or die ("Unable to select database");

	// Execute sample query (insert it into mksync all data in customer table)

	$res = mysql_query("SELECT * FROM mugunth1_udid.requests where udid='".mysql_real_escape_string($udid)."' AND productid='".mysql_real_escape_string($prod)."' AND status = 1",$hd) or die ("Unable to select :-(");

	
	$num = mysql_num_rows($res);
		
	if($num == 0)
		$returnString = "NO";
	else
		$returnString = "YES";
		
	mysql_close($hd);
	echo $returnString;
?>
