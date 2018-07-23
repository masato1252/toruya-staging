import React from 'react'
import ReactDOM from 'react-dom'
import Plans from 'components/plans/plans.js';

document.addEventListener('DOMContentLoaded', () => {
  const node = document.querySelector('#plans')
  const data = JSON.parse(node.getAttribute('data'))
  const i18n = JSON.parse(node.getAttribute('i18n'))

  ReactDOM.render(<Plans {...data} i18n={i18n} />, node)
})
