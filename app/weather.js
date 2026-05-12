const express = require('express');
const bodyParser = require('body-parser');
const fetch = require('node-fetch');
const fs = require('fs');
const path = require('path');
const { URLSearchParams } = require('url');
const dotenv = require('dotenv');

const projectRoot = path.resolve(__dirname, '..');
const envFiles = [
  path.join(projectRoot, '.env.local'),
  path.join(projectRoot, '.env'),
  path.join(__dirname, '.env.local'),
  path.join(__dirname, '.env'),
];

for (const file of [...new Set(envFiles)]) {
  if (fs.existsSync(file)) {
    dotenv.config({ path: file });
  }
}

const {
  API_CITY,
  API_KEY,
  API_LANGUE,
  API_UNITS,
  CURRENT_BASE_URL,
  FORECAST_BASE_URL,
  OPENWEATHER_API_TOKEN,
  PORT = 3000,
} = process.env;
const weatherApiKey = API_KEY || process.env.OPENWEATHER_API_KEY;

const app = express();
app.use(express.static(path.join(__dirname, 'public')));
app.use(bodyParser.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

const defaultCity = API_CITY && API_CITY.trim() ? API_CITY.trim() : 'saint-jean-de-matha,ca';
let selectedCity = defaultCity;
let selectedDay = 'today';

const buildWeatherUrl = (baseUrl, city) => {
  const params = new URLSearchParams({ q: city });
  if (API_LANGUE) params.append('lang', API_LANGUE);
  if (API_UNITS) params.append('units', API_UNITS);
  if (weatherApiKey) params.append('appid', weatherApiKey);
  return `${baseUrl}?${params.toString()}`;
};

const buildWeatherUrlFromOptions = (baseUrl, options = {}) => {
  const params = new URLSearchParams();
  if (options.lat && options.lon) {
    params.append('lat', options.lat);
    params.append('lon', options.lon);
  } else {
    params.append('q', options.q || selectedCity);
  }
  if (options.lang || API_LANGUE) params.append('lang', options.lang || API_LANGUE);
  if (options.units || API_UNITS) params.append('units', options.units || API_UNITS);
  if (weatherApiKey) params.append('appid', weatherApiKey);
  return `${baseUrl}?${params.toString()}`;
};

const fetchJSON = async (url) => {
  const response = await fetch(url);
  return response.json();
};

const isSuccess = (payload) => Number(payload?.cod) === 200;
const viewModel = (page, data = []) => ({
  page,
  data,
  day: selectedDay,
  city: selectedCity,
});

const requireInternalApiToken = (req, res, next) => {
  const configuredToken = String(OPENWEATHER_API_TOKEN || '').trim();
  const providedToken = String(req.get('X-Internal-Api-Token') || '').trim();

  if (!configuredToken) {
    res.status(503).json({ detail: 'OPENWEATHER_API_TOKEN est manquant côté openweather.' });
    return;
  }

  if (!providedToken || providedToken !== configuredToken) {
    res.status(403).json({ detail: 'Accès météo dashboard non autorisé.' });
    return;
  }

  next();
};

const normalizeWeatherPayload = (currentPayload, forecastPayload) => {
  const cityName = String(currentPayload?.name || '').trim();
  const countryCode = String(currentPayload?.sys?.country || '').trim();
  const location = [cityName, countryCode].filter(Boolean).join(', ') || selectedCity;

  return {
    location,
    current: {
      temperature_c: currentPayload?.main?.temp ?? null,
      condition: currentPayload?.weather?.[0]?.description || '',
      icon: currentPayload?.weather?.[0]?.icon || '',
    },
    forecast: Array.isArray(forecastPayload?.list)
      ? forecastPayload.list.slice(0, 8).map((item) => ({
          starts_at: item?.dt_txt || '',
          temperature_c: item?.main?.temp ?? null,
          condition: item?.weather?.[0]?.description || '',
          icon: item?.weather?.[0]?.icon || '',
        }))
      : [],
  };
};

const fetchWeatherPayload = async (options = {}) => {
  const urls = [
    buildWeatherUrlFromOptions(CURRENT_BASE_URL, options),
    buildWeatherUrlFromOptions(FORECAST_BASE_URL, options),
  ];
  const [currentPayload, forecastPayload] = await Promise.all(urls.map(fetchJSON));

  if (!isSuccess(currentPayload) || !isSuccess(forecastPayload)) {
    throw new Error('OpenWeather payload invalid');
  }

  return normalizeWeatherPayload(currentPayload, forecastPayload);
};

app.get('/', async (req, res) => {
  try {
    const urls = [
      buildWeatherUrl(CURRENT_BASE_URL, selectedCity),
      buildWeatherUrl(FORECAST_BASE_URL, selectedCity),
    ];
    const responses = await Promise.all(urls.map(fetchJSON));
    const shouldRenderHome = responses.every(isSuccess);

    if (shouldRenderHome) {
      res.render('meteo', viewModel('home', responses));
      return;
    }

    res.render('error', viewModel('error', responses));
  } catch (error) {
    console.error('Failed to fetch weather data:', error);
    res.render('error', viewModel('error'));
  }
});

app.get('/location', (req, res) => {
  res.render('location', viewModel('location'));
});

app.get("/healthz", (req, res) => res.status(200).send("ok"));

app.get('/api/dashboard/weather/', requireInternalApiToken, async (req, res) => {
  try {
    const payload = await fetchWeatherPayload({
      q: String(req.query.q || '').trim(),
      lat: String(req.query.lat || '').trim(),
      lon: String(req.query.lon || '').trim(),
      units: String(req.query.units || '').trim(),
      lang: String(req.query.lang || '').trim(),
    });
    res.json(payload);
  } catch (error) {
    console.error('Failed to fetch dashboard weather payload:', error);
    res.status(502).json({ detail: 'Source météo indisponible.' });
  }
});


app.post('/', (req, res) => {
  const { button, city } = req.body;
  if (button) {
    selectedDay = button;
  }

  if (city && city.trim()) {
    selectedCity = city.trim();
  }

  res.redirect('/');
});

const port = Number(PORT) || 3000;
const host = "0.0.0.0";

app.listen(port, host, () => {
  console.log(`Server is running on http://${host}:${port}`);
});
