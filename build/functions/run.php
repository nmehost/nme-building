<?php
  $nonce = intval($_POST['nonce']);
  $tdiff = time()-$nonce;
  if ($tdiff<0 || $tdiff>30)
  {
     header("HTTP/1.0 408 Request Timeout");
  }
  else
  {
     chdir($_ENV["DOCUMENT_ROOT"]."/../hurts");
     $lines = file("passwd.txt", FILE_IGNORE_NEW_LINES);
     $passwd = $lines[0];

     $nekoFile = $_POST['data'];
     $action = $_POST['action'];
     $md5Val = $_POST['md5'];
     $params = $_POST['params'];
     $auth = md5($action . $params . $nekoFile . $nonce . $passwd );
     if ($auth==$md5Val)
     {
        if ($nekoFile=="")
        {
           header("HTTP/1.0 400 Bad Action");
        }
        else
        {
           putenv("LD_LIBRARY_PATH=.");
           echo passthru("./neko scripts/" . $nekoFile . " " . escapeshellarg($params));
        }
     }
     else
     {
        header("HTTP/1.0 403 Forbidden");
     }
  }
?> 
