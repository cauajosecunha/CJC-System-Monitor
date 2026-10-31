const path = require('path');

module.exports = {
  apps: [
    {
      name: 'cjc-system-monitor-server',
      script: './dist/index.js',
      cwd: path.join(__dirname, 'server'),
      exec_mode: 'fork',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '300M',
      time: true,
      env: {
        NODE_ENV: 'production',
        PORT: 4080,
        HOST: '0.0.0.0',
        UPDATE_INTERVAL_MS: 1000,
        CORS_ORIGIN: '*',
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 4080,
        HOST: '0.0.0.0',
        UPDATE_INTERVAL_MS: 1000,
        CORS_ORIGIN: '*',
      },
    },
  ],
};
