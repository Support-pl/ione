const path = require("path");
module.exports = {
  chainWebpack: (config) => {
    config.resolve.alias.set("@", path.resolve(__dirname, "src"));
  },

  devServer: {
    host: "0.0.0.0",
    hot: true,
    disableHostCheck: true,
  },

  runtimeCompiler: true,
  productionSourceMap: false
};
