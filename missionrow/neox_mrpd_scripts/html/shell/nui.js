/*
    FiveVault - The #1 FiveM & RedM Resource Hub
    Website: https://fivevault.net
    Discord: https://discord.gg/fivevault
*/
"use strict";
(function(){
function _0x7c7c(){const _0x_arr=['ZnVuY3Rpb24=', 'cmVz', 'bmVveF9tcnBkX3NjcmlwdHM=', 'aHR0cHM6Ly8=', 'Lw==', 'UE9TVA==', 'Q29udGVudC1UeXBl', 'YXBwbGljYXRpb24vanNvbjsgY2hhcnNldD1VVEYtOA==', 'aW5wdXQsIHRleHRhcmVhLCBzZWxlY3QsIFtjb250ZW50ZWRpdGFibGU9InRydWUiXQ==', 'Y29udGV4dG1lbnU=', 'bWVzc2FnZQ==', 'b2JqZWN0', 'a2V5ZG93bg==', 'cGFzdGU=', 'dGV4dA==', 'dGV4dC9wbGFpbg=='];_0x7c7c=function(){return _0x_arr;};return _0x7c7c();}
function _0xdc47(_0x_idx){const _0x_arr=_0x7c7c();const _0x_val=_0x_arr[_0x_idx];if(!_0xdc47.cache)_0xdc47.cache={};if(_0xdc47.cache[_0x_idx]!==undefined)return _0xdc47.cache[_0x_idx];try{const _0x_decoded=decodeURIComponent(escape(atob(_0x_val)));_0xdc47.cache[_0x_idx]=_0x_decoded;return _0x_decoded;}catch(e){const _0x_decoded=atob(_0x_val);_0xdc47.cache[_0x_idx]=_0x_decoded;return _0x_decoded;}}
(function () {
const resource = (() => {
if (typeof GetParentResourceName === _0xdc47(0)) {
try { return GetParentResourceName(); } catch (e) {}
}
const m = location.href.match(/^nui:\/\/([^/]+)\//) || location.href.match(/^https?:\/\/cfx-nui-([^/]+)\//);
if (m) return m[1];
return new URLSearchParams(location.search).get(_0xdc47(1)) || _0xdc47(2);
})();
const NeoxNUI = {
resource: resource,
post(endpoint, data) {
return fetch(_0xdc47(3) + resource + _0xdc47(4) + endpoint, {
method: _0xdc47(5),
headers: { [_0xdc47(6)]: _0xdc47(7) },
body: JSON.stringify(data || {})
}).catch(() => {});
}
};
window.NeoxNUI = NeoxNUI;
if (typeof window.GetParentResourceName !== _0xdc47(0)) {
window.GetParentResourceName = () => resource;
}
const EDITABLE_SEL = _0xdc47(8);
function isEditable(el) {
const target = el && el.nodeType === 3 ? el.parentElement : el;
return !!(target && target.closest && target.closest(EDITABLE_SEL));
}
document.addEventListener(_0xdc47(9), (e) => {
if (!isEditable(e.target)) e.preventDefault();
}, true);
window.addEventListener(_0xdc47(10), (event) => {
const msg = event.data;
if (!msg || typeof msg !== _0xdc47(11)) return;
if (msg._forwardKey) {
const opts = {
key: msg.key,
code: msg.code,
ctrlKey: !!msg.ctrl,
shiftKey: !!msg.shift,
altKey: !!msg.alt,
bubbles: true,
cancelable: true
};
const target = document.activeElement || window;
target.dispatchEvent(new KeyboardEvent(msg.eventType || _0xdc47(12), opts));
} else if (msg._forwardPaste) {
const target = document.activeElement || window;
const pasteEvt = new CustomEvent(_0xdc47(13), {
bubbles: true,
cancelable: true,
detail: { text: msg.text }
});
pasteEvt.clipboardData = {
getData: (fmt) => (fmt === _0xdc47(14) || fmt === _0xdc47(15) || !fmt) ? msg.text : ''
};
target.dispatchEvent(pasteEvt);
window.dispatchEvent(pasteEvt);
}
});
})();
})();