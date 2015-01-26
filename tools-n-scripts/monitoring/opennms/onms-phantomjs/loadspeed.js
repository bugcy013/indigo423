var page = require('webpage').create(),
  system = require('system'),
  t, address;

address = system.args[1];

t = Date.now();

var finished = false;

// ignore any parse errors

page.onError = function(msg, trace) {};

page.open(address, function (status) {
  var exitStatus;

  if (status !== 'success') {
    exitStatus = 1;
    finished = true;
  } else {
    t = Date.now() - t;
    console.log(t);
    exitStatus = 0;
    finished = true;
  }

  phantom.exit(exitStatus);
});

window.setTimeout(function() {
  if (finished==true) {
    phantom.exit(exitStatus);
  } else {
    console.log("timeout");
    phantom.exit(2);
  }
}, system.args[2]);
