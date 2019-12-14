var exec = require('cordova/exec');

exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'VideoUpload', 'coolMethod', [arg0]);
};

function parseStoreArgs(args) {
    var a = [];
    a.push(args.location || null);
    a.push(args.path || null);
    a.push(args.container || null);
    a.push(args.access || null);
    return a;
}    
    
var VideoUpload = {
    init:function(key, secret) {
        exec(function() {}, function() {}, 'VideoUpload', 'init', [key, secret]);
    },
    startUpload:function(successCB, errorCB) {
        exec(successCB, errorCB, 'VideoUpload', 'startUpload', []);
    }
};

module.exports = VideoUpload;
    