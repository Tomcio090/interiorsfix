"use strict";
(function () {
    const FRAME_NAMES = ['cctv', 'projector', 'killhouse', 'range', 'archive'];
    const frames = {};
    let activeFrame = null;

    const activeFeatures = {
        cctv: new Set(),
        projector: new Set(),
        killhouse: new Set(),
        range: new Set(),
        archive: new Set()
    };

    FRAME_NAMES.forEach((name) => {
        frames[name] = document.getElementById('neox-frame-' + name);
    });

    function clearAllFocus() {
        FRAME_NAMES.forEach((name) => {
            const f = frames[name];
            if (f) {
                f.classList.remove('is-focused', 'has-cursor');
            }
        });
        activeFrame = null;
    }

    function setFrameFocus(moduleName, withCursor) {
        clearAllFocus();
        const f = frames[moduleName];
        if (f) {
            f.classList.add('is-focused');
            if (withCursor) {
                f.classList.add('has-cursor');
            }
            activeFrame = moduleName;
            try {
                if (f.contentWindow) {
                    f.contentWindow.focus();
                }
            } catch (e) {}
        }
    }

    function blurFrame(moduleName) {
        if (activeFrame === moduleName || !moduleName) {
            clearAllFocus();
        } else if (frames[moduleName]) {
            frames[moduleName].classList.remove('is-focused', 'has-cursor');
        }
    }

    function updateFrameActiveState(moduleName) {
        const targetFrame = frames[moduleName];
        if (!targetFrame) return;
        const feats = activeFeatures[moduleName];
        if (feats && feats.size > 0) {
            targetFrame.classList.add('is-active');
        } else {
            targetFrame.classList.remove('is-active');
        }
    }

    window.addEventListener('message', (event) => {
        const msg = event.data;
        if (!msg || typeof msg !== 'object') return;
        const moduleName = msg.neox;
        const targetFrame = frames[moduleName];
        if (!targetFrame) return;

        switch (msg.action) {
        case 'msg':
            if (msg.data) {
                const type = msg.data.type || msg.data.action;
                const feats = activeFeatures[moduleName];

                if (type && feats) {
                    // Feature Activators
                    if (type === 'SHOW_UI' || type === 'UPDATE_UI') {
                        feats.add('ui');
                    } else if (type === 'SHOW_WEAPONS') {
                        feats.add('weapons');
                    } else if (type === 'SHOW_GTA_COUNTDOWN') {
                        feats.add('countdown');
                    } else if (type === 'showCCTVHud') {
                        feats.add('cctvHud');
                    } else if (type === 'openEditor') {
                        feats.add('editor');
                    } else if (type === 'openStandalone') {
                        feats.add('standalone');
                    } else if (type === 'open') {
                        feats.add('main');
                    } else if (type === 'SHOW_ARCHIVE') {
                        feats.add('archive');
                    }
                    // Feature Deactivators
                    else if (type === 'HIDE_UI') {
                        feats.delete('ui');
                    } else if (type === 'HIDE_WEAPONS') {
                        feats.delete('weapons');
                    } else if (type === 'HIDE_GTA_COUNTDOWN') {
                        feats.delete('countdown');
                    } else if (type === 'hideCCTVHud') {
                        feats.delete('cctvHud');
                    } else if (type === 'closeEditor') {
                        feats.delete('editor');
                    } else if (type === 'close') {
                        feats.delete('main');
                        feats.delete('standalone');
                        feats.delete('editor');
                    } else if (type === 'HIDE_ARCHIVE') {
                        feats.delete('archive');
                        feats.delete('main');
                    }

                    updateFrameActiveState(moduleName);
                }

                if (targetFrame.contentWindow) {
                    targetFrame.contentWindow.postMessage(msg.data, '*');
                }
            }
            break;

        case 'focus':
            setFrameFocus(moduleName, !!(msg.data && msg.data.cursor));
            break;

        case 'blur':
            blurFrame(moduleName);
            break;
        }
    });

    window.addEventListener('keydown', (e) => {
        if (!activeFrame) return;
        const f = frames[activeFrame];
        if (!f || !f.contentWindow) return;
        f.contentWindow.postMessage({
            _forwardKey: true,
            eventType: e.type,
            key: e.key,
            code: e.code,
            ctrl: e.ctrlKey,
            shift: e.shiftKey,
            alt: e.altKey
        }, '*');
    });

    window.addEventListener('paste', (e) => {
        if (!activeFrame) return;
        const f = frames[activeFrame];
        if (!f || !f.contentWindow) return;
        const text = (e.clipboardData || window.clipboardData)?.getData('text');
        if (text) {
            f.contentWindow.postMessage({
                _forwardPaste: true,
                text: text
            }, '*');
        }
    });
})();