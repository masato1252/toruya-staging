import _ from "lodash";
import { useEffect, useRef } from "react";

// examples:
// objects are the values you want to compare
// _.isEqual is the function you want to use to compare
//
// useCustomCompareEffect(() => {
//   // as you do in useEffect
// }, [objects], _.isEqual)
function useCustomCompareMemoize(value, equal_func) {
  const ref = useRef()
  // it can be done by using useMemo as well
  // but useRef is rather cleaner and easier

  if (!equal_func(value, ref.current)) {
    ref.current = value
  }

  return ref.current
}

function useCustomCompareEffect(callback, dependencies, equal_func) {
  useEffect(callback, useCustomCompareMemoize(dependencies, equal_func))
}

export default useCustomCompareEffect
