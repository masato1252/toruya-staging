$(document).ready(function() {
  var animationSpeed = 300;
  var $sideNav = $("#sideNav")

  $sideNav.on('click', 'dt', function(e) {
    var $this = $(this);
    var checkElement = $this.next();

    //If the menu is visible
    if (checkElement.is(':visible')) {
      checkElement.slideUp(animationSpeed);
      $this.removeClass("here");
    }
    //If the menu is not visible
    else {
      $sideNav.find('dd:visible').slideUp(animationSpeed);
      $sideNav.find("dt").removeClass('here');

      //Open the target menu and add the here class
      checkElement.slideDown(animationSpeed, function() {
        $this.addClass('here');
      });
    }
  });
})
