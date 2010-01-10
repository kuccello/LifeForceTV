                       
  $(document).ready(function(){ 
    if(jQuery.browser.msie)
      {
        $("#vml_ie").append("<style>v\:image { behavior:url(#default#VML); display:inline-block ; -ms-interpolation-mode: bicubic}</style>\n");
        $("#vml_ie").append("<xml:namespace ns=\"urn:schemas-microsoft-com:vml\" prefix=\"v\" />");
      } 
  /*
      
      
        
      <!-- Include the VML behavior -->
<style>v\:image { behavior:url(#default#VML); display:inline-block ; -ms-interpolation-mode: bicubic}</style>
<!-- Declare the VML namespace -->
<xml:namespace ns="urn:schemas-microsoft-com:vml" prefix="v" />
 */
      /////////////////////////////
      // SLIDER
      /////////////////////////////
      // PARAMETERS:
      var $rotate_plus_sign_about = 180;    // degrees
      var $rotate_minus_sign_about = -180;  // degrees
      var $width_of_the_image = 162;        // width of ONE image in pixels, including the margin !!
      var $speed_of_moving = 0;             // in miliseconds, speed which are the images moving
      
      // SLIDER MAX is the minus sign
      // SLIDER MIN is the plus sign
      
      /////////////////////////////
      //INTERNAL PARAMS, PLEASE DONT CHANGE
      /////////////////////////////
	    var $rotmaxangle = 180;
      var $rotminangle = -180;
      var $es = $("#thumbs").find("li").size();   // el = Elements in Slider
      var $es_width = $width_of_the_image;
     
      $("#sl_content").css("width", $es_width * $es);
	    var $kook = 0;
      var $step = 0;
      var $actual_step = 0; 
      var $max_step = $es - 5;
      if(!($.browser.msie && $.browser.version=="6.0")) 
      {
       // $('#round_max').css("border", "1px solid black");
        $('#round_max').css("width", 26);	
        $('#round_max').css("height", 26);	
        $('#round_min').css("width", 26);	
        $('#round_min').css("height", 26);	
      }
      else
      {
      $('#round_max').css("margin", "34px 10px 33px 10px;");
      $('#round_min').css("margin", "34px 10px 33px 10px;");
     
      $('#sign_min').css("positon", "absolute");
      $('#sign_min').css("top", 40);
      $('#sign_min').css("left", 16);
      
      $('#sign_max').css("positon", "absolute");
      $('#sign_max').css("top", 40);
      $('#sign_max').css("left", 16);
       // $('#slider_max').("width", 26);	
      }
      
      	if(!($.browser.msie && $.browser.version=="6.0"))
      	{
      // we make objects from slider SIGNS
			     var rot=$('#sign_min').rotate(0);
			     var rota=$('#sign_max').rotate(0);
		    }
			if($.browser.msie && $.browser.version!="6.0")   // position of the signs in IE (dear got i was making that about 3 hours)
			{
  			rot[0].css("position", "absolute");
  			rot[0].css("top", 38);
  			rot[0].css("left", 13);	
  			rota[0].css("position", "absolute");
  			rota[0].css("top", 38);
  			rota[0].css("left", 13);
			}
			else if(!($.browser.msie && $.browser.version=="6.0"))                // position of the signs in normal working internet browser (mozilla, opera, etc)
			{
        rot[0].css("position", "absolute");
  			rot[0].css("top", 38);
  			rot[0].css("left", 13);
  			rota[0].css("position", "absolute");
  			rota[0].css("top", 37);
  			rota[0].css("left", 12);
      }
      
      // SLIDER MAX is the minus sign
      // SLIDER MIN is the plus sign
      $('#slider_max').hover(     // HERE WE SCALE THE CIRCLE WHEN THE MOUSE IS IN THE ELEMENT
      function () {
      if(!($.browser.msie && $.browser.version=="6.0")) 
      {
      $('#round_max').animate({ 
        width: 30, 
        height: 30,
        marginLeft: 10 ,
        marginTop:35
        }, 50 );
      }
      }, 
      function () {
      if(!($.browser.msie && $.browser.version=="6.0")) 
      {
        $('#round_max').animate({ 
        width: 26, 
        height: 26,
        marginLeft: 12 ,
        marginTop:37
        }, 50 );
        }
      });
      
    $('#slider_min').hover(   // HERE WE SCALE THE CIRCLE WHEN THE MOUSE IS IN THE ELEMENT
      function () {
       if(!($.browser.msie && $.browser.version=="6.0")) 
      {
      $('#round_min').animate({ 
        width: 30, 
        height: 30,
        marginLeft: 10 ,
        marginTop:35
        }, 50 );
        }
      }, 
      function () {
       if(!($.browser.msie && $.browser.version=="6.0")) 
      {
        $('#round_min').animate({ 
        width: 26, 
        height: 26,
        marginLeft: 12 ,
        marginTop:37
        }, 50 );
        }
      }); 
      
       // SLIDER MAX is the minus sign
      // SLIDER MIN is the plus sign
      
      // HERE IS THE ROTATING OF MINUS SIGN AND SLIDING
      $('#slider_max').click(function() {
      $('#slider').onselectstart = function () { return false; }
      $('#sign_max').stop();
      // IE fix
       if(!($.browser.msie && $.browser.version=="6.0")) 
      {
      if($rotminangle%360 == 0 && $.browser.msie)
      {
      	rota[0].animate({ 
        top: 38,
        left: 13
        }, 0 );
			}
			else if($.browser.msie)
		  {
		  	rota[0].animate({ 
        top: 37,
        left: 12
        }, 0 );
      }
      
      // main rotation
      rota[0].rotateAnimation($rotminangle);
      $rotminangle = $rotminangle - 180;
      }
      
      if($actual_step <= 0)   // if is the slider on the end, we make a bounce effect
      {
        $("#sl_content").stop(false, false);
        $("#sl_content").animate({marginLeft: +20}, 300 );
        $("#sl_content").animate({marginLeft: 0}, 80 );
      }
     else  // when the slider can move, we move it
      {
        $step =$es_width;
        $kook = $kook +  $step; 
        $("#sl_content").stop(false, false);
        $("#sl_content").animate({marginLeft: $kook}, 400 );
        $actual_step--;
      }
      });
        
        
        
       
       // SLIDER MAX is the minus sign
      // SLIDER MIN is the plus sign 
      $('#slider_min').click(function() {
      $('#sign_min').stop();
      // IE fix
       if(!($.browser.msie && $.browser.version=="6.0")) 
      {
      if($rotmaxangle%360 == 0 && $.browser.msie)
      {
      	rot[0].animate({ 
        top: 38,
        left: 14
        }, 0 );
			}
			else if($.browser.msie)
		  {
		  	rot[0].animate({ 
        top: 37,
        left: 13
        }, 0 );      
      }
      rot[0].rotateAnimation($rotmaxangle);
      $rotmaxangle = $rotmaxangle + 180;
      }
      if($actual_step >= $max_step) // if we cant move, do the bounce effect
      {
        $("#sl_content").stop(false, false);
        var $bounce = (($es * $es_width) - (5*$es_width)) * (-1);
        $("#sl_content").animate({marginLeft: $bounce - 20}, 300 );
        $("#sl_content").animate({marginLeft: $bounce}, 80 );
      }
      else    // else move the slider
      {
        $step = $es_width; 
        $kook = $kook -  $step; 
        $("#sl_content").stop(false, false);
        $("#sl_content").animate({marginLeft: $kook}, 300 );
        $actual_step++;
      }       
      });
     
      // CHANGING THE IMAGES     
      $('#featured_home li').click(function() {
        $("#slider_main_img").fadeTo(150, 0);   //  fade the MAIN IMAGE to WHITE. And when is the main image white, we call the callback function 
        $(this).fadeTo(150, 0.5,  function()    // fade all slider images to non transparent
        {// callback function
          // GETTING THE Attributes from slider
          $("#slider_img_tit").html($(this).find("a.slider_tit").html());
          $("#slider_img_tit").attr("href", $(this).find("a.slider_tit").attr("href"));
            
          $("#slider_img_desc").html($(this).find("a.slider_desc").html());
          $("#slider_img_desc").attr("href", $(this).find("a.slider_desc").attr("href"));

          // slider_video
          $("#slider_video").html($(this).find("a.slider_swf").html());
          $("#slider_video").attr("href", $(this).find("a.slider_swf").attr("href"));
          $("#slider_video").attr("rel", $(this).find("a.slider_swf").attr("rel"));
            Shadowbox.setup("#slider_video", {
                player:     "swf",
                height:     715,
                width:      435,
                autoplayMovies:     true
            });
          $("#slider_video").show();
          $('.disappear').hide();
          $('.appear').show();

          air_date = $("#slider_airdate");

          if(air_date) {

            air_date.html($(this).find("a.slider_airdate").html());
            //air_date.attr("href", $(this).find("a.slider_swf").attr("href"));
            //air_date.attr("rel", $(this).find("a.slider_swf").attr("rel"));

          }

          desc = $("#slider_description");
          if(desc){
            desc.html( $(this).find("a.slider_description").html());
          }

          rat = $("#slider_rating");
          if(rat){
              rat.html($(this).find("a.slider_rating").html());
          }

          
          // FLIPPING THE IMAGE
          $("#slider_main_img").attr("src",$(this).find("a.slider_img").attr("href")); 
           $("#slider_main_img").fadeTo(150, 1); // FADING MAIN IMAGE TO NORMAL
        });
  
       
  
        $('#featured_home li').fadeTo(5, 1);      // FADE ALL SLIDER IMAGES TO NORMAL
  		  $(this).fadeTo(150, 1);

      });
       
  });
