/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

// NOTE: KPB - this is a light refatoring of inappbrowser.js to allow "private" members
// This should be used as the basis of the OS specific inappbrowser.js files.

(function () {
    // special patch to correctly work on Ripple emulator (CB-9760)
    if (window.parent && !!window.parent.ripple) { // https://gist.github.com/triceam/4658021
        module.exports = window.open.bind(window); // fallback to default window.open behaviour
        return;
    }

    var exec = require('cordova/exec');
    var channel = require('cordova/channel');
    var modulemapper = require('cordova/modulemapper');
    var urlutil = require('cordova/urlutil');

    function InAppBrowser (url, windowName, windowFeatures, callbacks) {
        var me = this;
        me.channels = {
            'beforeload': channel.create('beforeload'),
            'loadstart': channel.create('loadstart'),
            'loadstop': channel.create('loadstop'),
            'loaderror': channel.create('loaderror'),
            'exit': channel.create('exit'),
            'customscheme': channel.create('customscheme'),
            'message': channel.create('message')
        };

        me.close = function (eventname) {
            exec(null, null, 'InAppBrowser', 'close', []);
        };

        me.show = function (eventname) {
            exec(null, null, 'InAppBrowser', 'show', []);
        };

        me.hide = function (eventname) {
            exec(null, null, 'InAppBrowser', 'hide', []);
        };

        me.addEventListener = function (eventname, f) {
            if (eventname in me.channels) {
                me.channels[eventname].subscribe(f);
            }
        };

        me.removeEventListener = function (eventname, f) {
            if (eventname in me.channels) {
                me.channels[eventname].unsubscribe(f);
            }
        };

        me.executeScript = function (injectDetails, cb) {
            if (injectDetails.code) {
                exec(cb, null, 'InAppBrowser', 'injectScriptCode', [injectDetails.code, !!cb]);
            } else if (injectDetails.file) {
                exec(cb, null, 'InAppBrowser', 'injectScriptFile', [injectDetails.file, !!cb]);
            } else {
                throw new Error('executeScript requires exactly one of code or file to be specified');
            }
        };

        me.insertCSS = function (injectDetails, cb) {
            if (injectDetails.code) {
                exec(cb, null, 'InAppBrowser', 'injectStyleCode', [injectDetails.code, !!cb]);
            } else if (injectDetails.file) {
                exec(cb, null, 'InAppBrowser', 'injectStyleFile', [injectDetails.file, !!cb]);
            } else {
                throw new Error('insertCSS requires exactly one of code or file to be specified');
            }
        };

        // NOTE: this is meant to be private, but isn't, usual JS underscore foo "protecting" it...
        me._eventHandler  = function (event) {
            if (event && (event.type in me.channels)) {
                if (event.type === 'beforeload') {
                    me.channels[event.type].fire(event, _loadAfterBeforeload);
                } else {
                    me.channels[event.type].fire(event);
                }
            }
        };

        function  _loadAfterBeforeload (strUrl) {
            strUrl = urlutil.makeAbsolute(strUrl);
            exec(null, null, 'InAppBrowser', 'loadAfterBeforeload', [strUrl]);
        }
    }

    module.exports = function (strUrl, strWindowName, strWindowFeatures, callbacks) {
        // Don't catch calls that write to existing frames (e.g. named iframes).
        if (window.frames && window.frames[strWindowName]) {
            var origOpenFunc = modulemapper.getOriginalSymbol(window, 'open');
            return origOpenFunc.apply(window, arguments);
        }

        strUrl = urlutil.makeAbsolute(strUrl);
        var iab = new InAppBrowser();

        callbacks = callbacks || {};
        for (var callbackName in callbacks) {
            iab.addEventListener(callbackName, callbacks[callbackName]);
        }

        var cb = function (eventname) {
            iab._eventHandler(eventname);
        };

        strWindowFeatures = strWindowFeatures || '';

        exec(cb, cb, 'InAppBrowser', 'open', [strUrl, strWindowName, strWindowFeatures]);
        return iab;
    };
})();