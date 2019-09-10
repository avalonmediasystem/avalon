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

var _assertThisInitialized2 = _interopRequireDefault(require("@babel/runtime/helpers/assertThisInitialized"));

var _inherits2 = _interopRequireDefault(require("@babel/runtime/helpers/inherits"));

var _defineProperty2 = _interopRequireDefault(require("@babel/runtime/helpers/defineProperty"));

var _react = _interopRequireWildcard(require("react"));

var _types = require("@babel/types");

var _reactFontawesome = require("@fortawesome/react-fontawesome");

var _freeSolidSvgIcons = require("@fortawesome/free-solid-svg-icons");

var SearchResults =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(SearchResults, _Component);

  function SearchResults(props) {
    var _this;

    (0, _classCallCheck2["default"])(this, SearchResults);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(SearchResults).call(this, props));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "duration", function (ms) {
      if (Number(ms) > 0) return _this.millisecondsToFormattedTime(ms);
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "millisecondsToFormattedTime", function (ms) {
      var sec_num = ms / 1000;
      var hours = Math.floor(sec_num / 3600);
      var minutes = Math.floor(sec_num / 60);
      var seconds = sec_num - minutes * 60 - hours * 3600;
      var hourStr = hours < 10 ? "0".concat(hours) : "".concat(hours);
      var minStr = minutes < 10 ? "0".concat(minutes) : "".concat(minutes);
      var secStr = seconds.toFixed(0);
      secStr = seconds < 10 ? "0".concat(secStr) : "".concat(secStr);
      return "".concat(hourStr, ":").concat(minStr, ":").concat(secStr);
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "displayField", function (doc, fieldLabel, fieldName) {
      if (doc[fieldName]) {
        return _react["default"].createElement("div", null, _react["default"].createElement("span", {
          className: "field-name"
        }, fieldLabel), " ", doc[fieldName], _react["default"].createElement("br", null));
      }
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "thumbnailSrc", function (doc) {
      if (doc['section_id_ssim']) {
        return _this.props.baseUrl + "/master_files/" + doc['section_id_ssim'][0] + "/thumbnail";
      }
    });
    return _this;
  }

  (0, _createClass2["default"])(SearchResults, [{
    key: "render",
    value: function render() {
      var _this2 = this;

      return _react["default"].createElement("div", {
        className: "row"
      }, this.props.documents.map(function (doc, index) {
        return _react["default"].createElement("div", {
          className: "col-lg-4 col-sm-6"
        }, _react["default"].createElement("div", {
          key: index,
          className: "card mb-2 border-0"
        }, _react["default"].createElement("div", {
          className: "card-img-caption"
        }, _react["default"].createElement("p", {
          className: "timestamp badge badge-dark"
        }, _this2.duration(doc['duration_ssi'])), _react["default"].createElement("a", {
          href: _this2.props.baseUrl + "/media_objects/" + doc['id']
        }, _react["default"].createElement("img", {
          className: "card-img-top img-cover",
          src: _this2.thumbnailSrc(doc),
          alt: "Card image cap"
        }))), _react["default"].createElement("div", {
          className: "card-body pl-0 pr-0"
        }, _react["default"].createElement("h6", {
          className: "card-title"
        }, _react["default"].createElement("div", {
          className: "row"
        }, _react["default"].createElement("div", {
          className: "col-10 pr-0"
        }, _react["default"].createElement("a", {
          href: _this2.props.baseUrl + "/media_objects/" + doc['id']
        }, doc["title_tesi"])), _react["default"].createElement("div", {
          className: "col-2"
        }, _react["default"].createElement("a", {
          href: "#card-body-" + index,
          "data-toggle": "collapse",
          "data-target": "#card-body-" + index,
          role: "button",
          "aria-expanded": "false",
          "aria-controls": "card-body-" + index
        }, _react["default"].createElement(_reactFontawesome.FontAwesomeIcon, {
          icon: _freeSolidSvgIcons.faChevronDown
        }))))), _react["default"].createElement("p", {
          id: "card-body-" + index,
          className: "card-text collapse"
        }, _this2.displayField(doc, 'Date', 'date_ssi'), _this2.displayField(doc, 'Main Contributors', 'creator_ssim'), _this2.displayField(doc, 'Summary', 'summary_ssi')))));
      }));
    }
  }]);
  return SearchResults;
}(_react.Component);

var _default = SearchResults;
exports["default"] = _default;