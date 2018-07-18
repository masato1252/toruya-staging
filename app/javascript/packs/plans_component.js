import React from 'react'
import ReactDOM from 'react-dom'
import Plans from 'components/plans/plans.js';

document.addEventListener('DOMContentLoaded', () => {
  const node = document.querySelector('#plans')
  const data = JSON.parse(node.getAttribute('data'))

  ReactDOM.render(<Plans {...data} />, node)
})
