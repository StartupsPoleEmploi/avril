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
  created: 'Crée',
  delegated: 'Avec certificateur',
  booklet_started: 'Livret 1 démarré',
  booklet_finished: 'Livret 1 terminé',
  admissible: 'Candidatures transmises admissible après relance',
  inadmissible: 'Candidatures transmises pas encore admissible après relance',
  submitted: 'Candidatures transmises',
  unsubmitted: 'Candidatures non transmises',
  finished: 'Livret 1 terminé',
  started: 'Livret 1 démarré',
  not_started: 'Livret 1 non démarré',
}

const COLORS = {
  created: '#dddddd',
  delegated: '#c7eeff',
  booklet_started: '#3498db',
  booklet_finished: '#2c3e50',
  admissible: '#27ae60',
  inadmissible: '#d35400',
  submitted: '#f39c12',
  unsubmitted: '#f1c40f',
  finished: '#2c3e50',
  started: '#3498db',
  not_started: '#bdc3c7',
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

const formatWeekNumber = weekNumberWithYear => {
  const [year, weekNumber] = weekNumberWithYear.split('-');
  return moment().year(year).week(weekNumber).weekday(1).format('DD/MM');
}

const weekNumberToString = (weekNumberWithYear, otherArgs) => {
  const [year, weekNumber] = weekNumberWithYear.split('-');
  const monday = moment().year(year).week(weekNumber).weekday(1).format('DD/MM/YY');
  const sunday = moment().year(year).week(weekNumber).weekday(7).format('DD/MM/YY');
  return `Du ${monday} au ${sunday}`;
}

const valueWithPercent = (value, total) => `${value} (${(100*value/total).toFixed(2)}%)`

const formatValueWithPercent = (value, name, props) => {
  const {semaine, ...withValues} = props.payload;
  const total = Object.values(withValues).reduce((a, b) => a + b, 0)
  return valueWithPercent(value, total);
}

const total = (entry) => {
  const {semaine, ...withValues} = entry.payload;
  return Object.values(withValues).reduce((a, b) => a + b, 0)
};

const Aggregate = ({data}) => {
  const aggregatedData = data.reduce((result, datum) => {
    return Object.keys(datum).filter(c => c !== 'semaine').reduce((subResult, key) => {
      return Object.assign(subResult, {[key]: datum[key] + (subResult[key] || 0)})
    }, result)
  }, {});
  const total = Object.values(aggregatedData).reduce((t, d) => (t+d), 0)
  return (
    <ul>
      { Object.keys(aggregatedData).map(k =>
        <li key={k}>{k}: {valueWithPercent(aggregatedData[k], total)} </li>
      )}
      <li>Total: {total} (100%)</li>
    </ul>
  );
}

const getLines = type => {
  if (type == 'submissions') {
    return [{
      label: 'Relance à 30 jours',
      color: 'red',
      date: moment().add(-30, 'days'),
    }]
  }
  if (type == 'booklet') {
    return [{
      label: 'MEP Livret 1 Educ nat',
      color: '#3498db',
      date: moment('2019-12-11'),
    }, {
      label: 'MEP Livret 1 pour tous',
      color: '#3498db',
      date: moment('2020-02-26'),
    }]
  }
}

const renderChart = name => {
  const $container = document.querySelector(`#${name}-plot`);
  if ($container && $container.dataset.url) {
    fetch($container.dataset.url)
      .then(res => res.json())
      .then(data => {
        const formattedData = formatDataToChart(data);
        render(
          <div>
            <Aggregate data={formattedData} />
            <ResponsiveContainer height={500}>
              <BarChart
                data={formattedData}
                margin={{
                  top: 5, right: 30, left: 20, bottom: 5,
                }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="semaine" tickFormatter={formatWeekNumber} interval="preserveStartEnd" minTickGap={30} />
                <YAxis />
                {getLines(data.query.type).map(line =>
                  <ReferenceLine x={line.date.format('YYYY-ww')} stroke={line.color}>
                    <Label value={line.label} angle={90} position="left"/>
                  </ReferenceLine>
                )}
                <Tooltip labelFormatter={weekNumberToString} formatter={formatValueWithPercent} />
                <Legend wrapperStyle={{bottom: -5}} />
                { formatDataToBar(data).map(c =>
                  <Bar key={c.key} dataKey={c.label} stackId="a" fill={c.color}>
                    {c.isLast && <LabelList position="top" valueAccessor={total}/>}
                  </Bar>
                )}
              </BarChart>
            </ResponsiveContainer>
          </div>,
          document.getElementById(`${name}-plot`)
        )
      })
  }
}

document.addEventListener('DOMContentLoaded', e => {
  renderChart('applications');
})

