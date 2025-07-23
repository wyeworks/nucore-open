// https://developer.mozilla.org/en-US/docs/Web/API/NodeList/forEach#polyfill

if (window.NodeList && !NodeList.prototype.forEach) {
   NodeList.prototype.forEach = Array.prototype.forEach;
}
