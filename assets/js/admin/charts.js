import React, { PureComponent } from 'react';
import { render } from 'react-dom';
import moment from 'moment';
import sortBy from 'lodash.sortby';
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

import DefaultTooltipContent from 'recharts/lib/component/DefaultTooltipContent';

const KEY_MAP = {
  week_number: 'semaine',
  created: 'Candidatures créées',
  delegated: 'Avec certificateur',
  submitted: 'Candidatures transmises',
  inadmissible: 'Candidatures transmises pas encore admissible après relance',
  admissible: 'Candidatures transmises admissible après relance',
  no_booklet: 'Pas de livret 1',
  booklet_started: 'Livret 1 démarré',
  booklet_finished: 'Livret 1 terminé',
  resumed: 'Avec pièce jointe',
}

const COLORS = {
  'created': '#c7c7c7',
  'delegated': '#66d1ff',
  'submitted': '#18495e',
  'inadmissible': '#d35400',
  'admissible': '#06632d',
  'no_booklet': '#c7c7c7',
  'booklet_started': '#66d1ff',
  'booklet_finished': '#3498db',
  'resumed': '#18495e',
}

const statusToKey = s => {
  const number = s.replace(/-[a-z]+$/, '');
  const withoutNumber = s.replace(/^\d+-/, '');
  return `${parseInt(number) + 1}. ${KEY_MAP[withoutNumber] || withoutNumber}`;
}

const statusToColor = s => {
  const withoutNumber = s.replace(/^\d+-/, '');
  return COLORS[withoutNumber] || withoutNumber;
}

const getAvailableStatuses = rows => {
  return rows.reduce((statuses, row) => {
    return statuses.concat(statuses.indexOf(row[1]) > -1 ? [] : [row[1]])
  }, []).sort();
}

const formatDataToChart = ({columns, rows}) => {
  const linearizedData = Object.values(rows.reduce((object, [weekNumber, status, count]) => {
    return {
      ...object,
      [weekNumber]: {
        ...object[weekNumber],
        semaine: weekNumber,
        [statusToKey(status)]: count,
      }
    }
  }, {})).sort((a, b) => b.index - a.index);
  return linearizedData
}

const formatDataToBar = ({columns, rows}) => {
  return getAvailableStatuses(rows).filter(c => statusToColor(c)).map((c, i, a) => ({
    color: statusToColor(c),
    key: c,
    label: statusToKey(c),
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
      { sortBy(Object.entries(aggregatedData), ([k, v]) => k).map(([k, v]) =>
        <li key={k}>{k}: {valueWithPercent(v, total)} </li>
      )}
      <li><strong>Total: {total} (100%)</strong></li>
    </ul>
  );
}

const getLines = type => {
  if (window.location.pathname === '/admin') { // Dirty
    return [{
      label: 'Relance à 30 jours',
      color: 'red',
      date: moment().add(-30, 'days'),
    }, {
      label: 'MEP Livret 1 Educ nat',
      color: '#3498db',
      date: moment('2019-12-11'),
    }, {
      label: 'MEP Livret 1 pour tous',
      color: '#3498db',
      date: moment('2020-02-26'),
    }, {
      label: 'MEP 1.2',
      color: 'green',
      date: moment('2020-05-15'),
    }, {
      label: 'MEP Livret 1 facultatif',
      color: '#3498db',
      date: moment('2022-02-22'),
    }]
  } else {
    return [];
  }
}

// const CustomTooltip = props => {
//   // payload[0] doesn't exist when tooltip isn't visible
//   if (props.payload[0] != null) {
//     // mutating props directly is against react's conventions
//     // so we create a new payload with the name and value fields set to what we want
//     const newPayload = [
//       {
//         name: 'Name',
//         // all your data which created the tooltip is located in the .payload property
//         value: props.payload[0].payload.name,
//         // you can also add "unit" here if you need it
//       },
//       ...props.payload,
//     ];

//     // we render the default, but with our overridden payload
//     return <DefaultTooltipContent {...props} payload={newPayload} />;
//   }

//   // we just render the default
//   return <DefaultTooltipContent {...props} />;
// };

const renderChart = name => {
  const $container = document.querySelector(`#${name}-plot`);
  if ($container && $container.dataset.url) {

    $container.innerHTML = 'Chargement en cours ...'

    fetch($container.dataset.url)
      .then(res => res.json())
      .then(data => {
        const linearizedData = formatDataToChart(data);
        render(
          <div>
            <Aggregate data={linearizedData} />
            <ResponsiveContainer height={500}>
              <BarChart
                data={linearizedData}
                margin={{
                  top: 5, right: 30, left: 20, bottom: 5,
                }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="semaine" tickFormatter={formatWeekNumber} interval="preserveStartEnd" minTickGap={30} />
                <YAxis />
                {getLines(data.query.type).map((line, idx) =>
                  <ReferenceLine key={idx} x={line.date.format('YYYY-ww')} stroke={line.color}>
                    <Label value={line.label} angle={90} position="left"/>
                  </ReferenceLine>
                )}
                <Tooltip labelFormatter={weekNumberToString} formatter={formatValueWithPercent} />
                <Legend wrapperStyle={{bottom: -5}} />
                { formatDataToBar(data).map(c =>
                  <Bar key={c.key} dataKey={c.label} stackId="a" fill={c.color}>
                    {false && c.isLast && <LabelList position="top" valueAccessor={total}/>}
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

