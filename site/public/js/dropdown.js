  $(document).ready(function(){
    /////////////////////////////
    // PNG fix for IE6. 7
    /////////////////////////////
    //DD_belatedPNG.fix('#search input.field, #search input.field:focus, #featured_home .bigimg .post_category a,#featured_home .bigimg .post_name a, #message_buttons .button2 a, #message_buttons .button2 a:hover, #inner_content .date, img');
    
   // $(document).pngFix();
    /////////////////////////////
    // Disable the mouse selection of slider (for example if u double click on the image)
    /////////////////////////////
    $('#slider').css({
      'MozUserSelect' : 'none'
    }).bind('selectstart', function() {
      return false;
    }).mousedown(function() {
      return false;
    });

  
  
  
  /////////////////////////////
  // Dropping down the menus
  /////////////////////////////
  // PARAMS:
  var $slide_down_speed = 300;    // speed which the menu slide down
  var $slide_up_speed = 0;        // speed which the menu slide up
  var $dropdown_menu_width = 230; // width of the dropdown menu (if you change that in CSS, please change it here)
  var $level = 0;                 // actual level of dropped menu (PLEASE DONT CHANGE!!)

  // CODE
  $("#navigation ul li").hover(
    // MOUSE IN
    function()
		{
		$(this).find("ul:first").stop(true, true).slideDown($slide_down_speed);
		
		if ($level > 0) // ONLY IF THE DROPDOWN LEVEL IS HIGHER THEN FIRST, WE HAVE TO CHANGE THE LEFT POSITION OF DROPDOWN 
    {
  		$(this).find("ul:first").css("left", $dropdown_menu_width);
      $(this).find("ul:first").css("top", 0);
    }
    // here we changing the ODD and EVEN classes of the dropdown menu
    $(this).find("ul:first").children("li").children("a:odd").addClass('odd');
    $(this).find("ul:first").children("li").children("a:even").addClass('even'); 
    
    // changing the NAVIGATION background image
		$(this).find("a.main_category").css("background-image","url(images/navigation_hover.gif)");
		$(this).find("a.main_category").css("background-position","top center");
		$(this).find("a.main_category").css("background-repeat","no-repeat");
		$(this).find("a.main_category").css("color","#FFF");
		$level++; // increasing the actual dropdown level								  
		},
		// MOUSE OUT
    function ()
		{
			$(this).find("ul").stop(true,true).slideUp($slide_up_speed);   // slide up the CSS    
			$(this).find("a").css("background-image","");
			$(this).find("a.main_category").css("color","#666");
			$("#navigation li.active").find("a.main_category").css("color","#FFF");
			$level--;                                                      // decrease the actual level
			
		}
	);

	 
  });