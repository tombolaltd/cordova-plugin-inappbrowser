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

    function InAppBrowser (url, windowName, windowFeatures, callbacks) {
        var me = this;
        var hidden = false;
        var backChannels = {
            preventexitonhide : channel.create('preventexitonhide')
        };
        var lastUrl = url;
        var lastWindowName = windowName;
        var lastWindowFeatures = windowFeatures;

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

        me.close = function (eventname) {
            exec(null, null, 'InAppBrowser', 'close', []);
            if (hidden) {
                eventHandler('exit');
            }
            hidden = false;
        };

        me.show = function (eventname) {
            exec(null, null, 'InAppBrowser', 'show', []);
            hidden = false;
        };

        me.hide = function (releaseResources, _blankPage) {
            if (releaseResources) {
                releaseListeners();
            }
            exec(null, null, 'InAppBrowser', 'hide', [releaseResources]);
            hidden = true;
        };

        me.unHide = function(strUrl, eventname){
            if(strUrl){
                lastUrl = urlutil.makeAbsolute(strUrl) || lastUrl || 'about:blank';
            }

            exec(eventHandler, eventHandler, "InAppBrowser", "unHide", [lastUrl, lastWindowName, lastWindowFeatures]);
            hidden = false;
        }

        me.update = function (strUrl, show) {
            if (strUrl) {
                lastUrl = urlutil.makeAbsolute(strUrl) || lastUrl || 'about:blank';
            }

            exec(eventHandler, eventHandler, "InAppBrowser", "update", [lastUrl, lastWindowName, lastWindowFeatures, show]);

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

        me.isHidden = function(){
            return hidden;
        }

        function eventHandler (event) {
            if (event && (event.type in backChannels)) {
                fireEvent(backChannels, event);
            }
            if (event && (event.type in me.channels)) {
                fireEvent(me.channels, event);
            }
        };

        function fireEvent(channels, event) {
            if(!channels){
                return;
            }
            if (!channels[event.type]) {
                return;
            }

            if (event.type === 'beforeload') {
                channels[event.type].fire(event, loadAfterBeforeload);
            }

            channels[event.type].fire(event);
        }

        function  loadAfterBeforeload (strUrl) {
            strUrl = urlutil.makeAbsolute(strUrl);
            exec(null, null, 'InAppBrowser', 'loadAfterBeforeload', [strUrl]);
        }

        function releaseListeners() {
            for (var eventname in me.channels) {
                for(var listenerObserverId in me.channels[eventname].handlers) {
                    me.removeEventListener(eventname, me.channels[eventname].handlers[listenerObserverId]);
                }
            }
        }

        backChannels['preventexitonhide'].subscribe(function(){
            var exitHandlersToRestore = {},
            exitChannel = me.channels['exit'],
            exitRestoreCallBack = function(){
                // This cleans up the current handler
                if (exitRestoreCallBack.observer_guid) {
                    me.removeEventListener('exit', exitChannel.handlers[exitRestoreCallBack.observer_guid]);
                }

                for (var exitCallbackObserverId in exitHandlersToRestore) {
                    var exitEventHandler = exitHandlersToRestore[exitCallbackObserverId];
                    me.addEventListener('exit', exitEventHandler);
                }
            };

            // Need to set this here as it is possible to hide via native code "directly" by calling hide via the
            // command infrastructure and not the hide method
            hidden = true;

            if (exitChannel.numHandlers > 0) {
                for (var exitCallbackObserverId in exitChannel.handlers) {
                    var exitEventHandler = exitChannel.handlers[exitCallbackObserverId];
                    exitHandlersToRestore[exitCallbackObserverId] = exitChannel.handlers[exitCallbackObserverId];
                    me.removeEventListener('exit', exitEventHandler);
                }
                me.addEventListener('exit', exitRestoreCallBack);
            }
        });

        for (var callbackName in callbacks) {
            me.addEventListener(callbackName, callbacks[callbackName]);
        }

        exec(eventHandler, eventHandler, "InAppBrowser", "open", [lastUrl, lastWindowName, lastWindowFeatures]);
    }

    module.exports = function (strUrl, strWindowName, strWindowFeatures, callbacks) {
        // Don't catch calls that write to existing frames (e.g. named iframes).
        if (window.frames && window.frames[strWindowName]) {
            var origOpenFunc = modulemapper.getOriginalSymbol(window, 'open');
            return origOpenFunc.apply(window, arguments);
        }

        strUrl = urlutil.makeAbsolute(strUrl);

        strWindowFeatures = strWindowFeatures || '';

        if (strWindowName === '_system') {
            // This is now separate as more-or-less fire and forget system browser was re-utilising
            // Code for blank/self. This caused problems with browser crashes etc.
            exec(null, null, "SystemBrowser", "open", [strUrl, strWindowName, strWindowFeatures]);
        } else {
            return new InAppBrowser(strUrl, strWindowName, strWindowFeatures, callbacks || {});
        }
    };
})();