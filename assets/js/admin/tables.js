import React, { PureComponent } from 'react';
import { render } from 'react-dom';

import ReactTable from 'react-table';
import 'react-table/react-table.css';

const mapColumnDefinitions = columns =>
  columns.map(columnName => ({
    accessor: columnName,
    Header: columnName,
    filterable: columnName.indexOf('name') > -1,
  }));

const mapRowDefinitions = (columns, rows) =>
  rows.map(row => row.reduce((obj, el, i) => {
    return Object.assign(obj, {[columns[i]]: el})
  }, {}));

const renderTable = name => {
  const $table = document.getElementById(`${name}-table`);
  if ($table.dataset.url) {
    fetch($table.dataset.url)
      .then(res => res.json())
      .then(({columns, rows}) => {
        render(
          <ReactTable
            data={mapRowDefinitions(columns, rows)}
            columns={mapColumnDefinitions(columns)}
            multiSort={true}
            defaultFilterMethod={(filter, row, column) => {
              const id = filter.pivotId || filter.id
              return String(row[id]).toLowerCase().indexOf(filter.value.toLowerCase()) > -1
            }}
          />
        , document.getElementById(`${name}-table`));
      })
  }

}

document.addEventListener('DOMContentLoaded', e => {
  renderTable('delegates');
  renderTable('certifications');
})



