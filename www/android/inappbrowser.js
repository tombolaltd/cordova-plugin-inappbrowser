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

    function InAppBrowser (strUrl, strWindowName, strWindowFeatures, callbacks) {
        var me = this;
        var hidden = false;
        var backChannels = { };
        me.channels = {
            'beforeload': channel.create('beforeload'),
            'loadstart': channel.create('loadstart'),
            'loadstop': channel.create('loadstop'),
            'loaderror': channel.create('loaderror'),
            'hidden' : channel.create('hidden'),
            'unhidden' : channel.create('unhidden'),
            'bridgeresponse' : channel.create('bridgeresponse'),
            'exit': channel.create('exit'),
            'customscheme': channel.create('customscheme'),
            'message': channel.create('message')
        };

        me.isHidden = function(){
            return hidden;
        }

        me.close = function (eventname) {
            exec(null, null, 'InAppBrowser', 'close', []);
            hidden = false;
        };

        me.show = function (eventname) {
            exec(null, null, 'InAppBrowser', 'show', []);
            hidden = false;
        };

        me.hide = function (eventname) {
            exec(null, null, 'InAppBrowser', 'hide', []);
            hidden = true;
        };

        me.unHide = function (strUrl, eventname) {
            exec(null,null,"InAppBrowser", "unHide", [strUrl]);
            hidden = false;
        };

        me.update = function (strUrl, show) {
            exec(null,null,"InAppBrowser", "update", [strUrl, show]);

            if (show) {
                hidden = false;
            }
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

        function eventHandler (event) {
            JOptionPane.showMessageDialog(null, "EVENT!!");
            JOptionPane.showMessageDialog(null, event.eventname);
            if (event && (event.type in me.channels)) {
                if (event.type === 'beforeload') {
                    // me.channels[event.type].fire(event, loadAfterBeforeload);
                    me.channels[event.type].fire(event);
                } else {
                    me.channels[event.type].fire(event);
                }
            }
        };

        function  loadAfterBeforeload (strUrl) {
            strUrl = urlutil.makeAbsolute(strUrl);
            exec(null, null, 'InAppBrowser', 'loadAfterBeforeload', [strUrl]);
        }

        for (var callbackName in callbacks) {
            me.addEventListener(callbackName, callbacks[callbackName]);
        }
 
        exec(eventHandler, eventHandler, "InAppBrowser", "open", [strUrl, strWindowName, strWindowFeatures]);

    }

    module.exports = function (strUrl, strWindowName, strWindowFeatures, callbacks) {
        // Don't catch calls that write to existing frames (e.g. named iframes).
        if (window.frames && window.frames[strWindowName]) {
            var origOpenFunc = modulemapper.getOriginalSymbol(window, 'open');
            return origOpenFunc.apply(window, arguments);
        }

        strUrl = urlutil.makeAbsolute(strUrl);

        strWindowFeatures = strWindowFeatures || '';

        if(strWindowName === '_system') {
            // This is now separate as more-or-less fire and forget system browser was re-utilising
            // Code for blank/self. This caused problems with browser crashes etc.
            exec(null, null, "SystemBrowser", "open", [strUrl, strWindowName, strWindowFeatures]);
        } else {
            return new InAppBrowser(strUrl, strWindowName, strWindowFeatures, callbacks || {});
        }
    };
})();