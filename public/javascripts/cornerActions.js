var topRight = document.createElement("div")
topRight.setAttribute('style','position:absolute;top:0px;right:0px;z-index:10;height:30px;width:30px;')
topRight.setAttribute('onClick','topRightClick()')
document.body.appendChild(topRight)
var topLeft = document.createElement("div")
topLeft.setAttribute('style','position:absolute;top:0px;left:0px;z-index:10;height:30px;width:30px;')
topLeft.setAttribute('onClick','topLeftClick()')
document.body.appendChild(topLeft)

var topRightClickCount = 0
var topLeftClickCount = 0

function resetClickCount(){
  topRightClickCount = 0
  topLeftClickCount = 0
  topRight.style.backgroundColor='transparent';
  topLeft.style.backgroundColor='transparent';
}

function topRightClick() {
  topRight.style.backgroundColor='red';
  topRightClickCount = topRightClickCount + 1

  if(topRightClickCount > 3) {
    window.location.reload()
  }
  window.setTimeout("resetClickCount()",4000)
}

function topLeftClick() {
  topLeft.style.backgroundColor='red';
  topLeftClickCount = topLeftClickCount + 1

  if(topLeftClickCount > 3) {
    history.back()
  }
  window.setTimeout("resetClickCount()",5000)
}
