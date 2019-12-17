var exec = require('cordova/exec');

exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'VideoUpload', 'coolMethod', [arg0]);
};

function parseOptions(args) {
    var a = [];
    a.push(args.key || null);
    a.push(args.secret || null);
    a.push(args.region || null);
    a.push(args.container || null);
    a.push(args.path || null);
    a.push(args.access || null);
    return a;
}    
    
var VideoUpload = {
    init:function(options) {
        exec(function() {}, function() {}, 'VideoUpload', 'init', parseOptions(options));
    },
    startUpload:function(successCB, errorCB) {
        exec(successCB, errorCB, 'VideoUpload', 'startUpload', []);
    }
};

module.exports = VideoUpload;
    