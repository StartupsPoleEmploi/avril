import React, { PureComponent } from 'react';
import ReactDOM from 'react-dom';
import moment from 'moment';
import {
  BarChart, Bar, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine,
} from 'recharts';

const formatData = data => {
  return [...Array(52).keys()].map(week_number =>
    data.reduce((obj, entry) =>
      Object.assign(obj, {[entry.name]: (entry.data.find(([_week_number, value]) => _week_number === week_number) || [])[1] || 0})
    , {semaine: week_number})
  ).filter(datum => data.reduce((result, entry) => (result || datum[entry.name] !== 0), false))
}


const chart = data => {
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
        <ReferenceLine x={moment().add(-30, 'days').format('w')} stroke="red" label="-30j" />
        <Tooltip />
        <Legend />
        { data.map(entry =>
          <Bar key={entry.name} dataKey={entry.name} stackId="a" fill={entry.color} />
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

