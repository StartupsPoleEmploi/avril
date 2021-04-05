import React, { PureComponent } from 'react';
import { render } from 'react-dom';

import ReactTable from 'react-table';
import 'react-table/react-table.css';
import {CSVLink, CSVDownload} from 'react-csv';


const mapColumnDefinitions = columns =>
  columns.map(columnName => ({
    accessor: columnName,
    Header: columnName,
    filterable: columnName.indexOf('name') > -1,
    className: 'text-left',
  }));

const mapRowDefinitions = (columns, rows) =>
  rows.map(row => row.reduce((obj, el, i) => {
    return Object.assign(obj, {[columns[i]]: el})
  }, {}));

const displayRecordCount = state => {
  const { filtered, pageRows, pageSize, sortedData, page } = state;

  if (sortedData && sortedData.length > 0) {
    const isFiltered = filtered.length > 0;
    const totalRecords = sortedData.length;
    const recordsCountFrom = page * pageSize + 1;
    const recordsCountTo = recordsCountFrom + pageRows.length - 1;
    return `${recordsCountFrom}-${recordsCountTo} of ${totalRecords} ${isFiltered ? 'filtered ' : ''}records`;
  } else return "No records";
}

const makeTableWithCount = (state, makeTable) => {
  return (
    <div className="main-grid">
      <p className="text-left">{displayRecordCount(state)}</p>
      {makeTable()}
    </div>
  );
}

const renderTable = name => {
  const $table = document.getElementById(`${name}-table`);
  if ($table && $table.dataset.url) {
    fetch($table.dataset.url)
      .then(res => res.json())
      .then(({columns, rows}) => {
        render(
          <div>
            <div className="text-right">
              <CSVLink
                data={mapRowDefinitions(columns, rows)}
                className="btn btn-primary"
                style={{marginBottom: '1rem'}}
                download={`${name}.csv`}
              >Télécharger en CSV</CSVLink>
            </div>
            <ReactTable
              data={mapRowDefinitions(columns, rows)}
              columns={mapColumnDefinitions(columns)}
              multiSort={true}
              defaultFilterMethod={(filter, row, column) => {
                const id = filter.pivotId || filter.id
                return String(row[id]).toLowerCase().indexOf(filter.value.toLowerCase()) > -1
              }}
            >
              {(state, makeTable) => makeTableWithCount(state, makeTable)}
            </ReactTable>
          </div>
        , document.getElementById(`${name}-table`));
      })
  }

}

document.addEventListener('DOMContentLoaded', e => {
  renderTable('delegates');
  renderTable('certifications');
})



