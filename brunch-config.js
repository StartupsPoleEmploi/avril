exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^web\/static\/js|node_modules/,
        'js/vendor.js': ["web/static/vendor/awesomplete-util.min.js"],
        'js/analytics.js': /^(web\/static\/vendor\/analytics\.js)/,
        "js/ex_admin_common.js": ["web/static/vendor/ex_admin_common.js"],
        "js/admin_lte2.js": ["web/static/vendor/admin_lte2.js"],
        "js/jquery.min.js": ["web/static/vendor/jquery.min.js"],
        "js/simditor.min.js": ["web/static/vendor/simditor/module.min.js",
                               "web/static/vendor/simditor/hotkeys.min.js",
                               "web/static/vendor/simditor/uploader.min.js",
                               "web/static/vendor/simditor/simditor.min.js"],
         "js/jquery.multi-select.js": ["web/static/vendor/multiselect/jquery.multi-select.js"],
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(web\/static\/css)/,
        "css/admin_lte2.css": ["web/static/vendor/admin_lte2.css"],
        "css/active_admin.css.css": ["web/static/vendor/active_admin.css.css"],
        "css/simditor.css": ["web/static/vendor/simditor/simditor.css"],
        "css/multi-select.dist.css": ["web/static/vendor/multiselect/multi-select.dist.css"],
      },
      order: {
        after: ["web/static/css/app.scss"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },
  conventions: {
    assets: /^(web\/static\/assets)/
  },
  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "web/static",
      "test/static"
    ],
    // Where to compile files to
    public: "priv/static"
  },

  plugins: {
    babel: {
      ignore: [/web\/static\/vendor/]
    },
    copycat: {
      "fonts": ["node_modules/font-awesome/fonts"]
    },
    postcss: {
      options: {
        parser: require('postcss-scss'),
      },
      processors: [
       require('autoprefixer')(['last 8 versions']),
       require('csswring')()
      ]
    },
    sass: {
      options: {
        includePaths: ["node_modules/bootstrap/scss", "node_modules/font-awesome/scss"], // tell sass-brunch where to look for files to @import
        precision: 8 // minimum precision required by bootstrap-sass
      }
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: { // bootstrap-sass' JavaScript requires both '$' and 'jQuery' in global scope
      $: 'jquery',
      jQuery: 'jquery',
      Popper: 'popper.js',
      awesomplete: 'awesomplete',
      bootstrap: 'bootstrap' // require bootstrap-sass' JavaScript globally
    }
  }
}

// To add the ExAdmin generated assets to your brunch build, do the following:
//
// Replace
//
//     javascripts: {
//       joinTo: "js/app.js"
//     },
//
// With
//
//     javascripts: {
//       joinTo: {
//         "js/app.js": /^(web\/static\/js)|(node_modules)/,
//         "js/ex_admin_common.js": ["web/static/vendor/ex_admin_common.js"],
//         "js/admin_lte2.js": ["web/static/vendor/admin_lte2.js"],
//         "js/jquery.min.js": ["web/static/vendor/jquery.min.js"],
//       }
//     },
//
// Replace
//
//     stylesheets: {
//       joinTo: "css/app.css",
//       order: {
//         after: ["web/static/css/app.css"] // concat app.css last
//       }
//     },
//
// With
//
//     stylesheets: {
//       joinTo: {
//         "css/app.css": /^(web\/static\/css)/,
//         "css/admin_lte2.css": ["web/static/vendor/admin_lte2.css"],
//         "css/active_admin.css.css": ["web/static/vendor/active_admin.css.css"],
//       },
//       order: {
//         after: ["web/static/css/app.css"] // concat app.css last
//       }
//     },
//
