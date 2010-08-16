function createExtras(){
  document.getElementById('buttons').setAttribute("style","left:90%;");
  document.getElementById("viewport").setAttribute("style","width:40%;top:50px;")
  document.getElementById("page" + tstCurrentPage).setAttribute("style","width:1250px;")

  var viewPortx = document.createElement("div")
  viewPortx.setAttribute('id','xviewport')
  viewPortx.setAttribute('class','options')
  
  var xoptions = document.createElement("div");
  xoptions.setAttribute('id','options');
  xoptions.setAttribute('class','scrollable');

  viewPortx.appendChild(xoptions) 

  var ul = document.createElement("ul")
  ul.id = "secondUl"

  xoptions.appendChild(ul)

  document.getElementById("page" + tstCurrentPage).setAttribute("style","width:1200px;")
  document.getElementById("load_indicator").setAttribute("style","display:none;")
  document.getElementById("page" + tstCurrentPage).appendChild(viewPortx)
  document.getElementsByClassName("inputPage")[0].setAttribute("style","width:100%;")


  updateTouchscreenInput = function(element) {
    var inputTarget = tstInputTarget;

    if (element.value.length>1)
      inputTarget.value = element.value;
    else if (element.innerHTML.length>1)
    inputTarget.value = element.innerHTML;

    highlightSelection(element.parentNode.childNodes, inputTarget)
    tt_update(inputTarget);
    checkRequireNextClick();
   
    var li = document.createElement("li")
    li.innerHTML = element.innerHTML

    li.onmousedown = function(){
        ul.removeChild(this);
    }

    document.getElementById("secondUl").appendChild(li)
  }

}

