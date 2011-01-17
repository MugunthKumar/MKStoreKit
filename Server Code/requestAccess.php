	
<?php

	$user = "mugunth1_udid";
	$password = "wrong password";
	$dbname = "mugunth1_udid";
	
	$prod = $_POST['productid'];
	$udid = $_POST['udid'];
	$email = $_POST['email'];
	$message = $_POST['message'];
    // Connect to database server

    $hd = mysql_connect("localhost", $user, $password)

          or die ("Unable to connect");

    // Select database

    mysql_select_db ($dbname, $hd)

          or die ("Unable to select database");

    // Execute sample query (insert it into mksync all data in customer table)

    $res = mysql_query("INSERT INTO mugunth1_udid.requests(udid, productid, email, message) VALUES ('$udid', '$prod', '$email', '$message')",$hd)

          or die ("Unable to insert :-(");
	
 	mysql_close($hd);
 	
 	echo "Done!";
?>
