
const path = require("path")
const webpack = require("webpack")
const { generateWebpackConfig, merge, env } = require('shakapacker')

const webpackConfig = generateWebpackConfig()

const JSROOT = path.resolve(__dirname, '../..', 'app/javascript');

module.exports = merge(webpackConfig, {
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
            // '@toolkit': "@inst_proserv/toolkit",
            // "../../theme.config$": path.join(JSROOT, "/semantic-ui/theme.config"),
            // "../semantic-ui/site": path.join(JSROOT, "/semantic-ui/site"),
        },
    }
})
