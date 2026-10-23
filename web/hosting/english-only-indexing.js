// English-only search policy, including already-published translated news.
// Runs after the normal request router and does not change content or access.
var excluded = ["en-ca", "ar", "cs", "da", "de", "el", "es", "fi", "fr", "fr-ca", "he", "hi", "hu", "id", "it", "ja", "ko", "ms", "nl", "no", "pl", "pt-br", "ro", "ru", "sv", "th", "tr", "vi", "zh-hans", "zh-hant", "bg"];
function handler(event) {
  var response = event.response;
  var prefix = event.request.uri.split('/')[1].toLowerCase();
  if (excluded.indexOf(prefix) !== -1) {
    response.headers['x-robots-tag'] = {value: 'noindex, follow'};
  }
  return response;
}
