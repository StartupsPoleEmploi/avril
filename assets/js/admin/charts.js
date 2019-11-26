import React, { PureComponent } from 'react';
import { render } from 'react-dom';
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

const KEY_MAP = {
  week_number: 'semaine',
  admissible: 'Admissible après relance',
  inadmissible: 'Refusé après relance',
  submitted: 'Candidatures transmises',
}

const COLORS = {
  admissible: '#2ecc71',
  inadmissible: '#c0392b',
  submitted: '#bdc3c7',
}

const arrayToObject = (row, keys) => {
  return keys.reduce((object, key, i) => {
    return Object.assign(object, {[KEY_MAP[key] || key]: row[i]})
  }, {});
}

const formatDataToChart = ({columns, rows}) => {
  return rows.map(row => arrayToObject(row, columns));
}

const formatDataToBar = ({columns, rows}) => {
  return columns.filter(c => COLORS[c]).map((c, i, a) => ({
    color: COLORS[c],
    key: c,
    label: KEY_MAP[c],
    isLast: i === a.length - 1,
  }));
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

const renderChart = name => {
  const $container = document.querySelector(`#${name}-plot`);
  if ($container && $container.dataset.url) {
    fetch($container.dataset.url)
      .then(res => res.json())
      .then((data) => {
        render(
          <ResponsiveContainer height={500}>
            <BarChart
              data={formatDataToChart(data)}
              margin={{
                top: 5, right: 30, left: 20, bottom: 5,
              }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="semaine" />
              <YAxis />
              <ReferenceLine x={moment().add(-30, 'days').format('w')} stroke="red">
                <Label value="Relance à 30 jours" angle={90} position="left"/>
              </ReferenceLine>
              <Tooltip labelFormatter={weekNumberToString} formatter={valueWithPercent} />
              <Legend />
              { formatDataToBar(data).map(c =>
                <Bar key={c.key} dataKey={c.label} stackId="a" fill={c.color}>
                  {c.isLast && <LabelList position="top" valueAccessor={total}/>}
                </Bar>
              )}
            </BarChart>
          </ResponsiveContainer>,
          document.getElementById(`${name}-plot`)
        )
      })
  }
}

document.addEventListener('DOMContentLoaded', e => {
  renderChart('applications');
})

