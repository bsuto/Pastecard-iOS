var extensionJS = function() {};
extensionJS.prototype = {
    run: function(arguments) {
        var t = window.getSelection().toString();
        if (t == '') {
            t = document.URL.toString();
            t = t.replace(/https?\:\/\//gi,'');
        }
          
        arguments.completionFunction({"text": t});
    }
};

var ExtensionPreprocessingJS = new extensionJS;
