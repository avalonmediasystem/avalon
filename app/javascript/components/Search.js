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

var _axios = _interopRequireDefault(require("axios"));

var _SearchResults = _interopRequireDefault(require("./SearchResults"));

var _Pagination = _interopRequireDefault(require("./Pagination"));

var _Facets = _interopRequireDefault(require("./Facets"));

var _FacetBadges = _interopRequireDefault(require("./FacetBadges"));

var Search =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(Search, _Component);

  function Search(props) {
    var _this;

    (0, _classCallCheck2["default"])(this, Search);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(Search).call(this, props));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "handleQueryChange", function (event) {
      _this.setState({
        query: event.target.value,
        currentPage: 1
      });
    });
    _this.state = {
      query: "",
      searchResult: {
        pages: {},
        docs: [],
        facets: []
      },
      currentPage: 1,
      appliedFacets: [],
      perPage: 12
    };
    return _this;
  }

  (0, _createClass2["default"])(Search, [{
    key: "componentDidMount",
    value: function componentDidMount() {
      this.retrieveResults();
    }
  }, {
    key: "componentDidUpdate",
    value: function componentDidUpdate(prevProps, prevState) {
      if (prevState.query != this.state.query || prevState.currentPage != this.state.currentPage || prevState.appliedFacets != this.state.appliedFacets) {
        this.retrieveResults();
      }
    }
  }, {
    key: "retrieveResults",
    value: function retrieveResults() {
      var component = this;
      var facetFilters = "";
      this.state.appliedFacets.forEach(function (facet) {
        facetFilters = facetFilters + "&f[" + facet.facetField + "][]=" + facet.facetValue;
      });

      if (this.props.collection) {
        facetFilters = facetFilters + "&f[collection_ssim][]=" + this.props.collection;
      }

      var url = this.props.baseUrl + "/catalog.json?per_page=" + this.state.perPage + "&q=" + this.state.query + "&page=" + this.state.currentPage + facetFilters;
      console.log("Performing search: " + url);
      (0, _axios["default"])({
        url: url
      }).then(function (response) {
        console.log(response);
        component.setState({
          searchResult: response.data.response
        });
      });
    }
  }, {
    key: "availableFacets",
    value: function availableFacets() {
      var availableFacets = this.state.searchResult.facets.slice();
      var facetIndex = availableFacets.findIndex(function (facet) {
        return facet.label === "Published";
      });

      if (facetIndex > -1) {
        availableFacets.splice(facetIndex, 1);
      }

      facetIndex = availableFacets.findIndex(function (facet) {
        return facet.label === "Created by";
      });

      if (facetIndex > -1) {
        availableFacets.splice(facetIndex, 1);
      }

      facetIndex = availableFacets.findIndex(function (facet) {
        return facet.label === "Date Digitized";
      });

      if (facetIndex > -1) {
        availableFacets.splice(facetIndex, 1);
      }

      facetIndex = availableFacets.findIndex(function (facet) {
        return facet.label === "Date Ingested";
      });

      if (facetIndex > -1) {
        availableFacets.splice(facetIndex, 1);
      }

      if (this.props.collection) {
        facetIndex = availableFacets.findIndex(function (facet) {
          return facet.label === "Collection";
        });
        availableFacets.splice(facetIndex, 1);
        facetIndex = availableFacets.findIndex(function (facet) {
          return facet.label === "Unit";
        });
        availableFacets.splice(facetIndex, 1);
      }

      return availableFacets;
    }
  }, {
    key: "render",
    value: function render() {
      var query = this.state.query;
      return _react["default"].createElement("div", null, _react["default"].createElement("form", {
        className: "container"
      }, _react["default"].createElement("label", {
        htmlFor: "q",
        className: "sr-only"
      }, "search for"), _react["default"].createElement("div", {
        className: "input-group"
      }, _react["default"].createElement("input", {
        value: query,
        onChange: this.handleQueryChange,
        name: "q",
        className: "form-control",
        placeholder: "Search...",
        autoFocus: "autofocus"
      }))), _react["default"].createElement("div", {
        className: "row"
      }, _react["default"].createElement("section", {
        className: "col-md-9"
      }, _react["default"].createElement(_FacetBadges["default"], {
        facets: this.state.appliedFacets,
        search: this
      }), _react["default"].createElement(_Pagination["default"], {
        pages: this.state.searchResult.pages,
        search: this
      }), _react["default"].createElement(_SearchResults["default"], {
        documents: this.state.searchResult.docs,
        baseUrl: this.props.baseUrl
      })), _react["default"].createElement("section", {
        className: "col-md-3"
      }, _react["default"].createElement(_Facets["default"], {
        facets: this.availableFacets(),
        search: this
      }))));
    }
  }]);
  return Search;
}(_react.Component);

var _default = Search;
exports["default"] = _default;