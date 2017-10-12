var num=1;
var place=1;
function movea(id){
if(place==1){var op=document.getElementById("build");}
else if(place==2){var op=document.getElementById("setdat");}
else if(place==3){var op=document.getElementById("fileserver");}
else if(place==4){var op=document.getElementById("report");}
else if(place==5){var op=document.getElementById("upload");}
else if(place==6){var op=document.getElementById("setansible");}
else if(place==7){var op=document.getElementById("searchroles");}
else if(place==8){var op=document.getElementById("register");}
else if(place==9){var op=document.getElementById("templatelist");}
else if(place==10){var op=document.getElementById("setcloudstack");}
op.className="";
if(id=="build"){place=1;}
else if(id=="setdat"){place=2;}
else if(id=="fileserver"){place=3;}
else if(id=="report"){place=4;}
else if(id=="upload"){place=5;}
else if(id=="setansible"){place=6;}
else if(id=="searchroles"){place=7;}
else if(id=="register"){place=8;}
else if(id=="templatelist"){place=9;}
else if(id=="setcloudstack"){place=10;}
var np=document.getElementById(id);
np.className="active";
}
function addtext(id)
{
var opartdiv=document.getElementById(id); 
var partdiv=document.createElement("div");
partdiv.id=opartdiv.id.concat(num.toString());
partdiv.className="row";
partdiv.innerHTML=opartdiv.innerHTML; 
document.getElementById("div1").appendChild(partdiv);
var buttondiv=document.createElement("div");
buttondiv.id="deletediv"+num;
buttondiv.className="col-sm-2";
var partbutton=document.createElement("input");
partbutton.id="delete"+num;
partbutton.type="button";
partbutton.value="delete";
partbutton.className="btn btn-default";
partbutton.onclick=function(){deletetext(this)};
document.getElementById(partdiv.id).appendChild(buttondiv);
document.getElementById(buttondiv.id).appendChild(partbutton);
num=num+1;
}
function deletetext(obj){
    var strid=obj.id;  
    var o=document.getElementById(obj.id);  
    var z=o.parentElement;  
    var zz=document.getElementById(z.id).parentElement; 
    var stridone=zz.id;  
    var my = document.getElementById(stridone);  
    if (my != null){  
    my.parentNode.removeChild(my);}  
}
