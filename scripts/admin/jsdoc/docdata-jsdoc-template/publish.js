/*global require: true */
(function () {
  'use strict';

  var fs = require('jsdoc/fs');
  var helper = require('jsdoc/util/templateHelper');

  var _ = require("underscore");
  var stringify = require("canonical-json");

  var names = [];
  var dataContents = {};

  /**
   * Get a tag dictionary from the tags field on the object, for custom fields
   * like package
   * @param  {JSDocData} data The thing you get in the TaffyDB from JSDoc
   * @return {Object}      Keys are the parameter names, values are the values.
   */
  var getTagDict = function (data) {
    var tagDict = {};

    if (data.tags) {
      _.each(data.tags, function (tag) {
        tagDict[tag.title] = tag.value;
      });
    }

    return tagDict;
  };

  var addToData = function (location, data) {
    _.extend(data, getTagDict(data));

    data.comment = undefined;
    data.___id = undefined;
    data.___s = undefined;
    data.tags = undefined;

    if (data.meta && data.meta.path) {
      var packagesFolder = 'packages/';
      var index = data.meta.path.indexOf(packagesFolder);
      if (index != -1) {
        var fullFilePath = data.meta.path.substr(index + packagesFolder.length) + '/' + data.meta.filename;
        data.filepath = fullFilePath;
        data.lineno = data.meta.lineno;
      }
    }

    data.meta = undefined;

    names.push(location);
    dataContents[location] = data;
  };

  /**
    @param {TAFFY} taffyData See <http://taffydb.com/>.
    @param {object} opts
    @param {Tutorial} tutorials
   */
  exports.publish = function(taffyData) {
    var data = helper.prune(taffyData);

    var namespaces = helper.find(data, {kind: "namespace"});

    // prepare all of the namespaces
    _.each(namespaces, function (namespace) {
      if (namespace.summary) {
        addToData(namespace.longname, namespace);
      }
    });

    var properties = helper.find(data, {kind: "member"});

    _.each(properties, function (property) {
      if (property.summary) {
        addToData(property.longname, property);
      }
    });

    // Callback descriptions are going to be embeded into Function descriptions
    // when they are used as arguments, so we always attach them to reference
    // them later.
    var callbacks = helper.find(data, {kind: "typedef"});
    _.each(callbacks, function (cb) {
      delete cb.comment;
      addToData(cb.longname, cb);
    });

    var functions = helper.find(data, {kind: "function"});
    var constructors = helper.find(data, {kind: "class"});

    // we want to do all of the same transformations to classes and functions
    functions = functions.concat(constructors);

    // insert all of the function data into the namespaces
    _.each(functions, function (func) {
      if (! func.summary) {
        // we use the @summary tag to indicate that an item is documented
        return;
      }

      func.options = [];
      var filteredParams = [];

      _.each(func.params, function (param) {
        param.name = param.name.replace(/,|\|/g, ", ");

        var splitName = param.name.split(".");

        if (splitName.length < 2 || splitName[0] !== "options") {
          // not an option
          filteredParams.push(param);
          return;
        }

        param.name = splitName[1];

        func.options.push(param);
      });

      func.params = filteredParams;

      // takes up too much room
      delete func.comment;

      addToData(func.longname, func);
    });

    // write full docs JSON
    var jsonString = stringify(dataContents, null, 2);
    var jsString = "DocsData = " + jsonString + ";";
    jsString = "// This file is automatically generated by JSDoc; regenerate it with scripts/admin/jsdoc/jsdoc.sh\n" + jsString;
    var docsDataFilename = "docs/client/data.js";
    fs.writeFileSync(docsDataFilename, jsString);

    // write name tree JSON
    jsonString = stringify(names.sort(), null, 2);
    var nameTreeFilename= "docs/client/names.json";
    fs.writeFileSync(nameTreeFilename, jsonString);
  };
})();