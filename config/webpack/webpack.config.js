const { existsSync } = require('fs')
const { resolve } = require('path')
const path = require("path")
const webpack = require("webpack")
const { merge, env } = require('shakapacker')

const envSpecificConfig = () => {
  const path = resolve(__dirname, `${env.nodeEnv}.js`)
  if (existsSync(path)) {
    console.log(`Loading ENV specific webpack configuration file ${path}`)
    return require(path)
  } else {
    throw new Error(`Could not find file to load ${path}, based on NODE_ENV`)
  }
}

const JSROOT = path.resolve(__dirname, '../..', 'app/javascript');

module.exports = merge(envSpecificConfig(), {
    performance: {
        hints: false,
    },
    plugins: [
        new webpack.ProvidePlugin({
            React: 'react',
        }),

        new webpack.DefinePlugin({
        }),

        env.isDevelopment && new (require('@pmmmwh/react-refresh-webpack-plugin'))({
            overlay: false,
        }),

        // new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),
    ].filter(Boolean),
    resolve: {
        alias: {
            '@': JSROOT,
            '@lib': path.join(JSROOT, "../../lib"),
        },
    }
})
