import React from 'react';
import { Accordion, Card, Button, Table, Container, Row, Col } from 'react-bootstrap';

const EncodeJobView = ({ job }) => {
    console.log('JOB: ', job);
    const { errors, created_at, updated_at } = JSON.parse(job.raw_object);
    
    return(
        <React.Fragment>
            <h2>
                <strong>Job ID: </strong>
                {job.id}
            </h2>
            <p>
                <strong>Status: </strong>
                {job.state}
            </p>
            <p>
                <strong>Adapter: </strong>
                {job.adapter}
            </p>
            <p>
                <strong>Adapter Job ID: </strong>
                {job.global_id.split('/').reverse()[0]}
            </p>
            <p>
                <strong>Title: </strong>
                {job.display_title}
            </p>
            {errors.length > 0 ?
                (<p>
                    <strong>Error Message: </strong>
                    {errors[0]}
                </p>)
                : (<React.Fragment>
                    <p>
                        <strong>Job Started: </strong>
                        {created_at}
                    </p>
                    <p>
                        <strong>Job Terminated: </strong>
                        {updated_at}
                    </p>
                </React.Fragment>)
            }
            <p>
                <strong>Raw Object: </strong>
            </p>

            <div className="box box-default">
                <pre>{job.raw_object}</pre>
            </div>
        </React.Fragment>
    );

}

export default EncodeJobView;