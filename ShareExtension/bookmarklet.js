var extensionJS = function() {};
extensionJS.prototype = {
    run: function(arguments) {
        var t = document.URL;
        t = t.replace(/https?\:\/\//gi,'');
        arguments.completionFunction({"text": t});
    }
};

var ExtensionPreprocessingJS = new extensionJS;
