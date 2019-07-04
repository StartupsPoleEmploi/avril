import React, { PureComponent } from 'react';
import ReactDOM from 'react-dom';
import moment from 'moment';
import {
  BarChart, Bar, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine,
} from 'recharts';
import ColorHash from 'color-hash';

const INADMISSIBLE_START = '2019-06-18';

const formatData = data => {
  return [...Array(52).keys()].map(week_number =>
    Object.keys(data).reduce((obj, key) =>
      Object.assign(obj, {[key]: (data[key].find(([_week_number, value]) => _week_number === week_number) || [])[1] || 0})
    , {semaine: week_number})
  ).filter(datum => Object.keys(data).reduce((result, key) => (result || datum[key] !== 0), false))
}


const chart = data => {
  const colorHash = new ColorHash
  return (
    <ResponsiveContainer height={500}>
      <BarChart
        data={formatData(data)}
        margin={{
          top: 5, right: 30, left: 20, bottom: 5,
        }}
      >
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="semaine" label="N° Semaine" />
        <YAxis />
        <ReferenceLine x={moment(INADMISSIBLE_START).add(-30, 'days').format('w')} stroke="blue" label="inadmissible" />
        <ReferenceLine x={moment().add(-30, 'days').format('w')} stroke="red" label="-30j" />
        <Tooltip />
        <Legend />
        { Object.keys(data).sort().map(key =>
          <Bar key={key} dataKey={key} stackId="a" fill={colorHash.hex(key)} />
        )}
      </BarChart>
    </ResponsiveContainer>
  );
}

const renderChart = name => {
  const $container = document.querySelector(`#${name}-plot`);
  if (!$container) return;

  const data = JSON.parse($container.querySelector('pre').innerHTML);
  ReactDOM.render(chart(data), $container.querySelector('.plot'));
}

document.addEventListener('DOMContentLoaded', e => {
  renderChart('applications');
})

