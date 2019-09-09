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

var Search =
/*#__PURE__*/
function (_Component) {
  (0, _inherits2["default"])(Search, _Component);

  function Search() {
    var _this;

    (0, _classCallCheck2["default"])(this, Search);
    _this = (0, _possibleConstructorReturn2["default"])(this, (0, _getPrototypeOf2["default"])(Search).call(this));
    (0, _defineProperty2["default"])((0, _assertThisInitialized2["default"])(_this), "handleQueryChange", function (event) {
      _this.setState({
        query: event.target.value
      });
    });
    _this.state = {
      query: "",
      documents: [],
      pages: {},
      currentPage: 1,
      facets: []
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
      if (prevState.query != this.state.query || prevState.currentPage != this.state.currentPage) {
        this.retrieveResults();
      }
    }
  }, {
    key: "retrieveResults",
    value: function retrieveResults() {
      var component = this;
      var url = "https://mallorn.dlib.indiana.edu/catalog.json?q=" + this.state.query + "&page=" + this.state.currentPage;
      (0, _axios["default"])({
        url: url
      }).then(function (response) {
        console.log(response);
        component.setState({
          documents: response.data.response.docs,
          pages: response.data.response.pages,
          facets: response.data.response.facets
        });
      });
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
      }, _react["default"].createElement(_Pagination["default"], {
        pages: this.state.pages,
        search: this
      }), _react["default"].createElement(_SearchResults["default"], {
        documents: this.state.documents
      })), _react["default"].createElement("section", {
        className: "col-md-3"
      }, _react["default"].createElement(_Facets["default"], {
        facets: this.state.facets,
        search: this
      }))));
    }
  }]);
  return Search;
}(_react.Component);

var _default = Search;
exports["default"] = _default;