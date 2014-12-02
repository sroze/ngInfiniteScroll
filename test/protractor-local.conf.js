var config = require('./protractor-shared.conf').config;

config.multiCapabilities = [
  { browserName: 'chrome' }
];

exports.config = config;
