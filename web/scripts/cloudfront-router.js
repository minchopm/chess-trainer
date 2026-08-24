function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // English is the site root, so /en is a second address for a page that
  // already has one. Angular's prerenderer leaves a meta-refresh document
  // there, which search engines usually read as a redirect; a 301 is what it
  // actually is, and "usually" is not a word to build indexing on.
  if (uri === '/en' || uri === '/en/') {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: '/' },
        'cache-control': { value: 'public,max-age=31536000' },
      },
    };
  }

  // The site is prerendered into directories: /privacy is /privacy/index.html
  // on S3. CloudFront's S3 REST origin does no index-document resolution of
  // its own, so a path with no file extension gets one here.
  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
  } else if (uri.lastIndexOf('.') <= uri.lastIndexOf('/')) {
    request.uri = uri + '/index.html';
  }

  return request;
}
