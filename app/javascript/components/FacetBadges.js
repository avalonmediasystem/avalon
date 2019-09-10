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

var FacetBadges =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(FacetBadges, _Component);

  function FacetBadges(props) {
    var _this;

    (0, _classCallCheck2["default"])(this, FacetBadges);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(FacetBadges).call(this, props));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "handleClick", function (index, event) {
      event.preventDefault();
      console.log(index);

      var newAppliedFacets = _this.props.facets.slice();

      console.log(newAppliedFacets);
      newAppliedFacets.splice(index, 1);
      console.log(newAppliedFacets);

      _this.props.search.setState({
        appliedFacets: newAppliedFacets
      });
    });
    return _this;
  }

  (0, _createClass2["default"])(FacetBadges, [{
    key: "render",
    value: function render() {
      var _this2 = this;

      if (this.props.facets != []) {
        return _react["default"].createElement("div", {
          className: "mb-3"
        }, this.props.facets.map(function (facet, index) {
          if (facet.length === 0) {
            return _react["default"].createElement("div", null);
          }

          return _react["default"].createElement("div", {
            className: "btn-group mr-2",
            role: "group",
            "aria-label": "Facet badge"
          }, _react["default"].createElement("button", {
            "class": "btn btn-outline-secondary disabled"
          }, facet.facetLabel, ": ", facet.facetValue), _react["default"].createElement("button", {
            className: "btn btn-outline-secondary",
            onClick: function onClick(event) {
              return _this2.handleClick(index, event);
            }
          }, "\xD7"));
        }));
      } else {
        return _react["default"].createElement("div", null);
      }
    }
  }]);
  return FacetBadges;
}(_react.Component);

var _default = FacetBadges;
exports["default"] = _default;