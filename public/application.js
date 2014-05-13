$(document).ready(function() {
  
    $(document).on('click','#hit', function(){
    $.ajax({
        type:'POST',
        url:'/hit',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });

    $(document).on('click','#stay', function(){
    $.ajax({
        type:'POST',
        url:'/stay',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });

    $(document).on('click','#dealer_turn', function(){
    $.ajax({
        type:'POST',
        url:'/dealer_turn',
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
    
  });

});