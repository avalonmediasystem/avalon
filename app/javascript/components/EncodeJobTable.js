import React from 'react';
import PropTypes from 'prop-types';
import { makeStyles, useTheme } from '@material-ui/core/styles';
import {
  Table,
  TableBody,
  TableHead,
  TableCell,
  TableFooter,
  TableRow,
  Paper,
  IconButton,
  TableSortLabel,
  TablePagination
} from '@material-ui/core';
import FirstPageIcon from '@material-ui/icons/FirstPage';
import KeyboardArrowLeft from '@material-ui/icons/KeyboardArrowLeft';
import KeyboardArrowRight from '@material-ui/icons/KeyboardArrowRight';
import LastPageIcon from '@material-ui/icons/LastPage';
import { ProgressBar, Form } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const COLUMN_HEADERS = [
  { propName: 'state', colName: 'Status' },
  { propName: 'id', colName: 'ID' },
  { propName: 'progress', colName: 'Progress' },
  { propName: 'display_title', colName: 'Filename' },
  { propName: 'master_file_id', colName: 'MasterFile' },
  { propName: 'media_object_id', colName: 'MediaObject' },
  { propName: 'created_at', colName: 'Job Started' }
];

const tableStyles = makeStyles(theme => ({
  root: {
    width: '100%',
    marginTop: theme.spacing(3)
  },
  table: {
    minWidth: 500
  },
  tableWrapper: {
    overflowX: 'auto'
  },
  visuallyHidden: {
    border: 0,
    clip: 'rect(0 0 0 0)',
    height: 1,
    margin: -1,
    overflow: 'hidden',
    padding: 0,
    position: 'absolute',
    top: 20,
    width: 1
  },
  tableCell: {
    fontSize: '1.5rem',
    padding: '14px 14px 14px 14px',
    border: 'groove',
    borderWidth: 'thin'
  }
}));

const paginationStyles = makeStyles(() => ({
  caption: {
    fontSize: '1.5rem'
  },
  selectRoot: {
    fontSize: '1.5rem'
  },
  selectIcon: {
    fontSize: '2.5rem'
  }
}));

export default function EncodeJobTable(props) {
  const { rows, baseUrl } = props;
  const classes = tableStyles();
  const paginationClasses = paginationStyles();
  const [page, setPage] = React.useState(0);
  const [rowsPerPage, setRowsPerPage] = React.useState(5);
  const [order, setOrder] = React.useState('asc');
  const [orderBy, setOrderBy] = React.useState('id');
  const [search, setSearch] = React.useState('');
  const [filteredRows, setFilteredRows] = React.useState(rows);

  const emptyRows =
    rowsPerPage - Math.min(rowsPerPage, rows.length - page * rowsPerPage);

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = event => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleRequestSort = (event, property) => {
    const isDesc = orderBy === property && order === 'desc';
    setOrder(isDesc ? 'asc' : 'desc');
    setOrderBy(property);
  };

  const handleSearch = event => {
    const query = event.target.value.toLowerCase();
    let filteredData = [];
    filteredData = rows.filter(e => {
      let retVal = false;
      const {
        state,
        id,
        display_title,
        master_file_id,
        media_object_id,
        created_at
      } = e;
      const searchThrough = [
        state,
        id,
        display_title,
        master_file_id,
        media_object_id,
        created_at
      ];
      searchThrough.find(item => {
        if (typeof item == 'string' && item.toLowerCase().includes(query)) {
          retVal = true;
        }
      });
      return retVal;
    });

    setSearch(event.target.value);
    setFilteredRows(filteredData);
  };

  const setStatus = state => {
    switch (state) {
      case 'completed':
        return <FontAwesomeIcon icon="check-circle" />;
      case 'running':
        return <FontAwesomeIcon icon="spinner" />;
      default:
        return <FontAwesomeIcon icon="times-circle" />;
    }
  };

  const setLink = (propName, row) => {
    if (propName === 'master_file_id') {
      return (
        <a
          href={`${baseUrl}/media_objects/${row.media_object_id}/section/${row.master_file_id}`}
        >
          {row.master_file_id}
        </a>
      );
    }
    if (propName === 'media_object_id') {
      return (
        <a href={`${baseUrl}/media_objects/${row.media_object_id}`}>
          {row.media_object_id}
        </a>
      );
    }
  };

  const formatDate = row => {
    const date = new Date(row.created_at);
    row.created_at = date.toLocaleString();
    return row.created_at;
  };

  return (
    <React.Fragment>
      <h1>Transcoding Dashboard</h1>
      <Paper className={classes.root}>
        <EnhancedTableToolbar
          handleSearch={handleSearch}
          searchQuery={search}
        />
        <div className={classes.tableWrapper}>
          <Table className={classes.table} aria-label="custom pagination table">
            <EnhancedTableHead
              classes={classes}
              order={order}
              orderBy={orderBy}
              onRequestSort={handleRequestSort}
              rowCount={filteredRows.length}
            />
            <TableBody>
              {stableSort(filteredRows, getSorting(order, orderBy))
                .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                .map(row => (
                  <TableRow key={row.id}>
                    <TableCell
                      className={classes.tableCell}
                      align="center"
                      component="th"
                      scope="row"
                    >
                      {setStatus(row.state)}
                    </TableCell>
                    <TableCell className={classes.tableCell} align="center">
                      <Link to={`/encode_records/${row.id}`}>{row.id}</Link>
                    </TableCell>
                    <TableCell className={classes.tableCell} align="left">
                      <ProgressBar
                        now={row.progress}
                        label={`${row.progress}%`}
                      />
                    </TableCell>
                    <TableCell className={classes.tableCell} align="left">
                      {row.display_title}
                    </TableCell>
                    <TableCell className={classes.tableCell} align="center">
                      {setLink('master_file_id', row)}
                    </TableCell>
                    <TableCell className={classes.tableCell} align="center">
                      {setLink('media_object_id', row)}
                    </TableCell>
                    <TableCell className={classes.tableCell} align="center">
                      {formatDate(row)}
                    </TableCell>
                  </TableRow>
                ))}

              {emptyRows > 0 && (
                <TableRow style={{ height: 53 * emptyRows }}>
                  <TableCell colSpan={6} />
                </TableRow>
              )}
            </TableBody>
            <TableFooter>
              <TableRow>
                <TablePagination
                  rowsPerPageOptions={[3, 5, 10, 25, 50]}
                  colSpan={3}
                  count={filteredRows.length}
                  rowsPerPage={rowsPerPage}
                  page={page}
                  SelectProps={{
                    inputProps: { 'aria-label': 'rows per page' },
                    native: true
                  }}
                  classes={paginationClasses}
                  onChangePage={handleChangePage}
                  onChangeRowsPerPage={handleChangeRowsPerPage}
                  ActionsComponent={TablePaginationActions}
                />
              </TableRow>
            </TableFooter>
          </Table>
        </div>
      </Paper>
    </React.Fragment>
  );
}

// Table header component with sorting
function desc(a, b, orderBy) {
  if (b[orderBy] < a[orderBy]) {
    return -1;
  }
  if (b[orderBy] > a[orderBy]) {
    return 1;
  }
  return 0;
}

function stableSort(array, cmp) {
  const stabilizedThis = array.map((el, index) => [el, index]);
  stabilizedThis.sort((a, b) => {
    const order = cmp(a[0], b[0]);
    if (order !== 0) return order;
    return a[1] - b[1];
  });
  return stabilizedThis.map(el => el[0]);
}

function getSorting(order, orderBy) {
  return order === 'desc'
    ? (a, b) => desc(a, b, orderBy)
    : (a, b) => -desc(a, b, orderBy);
}

function EnhancedTableHead(props) {
  const { classes, order, orderBy, onRequestSort } = props;
  const createSortHandler = property => event => {
    onRequestSort(event, property);
  };

  return (
    <TableHead>
      <TableRow>
        {COLUMN_HEADERS.map(colHeader => (
          <TableCell
            className={classes.tableCell}
            key={colHeader.propName}
            sortDirection={orderBy === colHeader.propName ? order : false}
          >
            <TableSortLabel
              active={orderBy === colHeader.propName}
              direction={order}
              onClick={createSortHandler(colHeader.propName)}
            >
              {colHeader.colName}
              {orderBy === colHeader.propName ? (
                <span className={classes.visuallyHidden}>
                  {order === 'desc' ? 'sorted descending' : 'sorted ascending'}
                </span>
              ) : null}
            </TableSortLabel>
          </TableCell>
        ))}
      </TableRow>
    </TableHead>
  );
}

EnhancedTableHead.propTypes = {
  classes: PropTypes.object.isRequired,
  onRequestSort: PropTypes.func.isRequired,
  order: PropTypes.oneOf(['asc', 'desc']).isRequired,
  orderBy: PropTypes.string.isRequired
};

// Pagination component for the table
const paginationActionStyles = makeStyles(theme => ({
  root: {
    flexShrink: 0,
    marginLeft: theme.spacing(2.5)
  },
  disabled: {
    color: 'red',
    backgroundColor: 'green'
  }
}));

function TablePaginationActions(props) {
  const classes = paginationActionStyles();
  const theme = useTheme();
  const { count, page, rowsPerPage, onChangePage } = props;

  const handleFirstPageButtonClick = event => {
    onChangePage(event, 0);
  };

  const handleBackButtonClick = event => {
    onChangePage(event, page - 1);
  };

  const handleNextButtonClick = event => {
    onChangePage(event, page + 1);
  };

  const handleLastPageButtonClick = event => {
    onChangePage(event, Math.max(0, Math.ceil(count / rowsPerPage) - 1));
  };

  return (
    <div className={classes.root}>
      <IconButton
        onClick={handleFirstPageButtonClick}
        disabled={page === 0}
        aria-label="first page"
      >
        {theme.direction === 'rtl' ? <LastPageIcon /> : <FirstPageIcon />}
      </IconButton>
      <IconButton
        onClick={handleBackButtonClick}
        disabled={page === 0}
        aria-label="previous page"
      >
        {theme.direction === 'rtl' ? (
          <KeyboardArrowRight />
        ) : (
          <KeyboardArrowLeft />
        )}
      </IconButton>
      <IconButton
        onClick={handleNextButtonClick}
        disabled={page >= Math.ceil(count / rowsPerPage) - 1}
        aria-label="next page"
      >
        {theme.direction === 'rtl' ? (
          <KeyboardArrowLeft />
        ) : (
          <KeyboardArrowRight />
        )}
      </IconButton>
      <IconButton
        onClick={handleLastPageButtonClick}
        disabled={page >= Math.ceil(count / rowsPerPage) - 1}
        aria-label="last page"
      >
        {theme.direction === 'rtl' ? <FirstPageIcon /> : <LastPageIcon />}
      </IconButton>
    </div>
  );
}

TablePaginationActions.propTypes = {
  count: PropTypes.number.isRequired,
  onChangePage: PropTypes.func.isRequired,
  page: PropTypes.number.isRequired,
  rowsPerPage: PropTypes.number.isRequired
};

// Search toolbar for the table
const tableToolbarStyles = makeStyles(theme => ({
  root: {
    width: '25%',
    marginTop: theme.spacing(3),
    overflowX: 'auto'
  }
}));

function EnhancedTableToolbar(props) {
  const { handleSearch, searchQuery } = props;
  const classes = tableToolbarStyles();

  const searchHandler = event => {
    handleSearch(event);
  };

  return (
    <Form className={classes.root}>
      <Form.Group controlId="search">
        <Form.Control
          type="text"
          placeholder="Search..."
          onChange={e => searchHandler(e)}
          value={searchQuery}
        />
      </Form.Group>
    </Form>
  );
}

EnhancedTableToolbar.propTypes = {
  handleSearch: PropTypes.func.isRequired,
  searchQuery: PropTypes.string.isRequired
};
