import React, { PureComponent } from 'react';
import ReactDOM from 'react-dom';
import moment from 'moment';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Label,
  LabelList,
  Legend,
  ResponsiveContainer,
  ReferenceLine,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

const formatData = data => {
  return [...Array(52).keys()].map(week_number =>
    data.reduce((obj, entry) =>
      Object.assign(obj, {[entry.name]: (entry.data.find(([_week_number, value]) => _week_number === week_number) || [])[1] || 0})
    , {semaine: week_number})
  ).filter(datum => data.reduce((result, entry) => (result || datum[entry.name] !== 0), false))
}

const weekNumberToString = (weekNumber, otherArgs) => {
  const monday = moment().week(weekNumber).day("Monday").format('DD/MM/YY');
  const sunday = moment().week(weekNumber+1).day("Sunday").format('DD/MM/YY');
  return `Du ${monday} au ${sunday}`;
}

const valueWithPercent = (value, name, props) => {
  const {semaine, ...withValues} = props.payload;
  const total = Object.values(withValues).reduce((a, b) => a + b, 0)
  return `${value} (${(100*value/total).toFixed(2)}%)`;
}

const total = (entry) => {
  const {semaine, ...withValues} = entry.payload;
  return Object.values(withValues).reduce((a, b) => a + b, 0)
};

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
        <XAxis dataKey="semaine" />
        <YAxis />
        <ReferenceLine x={moment().add(-30, 'days').format('w')} stroke="red">
          <Label value="Relance à 30 jours" angle="90" position="left"/>
        </ReferenceLine>
        <Tooltip labelFormatter={weekNumberToString} formatter={valueWithPercent} />
        <Legend />
        { data.map((entry, i) =>
          <Bar key={entry.name} dataKey={entry.name} stackId="a" fill={entry.color}>
            {i === (data.length - 1) && <LabelList position="top" valueAccessor={total}/>}
          </Bar>
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

