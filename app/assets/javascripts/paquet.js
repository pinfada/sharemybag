$(document).ready(function() {
  $("#slider1").slider({
      animate: true,
      value:1,
      min: 0,
      max: 1000,
      step: 10,
      slide: function(event, ui) {
          update(1,ui.value); //changed
      }
  });

  $("#slider2").slider({
      animate: true,
      value:0,
      min: 0,
      max: 500,
      step: 1,
      slide: function(event, ui) {
          update(2,ui.value); //changed
      }
  });

  $("#slider3").slider({
      animate: true,
      value:0,
      min: 0,
      max: 100,
      step: 1,
      slide: function(event, ui) {
          update(3,ui.value); //changed
      }
  });

  $("#slider4").slider({
      animate: true,
      value:0,
      min: 0,
      max: 100,
      step: 1,
      slide: function(event, ui) {
          update(4,ui.value); //changed
      }
  });

  $("#slider5").slider({
      animate: true,
      value:0,
      min: 0,
      max: 100,
      step: 1,
      slide: function(event, ui) {
          update(5,ui.value); //changed
      }
  });

  //Added, set initial value.
  $("#Montant").val(0);
  $("#duration").val(0);
  $("#longueur").val(0);
  $("#largeur").val(0);
  $("#hauteur").val(0);
  $("#Montant-label").text(0);
  $("#duration-label").text(0);
  $("#longueur-label").text(0);
  $("#largeur-label").text(0);
  $("#hauteur-label").text(0);

  update();
});

//changed. now with parameter
function update(slider,val) {
  //changed. Now, directly take value from ui.value. if not set (initial, will use current value.)
  var $Montant = slider == 1?val:$("#Montant").val();
  var $duration = slider == 2?val:$("#duration").val();
  var $longueur = slider == 3?val:$("#longueur").val();
  var $largeur = slider == 4?val:$("#largeur").val();
  var $hauteur = slider == 5?val:$("#hauteur").val();

  $total = "€" + ($Montant * $duration);
  $volume = ($longueur * $largeur * $hauteur);

  $( "#Montant" ).val($Montant);
  $( "#Montant-label" ).text($Montant);

  $( "#duration" ).val($duration);
  $( "#duration-label" ).text($duration);

  $( "#longueur" ).val($longueur);
  $( "#longueur-label" ).text($longueur);

  $( "#largeur" ).val($largeur);
  $( "#largeur-label" ).text($largeur);

  $( "#hauteur" ).val($hauteur);
  $( "#hauteur-label" ).text($hauteur);

  $( "#volume" ).val($volume);
  $( "#volume-label" ).text($volume);

  $( "#total" ).val($total);
  $( "#total-label" ).text($total);

  $('#slider1 a').html('<label><span class="glyphicon glyphicon-chevron-left"></span> '+$Montant+' <span class="glyphicon glyphicon-chevron-right"></span></label>');
  $('#slider2 a').html('<label><span class="glyphicon glyphicon-chevron-left"></span> '+$duration+' <span class="glyphicon glyphicon-chevron-right"></span></label>');
  $('#slider3 a').html('<label><span class="glyphicon glyphicon-chevron-left"></span> '+$longueur+' <span class="glyphicon glyphicon-chevron-right"></span></label>');
  $('#slider4 a').html('<label><span class="glyphicon glyphicon-chevron-left"></span> '+$largeur+' <span class="glyphicon glyphicon-chevron-right"></span></label>');
  $('#slider5 a').html('<label><span class="glyphicon glyphicon-chevron-left"></span> '+$hauteur+' <span class="glyphicon glyphicon-chevron-right"></span></label>');
}