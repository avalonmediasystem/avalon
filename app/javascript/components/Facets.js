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

var Facets =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(Facets, _Component);

  function Facets(props) {
    var _this;

    (0, _classCallCheck2["default"])(this, Facets);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(Facets).call(this, props));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "handleClick", function (facetField, facetLabel, item, event) {
      event.preventDefault();

      var newAppliedFacets = _this.props.search.state.appliedFacets.concat([{
        facetField: facetField,
        facetLabel: facetLabel,
        facetValue: item.value
      }]);

      console.log(newAppliedFacets);

      _this.props.search.setState({
        appliedFacets: newAppliedFacets,
        currentPage: 1
      });
    });
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "isFacetApplied", function (facet, item) {
      var index = _this.props.search.state.appliedFacets.findIndex(function (appliedFacet) {
        return appliedFacet.facetField === facet.name && appliedFacet.facetValue === item.value;
      });

      return index != -1;
    });
    return _this;
  }

  (0, _createClass2["default"])(Facets, [{
    key: "render",
    value: function render() {
      var _this2 = this;

      if (this.props.facets != {}) {
        return _react["default"].createElement("div", null, this.props.facets.map(function (facet, index) {
          if (facet.items.length === 0) {
            return _react["default"].createElement("div", null);
          }

          return _react["default"].createElement("div", {
            className: "card mb-3"
          }, _react["default"].createElement("h5", {
            className: "card-header collapse-toggle"
          }, _react["default"].createElement("a", null, facet.label)), _react["default"].createElement("div", {
            className: "card-body"
          }, _react["default"].createElement("ul", {
            className: "facet-values list-unstyled"
          }, facet.items.map(function (item, index) {
            return _react["default"].createElement("li", null, _this2.isFacetApplied(facet, item) ? _react["default"].createElement("span", {
              className: "facet-label"
            }, item.label) : _react["default"].createElement("a", {
              href: "",
              onClick: function onClick(event) {
                return _this2.handleClick(facet.name, facet.label, item, event);
              }
            }, _react["default"].createElement("span", {
              className: "facet-label"
            }, item.label)), _react["default"].createElement("span", {
              className: "facet-count"
            }, " (", item.hits, ")"));
          }))));
        }));
      } else {
        return _react["default"].createElement("div", null);
      }
    }
  }]);
  return Facets;
}(_react.Component);

var _default = Facets;
exports["default"] = _default;