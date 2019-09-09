"use strict";

var _interopRequireWildcard = require("@babel/runtime/helpers/interopRequireWildcard");

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _classCallCheck2 = _interopRequireDefault(require("@babel/runtime/helpers/classCallCheck"));

var _createClass2 = _interopRequireDefault(require("@babel/runtime/helpers/createClass"));

var _possibleConstructorReturn2 = _interopRequireDefault(require("@babel/runtime/helpers/possibleConstructorReturn"));

var _getPrototypeOf2 = _interopRequireDefault(require("@babel/runtime/helpers/getPrototypeOf"));

var _inherits2 = _interopRequireDefault(require("@babel/runtime/helpers/inherits"));

var _react = _interopRequireWildcard(require("react"));

var SearchResults =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(SearchResults, _Component);

  function SearchResults(props) {
    (0, _classCallCheck2["default"])(this, SearchResults);
    return (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(SearchResults).call(this, props));
  }

  (0, _createClass2["default"])(SearchResults, [{
    key: "render",
    value: function render() {
      return _react["default"].createElement("div", null, this.props.documents.map(function (doc, index) {
        return _react["default"].createElement("div", null, _react["default"].createElement("a", {
          key: index,
          href: "https://mallorn.dlib.indiana.edu/media_objects/" + doc['id']
        }, doc["title_tesi"]), _react["default"].createElement("dl", null, _react["default"].createElement("dt", null, "Date:"), _react["default"].createElement("dd", null, doc["date_ssi"]), _react["default"].createElement("dt", null, "Main Contributors:"), _react["default"].createElement("dd", null, doc["creator_ssim"]), _react["default"].createElement("dt", null, "Summary:"), _react["default"].createElement("dd", null, doc["summary_ssi"])));
      }));
    }
  }]);
  return SearchResults;
}(_react.Component);

var _default = SearchResults;
exports["default"] = _default;