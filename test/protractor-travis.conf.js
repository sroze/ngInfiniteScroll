var config = require('./protractor-shared.conf').config;

// All available platform / browser combinations can be found on https://saucelabs.com/platforms
config.multiCapabilities = [
  {
    browserName: 'chrome',
    platform: 'OS X 10.10',
    version: '37'
  }
];

exports.config = config;
