<?php
#echo 'test';
#chroot('/tmp');
$post = file_get_contents('php://input');
system('latexmlmediawiki '.escapeshellarg( $post )) or die('error:' . $post);