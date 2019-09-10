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

var Pagination =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(Pagination, _Component);

  function Pagination(props) {
    var _this;

    (0, _classCallCheck2["default"])(this, Pagination);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(Pagination).call(this, props));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "handleClick", function (page, event) {
      event.preventDefault();

      _this.props.search.setState({
        currentPage: page
      });
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "pageStart", function (pages) {
      return pages.offset_value + 1;
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "pageEnd", function (pages) {
      return Math.min(pages.offset_value + pages.limit_value, pages.total_count);
    });
    return _this;
  }

  (0, _createClass2["default"])(Pagination, [{
    key: "render",
    value: function render() {
      var _this2 = this;

      if (this.props.pages.total_count) {
        return _react["default"].createElement("div", {
          className: "sort-pagination"
        }, this.props.pages.prev_page != null ? _react["default"].createElement("a", {
          href: "#",
          onClick: function onClick(event) {
            return _this2.handleClick(_this2.props.pages.prev_page, event);
          }
        }, "Previous") : _react["default"].createElement("span", null, "Previous"), _react["default"].createElement("span", null, " | ", this.pageStart(this.props.pages), "-", this.pageEnd(this.props.pages), " of ", this.props.pages.total_count, " | "), this.props.pages.next_page != null ? _react["default"].createElement("a", {
          href: "#",
          onClick: function onClick(event) {
            return _this2.handleClick(_this2.props.pages.next_page, event);
          }
        }, "Next") : _react["default"].createElement("span", null, "Next"));
      } else if (this.props.pages.total_count === 0) {
        return _react["default"].createElement("p", null, "No results matched your search.");
      } else {
        return _react["default"].createElement("div", null);
      }
    }
  }]);
  return Pagination;
}(_react.Component);

var _default = Pagination;
exports["default"] = _default;