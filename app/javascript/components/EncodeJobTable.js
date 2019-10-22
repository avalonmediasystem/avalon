import React, { Component } from 'react';
import { Table, ProgressBar, Form, Row, Col } from 'react-bootstrap';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { Link } from 'react-router-dom';
import axios from 'axios';

const COLUMN_HEADERS = [{propName: 'state', colName: 'Status'}, { propName: 'id', colName: 'ID'}, { propName: 'progress', colName: 'Progress'}
, { propName: 'display_title', colName: 'Filename'}, {propName: 'master_file_id', colName: 'MasterFile'}, { propName: 'media_object_id', colName: 'MediaObject'}
, { propName: 'created_at', colName: 'Job Started'}];

class EncodeJobTable extends Component {
    constructor(props) {
        super(props);
        this.state = {
            encodeJobs: this.props.rows,
            sort: {
                column: null,
                direction: 'desc'
            },
            search: ''
        }
    }

    renderTableRows() {
        return this.state.encodeJobs.map((job) => {
            const { state, id, progress, display_title, master_file_id, media_object_id, created_at } = job;
            let jobState = null;
            switch(state) {
                case 'failed':
                jobState = <FontAwesomeIcon icon="times-circle"/>;
                break;
                case 'running':
                jobState = <FontAwesomeIcon icon="spinner"/>;
                break;
                default:
                jobState = <FontAwesomeIcon icon="check-circle"/>;
            }
            return (
                <tr key={id}>
                    <td>{jobState}</td>
                    <td><Link to={`/encode_records/${id}`}>{id}</Link></td>
                    <td><ProgressBar now={progress} label={`${progress}%`} /></td>
                    <td className="left-align">{display_title}</td>
                    <td>{master_file_id}</td>
                    <td>{media_object_id}</td>
                    <td>{created_at}</td>
                </tr>
            )
        });
    }

    renderTableHeader(column, index) {
        const { propName, colName } = column;
        return (
            <th key={index} onClick={e => this.sortColumn(propName)}>
                {colName}
                <span className={this.setArrow(propName)}></span>
            </th>
        );
    }

    setArrow = (column) => {
        let className = 'sort-direction';
        
        if (this.state.sort.column === column) {
            className += this.state.sort.direction === 'asc' ? ' asc' : ' desc';
        }
        return className;
    };

    sortColumn(column) {
        const direction = this.state.sort.column ? (this.state.sort.direction === 'asc' ? 'desc' : 'asc') : 'desc';
        const self = this;
        const { encodeJobs } = this.state;
        encodeJobs.sort(function(x, y){
            if(x[column] < y[column]) { return -1; }
            if(x[column] > y[column]) { return 1; }
            return 0;
        });
        if(direction === 'desc') {
            this.state.encodeJobs.reverse();
        }
        self.setState({ encodeJobs, sort: { column, direction} });
    }

    handleChange = (event) => {
        this.setState({ search: event.target.value });
        console.log(this.state.search);
    }

    render() {
        const { search } = this.state;
        return (
            <React.Fragment>
                <Form className="pull-right">
                    <Row>
                        <Col>
                            <Form.Control placeholder="Search" onChange={this.handleChange} value={search} />
                        </Col>
                    </Row>
                </Form>
                <Table striped bordered hover>
                    <thead>
                        <tr>
                            { COLUMN_HEADERS.map((col, index) => {
                                return this.renderTableHeader(col, index);
                            })}
                        </tr>
                    </thead>
                    <tbody>
                        {this.renderTableRows()}
                    </tbody>
                </Table>
            </React.Fragment>
        );
    }
}

export default EncodeJobTable;