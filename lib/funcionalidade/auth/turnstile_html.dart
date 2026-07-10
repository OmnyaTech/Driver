String buildTurnstileHtml({required String siteKey, required bool visible}) {
  final sizeValue = visible ? 'normal' : 'invisible';
  final appearanceValue = visible ? 'always' : 'interaction-only';
  final executionValue = visible ? 'render' : 'execute';

  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
    <style>
      body {
        margin: 0;
        padding: ${visible ? '12px' : '0'};
        background: ${visible ? '#0F172A' : 'transparent'};
        color: white;
        font-family: Arial, sans-serif;
      }
      #turnstile-container {
        ${visible ? '' : 'width:1px;height:1px;opacity:0.01;overflow:hidden;'}
      }
    </style>
  </head>
  <body>
    <div id="turnstile-container"></div>
    <script>
      (function () {
        const bridgeName = 'TurnstileBridge';
        const source = 'omnyadriver-turnstile';
        const visible = ${visible ? 'true' : 'false'};
        let widgetId = null;

        function emit(type, payload) {
          const message = JSON.stringify(Object.assign({ source, type }, payload || {}));
          if (window[bridgeName] && typeof window[bridgeName].postMessage === 'function') {
            window[bridgeName].postMessage(message);
          }
          if (window.parent && window.parent !== window) {
            window.parent.postMessage(message, '*');
          }
        }

        function renderWidget() {
          const container = document.getElementById('turnstile-container');
          if (!window.turnstile || !container) {
            emit('error', { code: 'turnstile-unavailable' });
            return;
          }

          const options = {
            sitekey: '$siteKey',
            appearance: '$appearanceValue',
            execution: '$executionValue',
            size: '$sizeValue',
            callback: function(token) {
              emit('success', { token: token, tokenLength: token ? token.length : 0 });
            },
            'error-callback': function(code) {
              emit('error', { code: code || 'turnstile-error' });
            },
            'expired-callback': function() {
              emit('expired', { code: 'turnstile-expired' });
            }
          };

          try {
            widgetId = window.turnstile.render(container, options);
            emit('rendered', { widgetId: widgetId, visible: visible });
            if (!visible) {
              window.turnstile.execute(widgetId);
              emit('executed', {});
            }
          } catch (error) {
            emit('error', { code: String(error || 'turnstile-render-error') });
          }
        }

        function waitForTurnstile() {
          if (window.turnstile) {
            renderWidget();
            return;
          }

          let attempts = 0;
          const timer = setInterval(function() {
            attempts += 1;
            if (window.turnstile) {
              clearInterval(timer);
              renderWidget();
            } else if (attempts > 150) {
              clearInterval(timer);
              emit('error', { code: 'turnstile-script-timeout' });
            }
          }, 200);
        }

        emit('boot', { visible: visible });
        waitForTurnstile();
      })();
    </script>
  </body>
</html>
''';
}
