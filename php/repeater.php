<!DOCTYPE html>
<? $img = $_GET['img'] ? $_GET['img'] : "/media/funny-gifs-pug-fangs.gif"?>
<html>
<head>
  <title>The Repeater!</title>
  <style>
    .background { 
       background-image: url(<?= $img ?>) ;
       position: fixed;
     }
    body, div { 
      margin: 0px;
      padding: 0px;
    }
    div { 
      height: 100%;
      width:  100%;
    }
  </style>
  <script src='//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js'></script>
  <script type='text/javascript'>
    (new Image).src= '<?= $img ?>'; //preload
    $(document).ready( function(){ $('div#here').addClass( 'background' ) });
  </script>
</head>
<body><div id='here'></div></body>
</html>