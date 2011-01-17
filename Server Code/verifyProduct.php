<?php
	
	$devmode = TRUE; // change this to FALSE after testing in sandbox
		
	$receiptdata = $_POST['receiptdata'];	
	
	if($devmode)
	{
		$appleURL = "https://sandbox.itunes.apple.com/verifyReceipt";
	}
	else
	{
		$appleURL = "https://buy.itunes.apple.com/verifyReceipt";
	}
	           
 	$receipt = json_encode(array("receipt-data" => $receiptdata));
	$response_json = do_post_request($appleURL, $receipt);
	$response = json_decode($response_json);
	
	
	if($response->{'status'} == 0)
	{
		echo ('YES');
	}
	else
	{
		echo ('NO');		
	}	

	function do_post_request($url, $data, $optional_headers = null)
	{
	  $params = array('http' => array(
	              'method' => 'POST',
	              'content' => $data
	            ));
	  if ($optional_headers !== null) {
	    $params['http']['header'] = $optional_headers;
	  }
	  $ctx = stream_context_create($params);
	  $fp = @fopen($url, 'rb', false, $ctx);
	  if (!$fp) {
	    throw new Exception("Problem with $url, $php_errormsg");
	  }
	  $response = @stream_get_contents($fp);
	  if ($response === false) {
	    throw new Exception("Problem reading data from $url, $php_errormsg");
	  }
	  return $response;
	}

?>

