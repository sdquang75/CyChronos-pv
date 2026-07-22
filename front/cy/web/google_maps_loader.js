(() => {
  const apiKey = window.GOOGLE_MAPS_API_KEY;

  if (
    typeof apiKey !== 'string' ||
    apiKey.length === 0 ||
    apiKey === 'YOUR_MAPS_API_KEY'
  ) {
    throw new Error(
      'Google Maps API key is missing. Copy maps_api_key.example.js to maps_api_key.js and set the key.',
    );
  }

  const scriptUrl = new URL('https://maps.googleapis.com/maps/api/js');
  scriptUrl.searchParams.set('key', apiKey);

  // Keep loading parser-blocking so Google Maps is ready before Flutter starts.
  document.write(`<script src="${scriptUrl}"><\/script>`);
})();
