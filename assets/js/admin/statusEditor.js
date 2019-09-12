import React, { PureComponent } from 'react';
import { render } from 'react-dom';

// const renderTable = name => {
//   const $table = document.getElementById(`${name}-table`);
//   if ($table.dataset.url) {
//     fetch($table.dataset.url)
//       .then(res => res.json())
//       .then(({columns, rows}) => {
//         render(
//           <ReactTable
//             data={mapRowDefinitions(columns, rows)}
//             columns={mapColumnDefinitions(columns)}
//             multiSort={true}
//             defaultFilterMethod={(filter, row, column) => {
//               const id = filter.pivotId || filter.id
//               return String(row[id]).toLowerCase().indexOf(filter.value.toLowerCase()) > -1
//             }}
//           />
//         , document.getElementById(`${name}-table`));
//       })
//   }

// }

document.addEventListener('DOMContentLoaded', e => {
  const $statusEditor = document.getElementById('status-editor');
  console.log($statusEditor);
  if ($statusEditor) {
    render(
      <div>
        <h1>Set app status here</h1>
        <form action="/admin/status" method="POST">
          <input type="hidden" name="_csrf_token" value={$statusEditor.dataset.token} />
          <select name="level">
            <option value="info">Info</option>
            <option value="warning">Warning</option>
            <option value="danger">Danger</option>
          </select>
          <textarea name="status"></textarea>
          <button type="submit">Soumettre</button>
        </form>
      </div>
    , $statusEditor)
  }
})



