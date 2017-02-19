$.fn.bindFirst = function(eventName, fn) {
  var elem, handlers, i, _len;
  this.on(eventName, fn);

  for (i = 0, _len = this.length; i < _len; i++) {
    elem = this[i];
    handlers = jQuery._data(elem).events[eventName.split('.')[0]];
    handlers.unshift(handlers.pop());
  }
};
