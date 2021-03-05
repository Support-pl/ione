const path = require("path");
module.exports = {
  chainWebpack: (config) => {
    config.resolve.alias.set("@", path.resolve(__dirname, "src"));
    config.plugin("html").tap((args) => {
      args[0].title = "IONe UI";
      return args;
    });
  },
  configureWebpack: {
    devtool: "source-map",
  },

  devServer: {
    host: "0.0.0.0",
    hot: true,
    disableHostCheck: true,
  },

  runtimeCompiler: true,
  productionSourceMap: false,
};
