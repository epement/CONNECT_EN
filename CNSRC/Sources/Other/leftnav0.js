
					
			function expandCollapse ( id )			
			{
			
			if ( document.getElementById(id).style.display == "none" )
					{
					document.getElementById(id).style.display="block";
					}
			else
					{
					document.getElementById(id).style.display="none";
					}

			}
			
			function expandcollapseone ( id )
			
			{
			var img_name = "arrow_" + id;
			var unselected_img;
			var img_src;
			var num=9;

			var selected=eval(id);

			for(i=0; i<num; i++)		
				{
					if (i !== selected)
					{				
					img_src = "/supportline/_images/template/rightarrow.jpg";
					unselected_img = "arrow_" + i;
					document[unselected_img].src=img_src;	
					document.getElementById(i).style.display="none";
					}
					else
					{
					img_src = "/supportline/_images/template/downarrow.jpg";	
					document[img_name].src=img_src;	
					}
				}
			
				
			if ( document.getElementById(id).style.display == "none" )
					{
					document.getElementById(id).style.display="block";
					img_src = "/supportline/_images/template/downarrow.jpg";	
					document[img_name].src=img_src;	
					}
			else
					{
					document.getElementById(id).style.display="none";
					img_src = "/supportline/_images/template/rightarrow.jpg";	
					document[img_name].src=img_src;	
					}			
			}
			
			function openall ()
			
			{
			var num=9;
			for(i=0; i<num; i++)
			
			{document.getElementById(i).style.display="block"}
			
			}
			
			
			function collapseall ()
			
			{
			var num=9;
			for(i=0; i<num; i++)
			
			{document.getElementById(i).style.display="none"}
			
			}