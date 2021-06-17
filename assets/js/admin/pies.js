import React, { PureComponent } from 'react';
import { render } from 'react-dom';

import {
  Cell,
  ResponsiveContainer,
  PieChart,
  Pie,
} from 'recharts';

const COLORS = [
  '#7f8c8d',
  '#2ecc71',
  '#3498db',
  '#e67e22',
  '#2c3e50',
  '#8e44ad',
];

const renderPie = name => {
  const $container = document.querySelector(`#${name}-pie`);
  if ($container && $container.dataset.url) {
    fetch($container.dataset.url)
      .then(res => res.json())
      .then(objData => {
        const data = objData.sort((a, b) => b.value - a.value);
        const total = data.reduce((acc, d) => acc + d.value, 0);
        render(
          <div style={{height: '400px'}}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  dataKey="value"
                  data={data}
                  minAngle={4}
                  startAngle={180}
                  endAngle={-180}
                  label={entry => `${entry.value} ${entry.label} : ${parseInt(entry.percent * 100)}%`}
                >
                  {
                    data.map((entry, index) => <Cell key={index} fill={COLORS[index % COLORS.length]}/>)
                  }
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <p className="text-center">Total: {total} utilisateurs</p>
          </div>,
          document.getElementById(`${name}-pie`)
        )
      })
  }
}

document.addEventListener('DOMContentLoaded', e => {
  renderPie('users');
})

